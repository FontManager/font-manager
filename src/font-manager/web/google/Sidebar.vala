/* Sidebar.vala
 *
 * Copyright (C) 2020-2023 Jerry Casiano
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

    public class Filter : FontListFilter {

        public int n_variations { get; set; }
        public StringSet categories { get; set; }
        public StringSet language_support { get; set; }

        public override bool matches (Object? item) {
            return_val_if_fail(item != null, false);
            return_val_if_fail(item is Family, false);
            var family = (Family) item;
            if (categories.size < 5 && !(family.category in categories))
                return false;
            if (family.count < n_variations)
                return false;
            if (language_support.size > 0) {
                foreach (string entry in language_support)
                    if (entry in family.subsets)
                        return true;
                return false;
            }
            return true;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-fonts-sidebar.ui")]
    public class Sidebar : Gtk.Box {

        public signal void sort_changed (string order);

        public int n_variations { get; private set; default = 0; }
        public Filter filter { get; private set; }
        public StringSet categories { get; private set; }
        public StringSet language_support { get; private set; }

        [GtkChild] unowned Gtk.DropDown sort_order;
        [GtkChild] unowned Gtk.Grid category_grid;
        [GtkChild] unowned Gtk.ListBox language_list;

        string sort_options [4] = { "alpha", "date", "popularity", "trending" };

        public Sidebar () {
            widget_set_name(category_grid, "FontManagerGoogleFontsCategories");
            widget_set_name(language_list, "FontManagerGoogleFontsOrthographies");
            categories = new StringSet();
            language_support = new StringSet();
            foreach (var lang in Languages) {
                var label = dgettext(null, lang.label);
                var check = new Gtk.CheckButton.with_label(label) {
                    can_focus = false,
                    name = lang.name
                };
                language_list.insert(check, -1);
                check.toggled.connect(on_language_toggled);
            }
            // Defined in ui file
            Gtk.Widget? widget = category_grid.get_first_child();
            while (widget != null) {
                categories.add(widget.name);
                widget = widget.get_next_sibling();
            }
            filter = new Filter();
            BindingFlags flags = BindingFlags.SYNC_CREATE;
            bind_property("n-variations", filter, "n-variations", flags);
            bind_property("categories", filter, "categories", flags);
            bind_property("language-support", filter, "language-support", flags);
            sort_order.notify["selected"].connect(() => {
                sort_changed(sort_options[sort_order.selected]);
            });
        }

        [GtkCallback]
        void on_category_toggled (Gtk.CheckButton widget) {
            if (widget.active)
                categories.add(widget.name);
            else
                categories.remove(widget.name);
            filter.changed();
            return;
        }

        void on_language_toggled (Gtk.CheckButton widget) {
            if (widget.active)
                language_support.add(widget.name);
            else
                language_support.remove(widget.name);
            filter.changed();
            return;
        }

        [GtkCallback]
        void on_variations_toggled (Gtk.ToggleButton widget) {
            if (!widget.active)
                return;
            n_variations = int.parse(widget.name);
            filter.changed();
            return;
        }

    }

}

#endif /* HAVE_WEBKIT */

