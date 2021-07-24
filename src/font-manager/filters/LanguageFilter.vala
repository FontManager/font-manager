/* LanguageFilter.vala
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

internal const string SELECT_ON_LANGUAGE = """
SELECT DISTINCT Fonts.family, Fonts.description
FROM Fonts, json_tree(Orthography.support, '$.%s')
JOIN Orthography USING (filepath, findex)
WHERE json_tree.key = 'coverage' AND json_tree.value > %f;
""";

const string DEFAULT_LANGUAGE_FILTER_COMMENT = _("Filter based on supported orthographies");

namespace FontManager {

    public class LanguageFilter : Category {

        public signal void selections_changed ();

        public StringSet selected { get; set; }
        public double coverage { get; set; default = 90; }
        public LanguageFilterSettings settings { get; private set; }

        public override int size {
            get {
                return ((int) selected.size);
            }
        }

        construct {
            selected = new StringSet();
            settings = new LanguageFilterSettings(this);
            settings.selections_changed.connect(() => {
                Idle.add(() => {
                    update.begin((obj, res) => { update.end(res); });
                    return GLib.Source.REMOVE;
                });
            });
        }

        public LanguageFilter () {
            base(_("Supported Orthographies"),
                 DEFAULT_LANGUAGE_FILTER_COMMENT,
                 "preferences-desktop-locale-symbolic",
                 SELECT_ON_LANGUAGE,
                 CategoryIndex.LANGUAGE);
            GLib.Settings? settings = get_default_application().settings;
            if (settings != null)
                restore_state(settings);
        }

        public void restore_state (GLib.Settings settings) {
            foreach (var entry in settings.get_strv("language-filter-list"))
                selected.add(entry);
            update.begin((obj, res) => { update.end(res); });
            return;
        }

        public void save_state (GLib.Settings settings) {
            settings.set_strv("language-filter-list", list());
            return;
        }

        public void add (string language) {
            selected.add(language);
            update.begin((obj, res) => { update.end(res); });
            return;
        }

        public string [] list () {
            string [] result = {};
            foreach (string language in selected)
                result += language;
            return result;
        }

        public new async void update () {
            descriptions.clear();
            families.clear();
            try {
                Database db = get_database(db_type);
                foreach (string language in selected) {
                    var pref_loc = Intl.setlocale(LocaleCategory.ALL, "");
                    Intl.setlocale(LocaleCategory.ALL, "C");
                    string _sql_ = sql.printf(language, coverage);
                    Intl.setlocale(LocaleCategory.ALL, pref_loc);
                    get_matching_families_and_fonts(db, families, descriptions, _sql_);
                    Idle.add(update.callback);
                    yield;
                }
            } catch (DatabaseError error) {
                warning(error.message);
            }
            StringSet? available_families = get_default_application().available_families;
            assert(available_families != null);
            families.retain_all(available_families);
            Idle.add(() => {  selections_changed(); return GLib.Source.REMOVE; });
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-language-filter-settings.ui")]
    public class LanguageFilterSettings : Gtk.Box {

        public signal void selections_changed ();

        weak LanguageFilter filter;

        [GtkChild] unowned Gtk.SpinButton coverage_spin;
        [GtkChild] unowned Gtk.SearchEntry search_entry;
        [GtkChild] unowned Gtk.TreeView treeview;

        uint? search_timeout;
        uint16 text_length = 0;
        Gtk.ListStore real_model;
        Gtk.TreeModelFilter? search_filter = null;

        construct {
            real_model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(string));
            search_filter = new Gtk.TreeModelFilter(real_model, null);
            search_filter.set_visible_func((m, i) => { return visible_func(m, i); });
            treeview.set_model(search_filter);
            treeview.get_selection().set_mode(Gtk.SelectionMode.NONE);
            Gtk.TreeIter iter;
            foreach (var entry in Orthographies) {
                real_model.append(out iter);
                string local = dgettext(null, entry.name);
                /* Prefer the actual native name but fallback to localized name, if available. */
                string native = entry.native != entry.name ? entry.native : local;
                /* Store all three for use during filtering */
                real_model.set(iter, 0, entry.name, 1, native, 2, local, -1);
            }
            var text = new Gtk.CellRendererText();
            text.ellipsize = Pango.EllipsizeMode.END;
            var toggle = new Gtk.CellRendererToggle();
            toggle.toggled.connect(on_toggled);
            treeview.row_activated.connect((path, col) => { on_toggled(path.to_string()); });
            treeview.insert_column_with_data_func(FontListColumn.TOGGLE, "", toggle, toggle_cell_data_func);
            treeview.insert_column_with_attributes(-1, "", text, "text", 1, null);
            treeview.set_search_entry(search_entry);
            /* XXX : Remove placeholder icon set in ui file to avoid Gtk warning */
            search_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, null);
            base.constructed();
            return;
        }

        public LanguageFilterSettings (LanguageFilter filter) {
            this.filter = filter;
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            filter.bind_property("coverage", coverage_spin, "value", flags);
        }

        bool refilter () {
            /* Unset the model to prevent updates while filtering */
            treeview.set_model(null);
            search_filter.refilter();
            treeview.set_model(search_filter);
            search_timeout = null;
            return false;
        }

        [GtkCallback]
        void on_search_changed () {
            queue_refilter();
            text_length = search_entry.get_text_length();
            return;
        }

        [GtkCallback]
        void on_back_button_clicked () {
            get_default_application().main_window.sidebar.mode = "Standard";
            search_entry.set_text("");
            return;
        }

        [GtkCallback]
        void on_clear_button_clicked () {
            filter.selected.clear();
            treeview.queue_draw();
            selections_changed();
            return;
        }

        void on_toggled (string path) {
            Gtk.TreeIter iter;
            Value val;
            search_filter.get_iter_from_string(out iter, path);
            search_filter.get_value(iter, 0, out val);
            var lang = (string) val;
            if (lang in filter.selected)
                filter.selected.remove(lang);
            else
                filter.selected.add(lang);
            val.unset();
            treeview.queue_draw();
            selections_changed();
            return;
        }

        void toggle_cell_data_func (Gtk.TreeViewColumn layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, 0, out val);
            cell.set_property("active", (filter.selected.contains((string) val)));
            val.unset();
            return;
        }

        /* Add slight delay to avoid filtering while search is still changing */
        void queue_refilter () {
            if (search_timeout != null)
                GLib.Source.remove(search_timeout);
            search_timeout = Timeout.add(333, refilter);
            return;
        }

        bool visible_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
            bool search_match = true;
            if (text_length > 0) {
                string needle = search_entry.get_text().casefold();
                for (int i = 0; i <= 2; i++) {
                    Value val;
                    model.get_value(iter, i, out val);
                    var haystack = (string) val;
                    search_match = haystack.casefold().contains(needle);
                    if (search_match)
                        break;
                }

            }
            return search_match;
        }

    }

}
