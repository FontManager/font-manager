/* Sidebar.vala
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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
            widget_set_margin(this, MIN_MARGIN * 2);
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

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-sidebar.ui")]
    public class Sidebar : Gtk.Box {

        public signal void changed();

        public FontListFilter? filter { get; set; default = null; }
        public Json.Array? available_fonts { get; set; default = null; }
        public Reject? disabled_families { get; set; default = null; }
        public SortType sort_type { get; set; default = SortType.NONE; }

        public CategoryListModel category_model {
            get {
                return (CategoryListModel) categories.model;
            }
        }

        public CollectionListModel collection_model {
            get {
                return (CollectionListModel) collections.model;
            }
        }

        SidebarControls controls;

        [GtkChild] unowned CategoryListView categories;
        [GtkChild] unowned CollectionListView collections;
        [GtkChild] unowned Gtk.MenuButton collection_sort_type;

        static construct {
            install_property_action("sort-type", "sort-type");
        }

        public Sidebar () {
            controls = new SidebarControls();
            controls.valign = Gtk.Align.END;
            append(controls);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("disabled-families", categories, "disabled-families", flags);
            bind_property("disabled-families", collections, "disabled-families", flags);
            bind_property("sort-type", collection_model, "sort-type", BindingFlags.BIDIRECTIONAL);
            categories.selection_changed.connect(on_category_changed);
            collections.selection_changed.connect(on_collection_changed);
            controls.add_selected.connect(on_add_selected);
            controls.remove_selected.connect(on_remove_selected);
            controls.edit_selected.connect(on_edit_selected);
            categories.selection.select_item(0, true);
            collection_sort_type.set_menu_model(get_sort_type_menu_model());
            map.connect_after(() => {
                categories.sorted = get_available_sorted();
            });
            collections.changed.connect_after(() => {
                categories.sorted = get_available_sorted();
                changed();
            });
        }

        StringSet get_available_sorted () {
            var result = ((CollectionListModel) collections.model).get_full_contents();
            var available = list_available_font_families();
            result.retain_all(available);
            return result;
        }

        public void select_first_row () {
            categories.select_item(0);
            return;
        }

        public void update_collections () {
            collections.queue_update();
            collections.save();
            categories.sorted = get_available_sorted();
            changed();
            return;
        }

        void on_add_selected () {
            collections.add_new_collection();
            return;
        }

        void on_edit_selected () requires (categories.language_filter != null) {
            var main_window = get_default_application().main_window;
            var filter_settings = categories.language_filter.settings;
            var dialog = new LanguageSettingsDialog(main_window, filter_settings);
            dialog.present();
            return;
        }

        void on_remove_selected () {
            collections.remove_selected_collection();
            return;
        }

        void on_selection_changed (FilterListView view, FontListFilter? item) {
            filter = item;
            view.selection.unselect_item(view.selected_position);
            bool removable = (filter is Collection);
            bool language_filter = filter is LanguageFilter;
            controls.removable = removable;
            controls.editable = language_filter;
            if (language_filter) {
                controls.edit_button.has_frame = true;
                controls.edit_button.add_css_class(STYLE_CLASS_SUGGESTED_ACTION);
            } else {
                controls.edit_button.has_frame = false;
                controls.edit_button.remove_css_class(STYLE_CLASS_SUGGESTED_ACTION);
            }
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

        public signal void changed();

        public Object? selected_item { get; set; default = null; }
        public GLib.Settings? settings { get; protected set; default = null; }
        public FontListFilter? filter { get; set; default = null; }
        public Json.Array? available_fonts { get; set; default = null; }
        public Reject? disabled_families { get; set; default = null; }
        public Orthography? selected_orthography { get; set; default = null; }

        public PreviewPanePage mode {
            set {
                if (value == PreviewPanePage.CHARACTER_MAP)
                    stack.set_visible_child(orthographies);
                else
                    stack.set_visible_child(sidebar);
            }
        }

        public CategoryListModel category_model {
            get {
                return sidebar.category_model;
            }
        }

        public CollectionListModel collection_model {
            get {
                return sidebar.collection_model;
            }
        }

        Gtk.Stack stack;
        Sidebar sidebar;
        OrthographyList orthographies;

        public SidebarStack (GLib.Settings? settings) {
            Object(settings: settings);
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
            bind_property("available-fonts", sidebar, "available-fonts", flags);
            bind_property("disabled-families", sidebar, "disabled-families", flags);
            bind_property("selected-item", orthographies, "selected-item", flags);
            orthographies.bind_property("selected-orthography", this, "selected-orthography", flags);
            sidebar.changed.connect(() => { changed(); });
            if (settings != null)
                settings.bind("sort-type", collection_model, "sort-type", SettingsBindFlags.DEFAULT);
        }

        public void select_first_category () {
            sidebar.select_first_row();
            return;
        }

        public void update_collections () {
            sidebar.update_collections();
            return;
        }

    }

}

