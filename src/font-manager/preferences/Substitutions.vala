/* Substitutions.vala
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

    // FIXME !! EntryCompletion is deprecated with no replacement.
    internal Gtk.ListStore? family_completion_model = null;

    internal Gtk.ListStore get_family_completion_model () {
        if (family_completion_model == null) {
            family_completion_model = new Gtk.ListStore(1, typeof(string));
            foreach (string family in list_available_font_families()) {
                Gtk.TreeIter iter;
                family_completion_model.append(out iter);
                family_completion_model.set(iter, 0, family, -1);
            }
        }
        return family_completion_model;
    }

    internal Gtk.EntryCompletion get_family_completion () {
        Gtk.EntryCompletion family_completion = new Gtk.EntryCompletion();
        family_completion.set_model(get_family_completion_model());
        family_completion.set_text_column(0);
        return family_completion;
    }

    internal Gtk.Widget? get_bin_child (Gtk.Widget? widget) {
        if (widget == null)
            return null;
        return widget.get_first_child();
    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-substitute.ui")]
    public class Substitute : Gtk.Grid {

        public string family { get; set; default = ""; }
        public string priority { get; set; default = "prefer"; }

        [GtkChild] unowned Gtk.Button close;
        [GtkChild] unowned Gtk.DropDown type;
        [GtkChild] unowned Gtk.Entry target;

        string priorities [3] = { "prefer", "accept", "default" };

        public override void constructed () {
            target.set_completion(get_family_completion());
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            type.bind_property("selected", this, "priority", flags,
                               (b, s, ref t) => { t = priorities[(uint) s]; return true; },
                               (b, s, ref t) => {
                                    for (uint i = 0; i < priorities.length; i++)
                                        if (priorities[i] == (string)s) {
                                            t = i;
                                            return true;
                                        }
                                    return false;
                                });
            target.bind_property("text", this, "family", flags);
            close.clicked.connect(() => {
                Gtk.ListBox list = (Gtk.ListBox) get_ancestor(typeof(Gtk.ListBox));
                Gtk.ListBoxRow parent = (Gtk.ListBoxRow) get_ancestor(typeof(Gtk.ListBoxRow));
                list.remove(parent);
            });
            base.constructed();
            return;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-substitute-row.ui")]
    public class SubstituteRow : Gtk.Box {

        public string? family { get; set; default = null; }

        [GtkChild] unowned Gtk.Entry entry;
        [GtkChild] unowned Gtk.ListBox list;
        [GtkChild] unowned Gtk.Button add_button;

        public override void constructed () {
            widget_set_name(this, "FontManagerSubstituteRow");
            entry.set_completion(get_family_completion());
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            entry.bind_property("text", this, "family", flags);
            base.constructed();
            return;
        }

        [GtkCallback]
        void on_add_button_clicked () {
            list.insert(new Substitute(), -1);
            return;
        }

        [GtkCallback]
        void on_entry_changed () {
            set_control_sensitivity(add_button, entry.get_text() != null);
            return;
        }

        public SubstituteRow.from_element (AliasElement alias) {
            family = alias.family;
            string [] priorities = { "default", "accept", "prefer" };
            for (int i = 0; i < priorities.length; i++) {
                foreach (string family in alias[priorities[i]].list()) {
                    Substitute sub = new Substitute();
                    sub.family = family;
                    sub.priority = priorities[i];
                    list.insert(sub, -1);
                }
            }
        }

        public AliasElement to_element () {
            var res = new AliasElement(entry.get_text());
            int i = 0;
            var sub = (Substitute) get_bin_child(list.get_row_at_index(i));
            while (sub != null) {
                if (sub.priority != null && sub.family != null && sub.family != "")
                    res[sub.priority].add(sub.family);
                i++;
                sub = (Substitute) get_bin_child(list.get_row_at_index(i));
            }
            return res;
        }

    }

    public class SubstituteList : PreferenceList {

        public SubstituteList () {
            widget_set_name(this, "FontManagerSubstituteList");
            controls.visible = true;
            string w1 = _("Font Substitutions");
            string w2 = _("Easily substitute one font family for another.");
            string w3 = _("To add a new substitute click the add button in the toolbar.");
            var place_holder = new PlaceHolder(w1, w2, w3, "edit-find-replace-symbolic");
            list.set_placeholder(place_holder);
            var help = inline_help_widget(FONTCONFIG_DISCLAIMER);
            controls.append(help);
        }

        void clear () {
            while (list.get_row_at_index(0) != null) {
                Gtk.ListBoxRow row = list.get_row_at_index(0);
                list.remove(row);
            }
            return;
        }

        public bool load () {
            var aliases = new Aliases() {
                config_dir = get_user_fontconfig_directory(),
                target_file = "39-Aliases.conf"
            };
            bool res = aliases.load();
            foreach (AliasElement element in aliases.list()) {
                var row = new SubstituteRow.from_element(element);
                list.insert(row, -1);
                row.show();
            }
            list.set_sort_func((row1, row2) => {
                var a = (SubstituteRow) get_bin_child(row1);
                var b = (SubstituteRow) get_bin_child(row2);
                return natural_sort(a.family, b.family);
            });
            list.invalidate_sort();
            return res;
        }

        public bool save () {
            var aliases = new Aliases() {
                config_dir = get_user_fontconfig_directory(),
                target_file = "39-Aliases.conf"
            };
            int i = 0;
            var alias_row = (SubstituteRow) get_bin_child(list.get_row_at_index(i));
            while (alias_row != null) {
                AliasElement? element = alias_row.to_element();
                // Empty rows are allowed in the list - don't save one
                if (element != null && element.family != null && element.family != "")
                    aliases.add_element(element);
                i++;
                alias_row = (SubstituteRow) get_bin_child(list.get_row_at_index(i));
            }
            bool res = aliases.save();
            return res;
        }

        protected override void on_add_selected () {
            list.insert(new SubstituteRow(), -1);
            return;
        }

        protected override void on_map () {
            load();
            base.on_map();
            return;
        }

        protected override void on_unmap () {
            save();
            clear();
            return;
        }

        protected override void on_remove_selected () {
            list.remove(list.get_selected_row());
            return;
        }

    }

}

