/* LanguageFilter.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

const string DEFAULT_LANGUAGE_FILTER_COMMENT = _("Filter based on language support");

namespace FontManager {

    public class LanguageFilter : Category {

        public signal void selections_changed ();

        public StringHashset selected { get; set; }
        public double coverage { get; set; default = 90; }

        public Gtk.Button settings_button { get; private set; }
        public LanguageFilterSettings settings { get; private set; }

        public override int size {
            get {
                return ((int) selected.size);
            }
        }

        public LanguageFilter () {
            base(_("Language"),  DEFAULT_LANGUAGE_FILTER_COMMENT, "preferences-desktop-locale", SELECT_ON_LANGUAGE, CategoryIndex.LANGUAGE);
            selected = new StringHashset();
            settings = new LanguageFilterSettings();
            bind_property("selected", settings, "selected", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("coverage", settings, "coverage", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            settings_button = settings.get_button();
            settings.selections_changed.connect(() => {
                update.begin((obj, res) => {
                    update.end(res);
                    selections_changed();
                });
            });
            main_window.sidebar.add_view(settings, "LanguageFilterSettings");
        }

        public void add (string language) {
            selected.add(language);
            update.begin((obj, res) => {
                update.end(res);
                selections_changed();
            });
            return;
        }

        public string [] list () {
            string [] result = {};
            foreach (var language in selected)
                result += language;
            return result;
        }

        public new async void update () {
            descriptions.clear();
            families.clear();
            try {
                Database db = get_database(db_type);
                foreach (string language in selected) {
                    string _sql_ = sql.printf(language, coverage);
                    get_matching_families_and_fonts(db, families, descriptions, _sql_);
                    Idle.add(update.callback);
                    yield;
                }
            } catch (DatabaseError error) {
                warning(error.message);
            }
            if (available_font_families != null)
                families.retain_all(available_font_families.list());
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-language-filter-settings.ui")]
    public class LanguageFilterSettings : Gtk.Box {

        public signal void selections_changed ();

        public double coverage { get; set; default = 90; }
        public StringHashset selected { get; set; }

        [GtkChild] Gtk.SpinButton coverage_spin;
        [GtkChild] Gtk.SearchEntry search_entry;
        [GtkChild] Gtk.TreeView treeview;

        uint? search_timeout;
        uint16 text_length = 0;
        Gtk.Button settings_button;
        Gtk.ListStore real_model;
        Gtk.TreeModelFilter? search_filter = null;

        public override void constructed () {
            selected = new StringHashset();
            bind_property("coverage", coverage_spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            real_model = new Gtk.ListStore(2, typeof(string), typeof(string));
            search_filter = new Gtk.TreeModelFilter(real_model, null);
            search_filter.set_visible_func((m, i) => { return visible_func(m, i); });
            treeview.set_model(search_filter);
            treeview.get_selection().set_mode(Gtk.SelectionMode.NONE);
            Gtk.TreeIter iter;
            foreach (var entry in Orthographies) {
                real_model.append(out iter);
                real_model.set(iter, 0, entry.name, 1, entry.native, -1);
            }
            var text = new Gtk.CellRendererText();
            text.ellipsize = Pango.EllipsizeMode.END;
            var toggle = new Gtk.CellRendererToggle();
            toggle.toggled.connect(on_toggled);
            treeview.row_activated.connect((path, col) => { on_toggled(path.to_string()); });
            treeview.insert_column_with_data_func(FontListColumn.TOGGLE, "", toggle, toggle_cell_data_func);
            treeview.insert_column_with_attributes(-1, "", text, "text", 1, null);
            treeview.set_search_entry(search_entry);
            search_entry.search_changed.connect(() => {
                queue_refilter();
                text_length = search_entry.get_text_length();
            });
            /* XXX : Remove placeholder icon set in ui file to avoid Gtk warning */
            search_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, null);
            base.constructed();
            return;
        }

        public Gtk.Button get_button () {
            if (settings_button != null)
                return settings_button;
            settings_button = new Gtk.Button();
            settings_button.always_show_image = true;
            var settings_icon = new Gtk.Image.from_icon_name("preferences-desktop-locale", Gtk.IconSize.BUTTON);
            settings_button.set_image(settings_icon);
            settings_button.set_label("Filter Settings");
            settings_button.halign = Gtk.Align.CENTER;
            settings_button.valign = Gtk.Align.END;
            settings_button.margin = 12;
            settings_button.relief = Gtk.ReliefStyle.NONE;
            settings_button.show();
            settings_button.clicked.connect(() => {
                main_window.sidebar.mode = "LanguageFilterSettings";
            });
            return settings_button;
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
        void on_back_button_clicked () {
            main_window.sidebar.mode = "Standard";
            search_entry.set_text("");
            return;
        }

        [GtkCallback]
        void on_clear_button_clicked () {
            selected.clear();
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
            if (lang in selected)
                selected.remove(lang);
            else
                selected.add(lang);
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
            cell.set_property("active", (selected.contains((string) val)));
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
                for (int i = 0; i <= 1; i++) {
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
