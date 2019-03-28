/* LanguageFilter.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

namespace FontManager {

    public class LanguageFilter : Category {

        public signal void selections_changed ();

        public StringHashset selected { get; set; }
        public double coverage { get; set; default = 90; }

        public LanguageFilterSettings settings { get; private set; }

        public override int size {
            get {
                return ((int) selected.size);
            }
        }

        public LanguageFilter () {
            base(_("Language"),  _("Filter based on language support"),
                 "preferences-desktop-locale", SELECT_ON_LANGUAGE);
            selected = new StringHashset();
            settings = new LanguageFilterSettings();
            bind_property("selected", settings, "selected", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("coverage", settings, "coverage", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            settings.selections_changed.connect(() => {
                update.begin((obj, res) => {
                    update.end(res);
                    selections_changed();
                });
            });
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
            var application = ((FontManager.Application) GLib.Application.get_default());
            families.retain_all(application.available_font_families.list());
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-language-popover.ui")]
    public class LanguagePopover : Gtk.Popover {

        public signal void selections_changed ();

        public double coverage { get; set; default = 90; }
        public StringHashset selected { get; set; }

        [GtkChild] Gtk.SpinButton coverage_spin;
        [GtkChild] Gtk.SearchEntry search_entry;
        [GtkChild] Gtk.TreeView treeview;

        Gtk.ListStore liststore;

        public override void constructed () {
            set_modal(true);
            selected = new StringHashset();
            bind_property("coverage", coverage_spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            liststore = new Gtk.ListStore(2, typeof(string), typeof(string));
            treeview.set_model(liststore);
            Gtk.TreeIter iter;
            foreach (var entry in Orthographies) {
                liststore.append(out iter);
                liststore.set(iter, 0, entry.name, 1, entry.native, -1);
            }
            var text = new Gtk.CellRendererText();
            var _text = new Gtk.CellRendererText();
            _text.sensitive = false;
            var toggle = new Gtk.CellRendererToggle();
            toggle.toggled.connect(on_toggled);
            treeview.row_activated.connect((path, col) => { on_toggled(path.to_string()); });
            treeview.insert_column_with_data_func(FontListColumn.TOGGLE, "", toggle, toggle_cell_data_func);
            treeview.insert_column_with_attributes(-1, "", text, "text", 1, null);
            treeview.insert_column_with_attributes(-1, "", _text, "text", 0, null);
            treeview.set_search_entry(search_entry);
            base.constructed();
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
            liststore.get_iter_from_string(out iter, path);
            liststore.get_value(iter, 0, out val);
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

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-language-filter-settings.ui")]
    public class LanguageFilterSettings : Gtk.MenuButton {

        public signal void selections_changed ();

        public double coverage { get; set; default = 90; }
        public StringHashset selected { get; set; }

        LanguagePopover _popover_;

        public override void constructed () {
            _popover_ = new LanguagePopover();
            set_popover(_popover_);
            bind_property("coverage", popover, "coverage", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("selected", popover, "selected", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            _popover_.selections_changed.connect(() => { selections_changed(); });
            base.constructed();
            return;
        }

    }



}
