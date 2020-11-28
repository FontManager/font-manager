/* Filters.vala
 *
 * Copyright (C) 2020 Jerry Casiano
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

#if HAVE_WEBKIT

namespace FontManager.GoogleFonts {

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-font-filters.ui")]
    public class Filters : Gtk.ScrolledWindow {

        public signal void changed ();

        [GtkChild] public Gtk.ComboBoxText sort_order { get; private set; }

        [GtkChild] Gtk.Grid category_grid;
        [GtkChild] Gtk.ListBox language_list;

        int n_variations = 0;
        StringSet categories;
        StringSet language_support;

        public override void constructed () {
            base.constructed();
            foreach (var lang in Languages) {
                var check = new Gtk.CheckButton.with_label(lang.display_name) {
                    can_focus = false,
                    name = lang.name
                };
                language_list.insert(check, -1);
                check.show();
                check.toggled.connect(on_language_toggled);
            }
            categories = new StringSet();
            foreach (var widget in category_grid.get_children())
                categories.add(widget.name);
            language_support = new StringSet();
            return;
        }

        public bool visible_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
            Value? val = null;
            model.get_value(iter, 0, out val);
            return_val_if_fail(val != null, true);
            Family? family = null;
            Font? variant = null;
            bool root_node = model.iter_has_child(iter);
            if (root_node) {
                family = ((Family) val);
                variant = family.get_default_variant();
            } else {
                Gtk.TreeIter parent;
                return_val_if_fail(model.iter_parent(out parent, iter), true);
                Value? _val = null;
                model.get_value(iter, 0, out _val);
                return_val_if_fail(_val != null, true);
                family = ((Family) _val);
                variant = ((Font) val);
            }
            return_val_if_fail(family != null && variant != null, true);
            if (root_node && categories.size < 5 && !(family.category in categories))
                return false;
            if (root_node && family.count < n_variations)
                return false;
            if (root_node && language_support.size > 0) {
                foreach (string entry in language_support) {
                    if (entry in family.subsets)
                        return true;
                }
                return false;
            }
            return true;
        }

        [GtkCallback]
        void on_category_toggled (Gtk.ToggleButton widget) {
            if (widget.active)
                categories.add(widget.name);
            else
                categories.remove(widget.name);
            changed();
            return;
        }

        void on_language_toggled (Gtk.ToggleButton widget) {
            if (widget.active)
                language_support.add(widget.name);
            else
                language_support.remove(widget.name);
            changed();
            return;
        }

        [GtkCallback]
        void on_variations_toggled (Gtk.ToggleButton widget) {
            if (!widget.active)
                return;
            n_variations = int.parse(widget.name);
            changed();
            return;
        }

    }

}

#endif /* HAVE_WEBKIT */
