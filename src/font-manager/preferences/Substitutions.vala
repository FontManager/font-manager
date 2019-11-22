/* Substitutions.vala
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

namespace FontManager {

    public class SubstitutionPreferences : FontConfigSettingsPage {

        BaseControls base_controls;
        SubstituteList sub_list;

        public SubstitutionPreferences () {
            sub_list = new SubstituteList();
            sub_list.expand = true;
            base_controls = new BaseControls();
            base_controls.add_button.set_tooltip_text(_("Add alias"));
            base_controls.remove_button.set_tooltip_text(_("Remove selected alias"));
            base_controls.remove_button.sensitive = false;
            box.pack_start(base_controls, false, false, 1);
            add_separator(box, Gtk.Orientation.HORIZONTAL);
            box.pack_end(sub_list, true, true, 1);
            sub_list.load();
            connect_signals();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            base_controls.show();
            base_controls.remove_button.hide();
            sub_list.show();
        }

        void connect_signals () {
            base_controls.add_selected.connect(() => {
                sub_list.on_add_row();
            });
            base_controls.remove_selected.connect(() => {
                sub_list.on_remove_row();
            });
            sub_list.row_selected.connect((r) => {
                if (r != null)
                    base_controls.remove_button.show();
                else
                    base_controls.remove_button.hide();
                base_controls.remove_button.sensitive = (r != null);
            });
            controls.save_selected.connect(() => {
                if (sub_list.save())
                    show_message(_("Settings saved to file."));
            });
            controls.discard_selected.connect(() => {
                if (sub_list.discard())
                    show_message(_("Removed configuration file."));
            });
            sub_list.place_holder.map.connect(() => {
                base_controls.add_button.set_relief(Gtk.ReliefStyle.NORMAL);
                base_controls.add_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            sub_list.place_holder.unmap.connect(() => {
                base_controls.add_button.set_relief(Gtk.ReliefStyle.NONE);
                base_controls.add_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            return;
        }

    }

    internal Gtk.Widget? get_bin_child (Gtk.Widget? row) {
        if (row == null)
            return null;
        return ((Gtk.Bin) row).get_child();
    }

    /**
     * Substitute:
     *
     * Single line widget representing a substitute font family
     * in a Fontconfig <alias> entry.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-substitute.ui")]
    class Substitute : Gtk.Grid {

        /**
         * Substitute:priority:
         *
         * prefer, accept, or default
         */
        public string priority {
            owned get {
                return type.get_active_text();
            }
            set {
                var e = get_bin_child(type) as Gtk.Entry;
                e.set_text(value);
            }
        }

        /**
         * Substitute:family:
         *
         * Name of replacement family
         */
        public string? family {
            owned get {
                return target.get_text();
            }
            set {
                target.set_text(value);
            }
        }

        public Gtk.ListStore? completion_model {
            set {
                Gtk.EntryCompletion completion = target.get_completion();
                completion.set_model(value);
                completion.set_text_column(0);
            }
        }

        [GtkChild] Gtk.Button close;
        [GtkChild] Gtk.ComboBoxText type;
        [GtkChild] Gtk.Entry target;

        public override void constructed () {
            target.set_completion(new Gtk.EntryCompletion());
            close.clicked.connect(() => {
                this.destroy();
                return;
            });
            base.constructed();
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-alias-row.ui")]
    class AliasRow : Gtk.Box {

        public string family {
            owned get {
                return entry.get_text();
            }
            set {
                entry.set_text(value);
            }
        }

        public Gtk.ListStore? completion_model {
            set {
                Gtk.EntryCompletion completion = entry.get_completion();
                completion.set_model(value);
                completion.set_text_column(0);
            }
            get {
                return entry.get_completion().get_model() as Gtk.ListStore;
            }
        }

        [GtkChild] Gtk.Entry entry;
        [GtkChild] Gtk.ListBox list;
        [GtkChild] Gtk.Button add_button;

        public override void constructed () {
            entry.set_completion(new Gtk.EntryCompletion());
            add_button.clicked.connect(() => {
                var sub = new Substitute();
                sub.completion_model = completion_model;
                list.insert(sub, -1);
                sub.show();
            });
            entry.changed.connect(() => {
                add_button.sensitive = (entry.get_text() != null);
            });
            base.constructed();
            return;
        }

        public AliasRow.from_element (AliasElement alias) {
            family = alias.family;
            string [] priorities = { "default", "accept", "prefer" };
            for (int i = 0; i < priorities.length; i++) {
                foreach (string family in alias[priorities[i]].list()) {
                    Substitute sub = new Substitute();
                    sub.completion_model = completion_model;
                    sub.family = family;
                    sub.priority = priorities[i];
                    list.insert(sub, -1);
                    sub.show();
                }
            }
        }

        public AliasElement to_element () {
            var res = new AliasElement(entry.get_text());
            int i = 0;
            var sub = get_bin_child(list.get_row_at_index(i)) as Substitute;
            while (sub != null) {
                if (sub.family != null && sub.family != "")
                    res[sub.priority].add(sub.family);
                i++;
                sub = get_bin_child(list.get_row_at_index(i)) as Substitute;
            }
            return res;
        }

    }

    class SubstituteList : Gtk.ScrolledWindow {

        public signal void row_selected(Gtk.ListBoxRow? selected_row);

        public PlaceHolder place_holder { get; private set; }

        Gtk.ListBox list;
        Gtk.ListStore completion_model;

        construct {
            name = "FontManagerAliasList";
            string w1 = _("Font Substitutions");
            string w2 = _("Easily substitute one font family for another.");
            string w3 = _("To add a new substitute click the add button in the toolbar.");
            string welcome_tmpl = "<span size=\"xx-large\" weight=\"bold\">%s</span>\n<span size=\"large\">\n\n%s\n</span>\n\n\n<span size=\"x-large\">%s</span>";
            string welcome_message = welcome_tmpl.printf(w1, w2, w3);
            place_holder = new PlaceHolder(welcome_message, "edit-find-replace-symbolic");
            list = new Gtk.ListBox();
            list.set_placeholder(place_holder);
            list.expand = true;
            add(list);
            list.row_selected.connect((r) => { row_selected(r); });
            list.show();
            place_holder.show();
        }

        public SubstituteList () {
            completion_model = new Gtk.ListStore(1, typeof(string));
            foreach (string family in list_available_font_families()) {
                Gtk.TreeIter iter;
                completion_model.append(out iter);
                completion_model.set(iter, 0, family, -1);
            }
        }

        public void on_add_row () {
            var row = new AliasRow();
            row.completion_model = completion_model;
            list.insert(row, -1);
            row.show();
            return;
        }

        public void on_remove_row () {
            ((Gtk.Widget) list.get_selected_row()).destroy();
            return;
        }

        public bool discard () {
            while (list.get_row_at_index(0) != null)
                ((Gtk.Widget) list.get_row_at_index(0)).destroy();
            var aliases = new Aliases();
            aliases.config_dir = get_user_fontconfig_directory();
            aliases.target_file = "39-Aliases.conf";
            File file = File.new_for_path(aliases.get_filepath());
            try {
                if (file.delete())
                    return true;
            } catch (Error e) {
                /* Try to save empty file */
                return save();
            }
            return false;
        }

        public bool load () {
            var aliases = new Aliases();
            aliases.config_dir = get_user_fontconfig_directory();
            aliases.target_file = "39-Aliases.conf";
            bool res = aliases.load();
            foreach (AliasElement element in aliases.list()) {
                var row = new AliasRow.from_element(element);
                row.completion_model = completion_model;
                list.insert(row, -1);
                row.show();
            }
            list.set_sort_func((row1, row2) => {
                var a = get_bin_child(row1) as AliasRow;
                var b = get_bin_child(row2) as AliasRow;
                return natural_sort(a.family, b.family);
            });
            list.invalidate_sort();
            return res;
        }

        public bool save () {
            var aliases = new Aliases();
            aliases.config_dir = get_user_fontconfig_directory();
            aliases.target_file = "39-Aliases.conf";
            int i = 0;
            var alias_row = get_bin_child(list.get_row_at_index(i)) as AliasRow;
            while (alias_row != null) {
                AliasElement? element = alias_row.to_element();
                /* Empty rows are allowed in the list - don't save one */
                if (element != null && element.family != null && element.family != "")
                    aliases.add_element(element);
                i++;
                alias_row = get_bin_child(list.get_row_at_index(i)) as AliasRow;
            }
            bool res = aliases.save();
            return res;
        }

    }

}
