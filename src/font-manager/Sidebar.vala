/* Sidebar.vala
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

    public class SidebarControls : Gtk.Box {

        public signal void add_selected ();
        public signal void remove_selected ();
        public signal void edit_selected ();

        public Gtk.Button add_button { get; protected set; }
        public Gtk.Button remove_button { get; protected set; }
        public Gtk.Button edit_button { get; protected set; }

        public bool removable {
            get {
                return remove_button.sensitive;
            }
            set {
                set_control_sensitivity(remove_button, value);
            }
        }

        public bool editable {
            get {
                return edit_button.sensitive;
            }
            set {
                set_control_sensitivity(edit_button, value);
            }
        }

        construct {
            opacity = 0.9;
            spacing = DEFAULT_MARGIN;
            margin_start = margin_end = margin_top = margin_bottom = MIN_MARGIN * 2;
            add_button = new Gtk.Button.from_icon_name("list-add-symbolic") {
                has_frame = false,
                tooltip_text = _("Add new collection")
            };
            remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic") {
                has_frame = false,
                tooltip_text = _("Remove selected item")
            };
            edit_button = new Gtk.Button.from_icon_name("document-edit-symbolic") {
                hexpand = true,
                has_frame = false,
                halign = Gtk.Align.END,
                tooltip_text = _("Edit selected item")
            };
            set_control_sensitivity(remove_button, false);
            set_control_sensitivity(edit_button, false);
            add_button.clicked.connect((w) => { add_selected(); });
            remove_button.clicked.connect(() => { remove_selected(); });
            edit_button.clicked.connect(() => { edit_selected(); });
            append(add_button);
            append(remove_button);
            append(edit_button);
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-sidebar.ui")]
    public class Sidebar : Gtk.Box {

        public FontListFilter? filter { get; set; default = null; }
        public StringSet? available_families { get; set; default = null; }

        SidebarControls controls;

        [GtkChild] unowned CategoryListView categories;
        [GtkChild] unowned CollectionListView collections;

        public Sidebar () {
            var families = new StringSet();
            foreach (var family in list_available_font_families())
                families.add(family);
            available_families = families;
            controls = new SidebarControls();
            controls.valign = Gtk.Align.END;
            append(controls);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("available-families", categories, "available-families", flags);
            categories.selection_changed.connect(on_category_changed);
            collections.selection_changed.connect(on_collection_changed);
            controls.add_selected.connect(on_add_selected);
            controls.remove_selected.connect(on_remove_selected);
            controls.edit_selected.connect(on_edit_selected);
            categories.selection.select_item(0, true);
        }

        void on_add_selected () {
            message("Add not implemented");
            return;
        }

        void on_edit_selected () {
            message("Edit not implemented");
            return;
        }

        void on_remove_selected () {
            message("Remove not implemented");
            return;
        }

        void on_selection_changed (FilterListView view, FontListFilter? item) {
            filter = item;
            view.selection.unselect_item(view.selected_position);
            bool removable = !(filter is Category);
            bool language_filter = filter is LanguageFilter;
            controls.removable = removable;
            controls.editable = removable || language_filter;
            return;
        }

        void on_category_changed (FontListFilter? item) {
            on_selection_changed(collections, item);
            return;
        }

        void on_collection_changed (FontListFilter? item) {
            on_selection_changed(categories, item);
            return;
        }

    }

    public class SidebarStack : Gtk.Box {

        public Object? selected_item { get; set; default = null; }

        public FontListFilter? filter { get; set; default = null; }
        public StringSet? available_families { get; set; default = null; }
        public Orthography? selected_orthography { get; set; default = null; }

        public PreviewPanePage mode {
            set {
                if (value == PreviewPanePage.CHARACTER_MAP)
                    stack.set_visible_child(orthographies);
                else
                    stack.set_visible_child(sidebar);
            }
        }

        Gtk.Stack stack;
        Sidebar sidebar;
        OrthographyList orthographies;

        public SidebarStack () {
            stack = new Gtk.Stack() {
                transition_duration = 500,
                transition_type = Gtk.StackTransitionType.OVER_RIGHT_LEFT
            };
            append(stack);
            sidebar = new Sidebar();
            orthographies = new OrthographyList();
            stack.add_child(orthographies);
            stack.add_child(sidebar);
            stack.set_visible_child(sidebar);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            sidebar.bind_property("filter", this, "filter", flags);
            bind_property("available-families", sidebar, "available-families", flags);
            bind_property("selected-item", orthographies, "selected-item", flags);
            orthographies.bind_property("selected-orthography", this, "selected-orthography", flags);
        }

    }

}

