/* MainPane.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    public class MainPane : DualPaned {

        public Json.Array? available_fonts { get; set; default = null; }
        public Reject? disabled_families { get; set; default = null; }

        public Mode mode { get; set; default = 0; }
        public UserActionModel user_actions { get; set; }
        public UserSourceModel user_sources { get; set; }

        public WaterfallSettings waterfall_settings { get; set; }
        public int predefined_size { get; set; }
        public bool show_line_size { get; set; }

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

        Gtk.Stack content;
        Gdk.Rectangle clicked_area;

        SidebarStack sidebar;
        FontListView fontlist;
        ComparePane compare;
        PreviewPane preview;

        static construct {
            install_property_action("predefined-size", "predefined-size");
            install_property_action("show-line-size", "show-line-size");
        }

        public MainPane (GLib.Settings? settings) {
            base(settings);
            sidebar = new SidebarStack(settings);
            fontlist = new FontListView();
            preview = new PreviewPane();
            compare = new ComparePane(settings);
            content = new Gtk.Stack() {
                transition_type = Gtk.StackTransitionType.CROSSFADE,
                transition_duration = 420
            };
            content.add_named(preview, Mode.MANAGE.to_string());
            content.add_named(compare, Mode.COMPARE.to_string());
            set_sidebar_widget(sidebar);
            set_list_widget(fontlist);
            set_content_widget(content);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("available-fonts", fontlist, "available-fonts", flags);
            bind_property("available-fonts", sidebar, "available-fonts", flags);
            bind_property("user-actions", fontlist, "user-actions", flags);
            bind_property("user-sources", fontlist, "user-sources", flags);
            bind_property("disabled-families", fontlist, "disabled-families", flags);
            bind_property("disabled-families", sidebar, "disabled-families", flags);
            sidebar.bind_property("filter", fontlist, "filter", flags);
            fontlist.bind_property("selected-item", sidebar, "selected-item", flags);
            fontlist.bind_property("selected-items", compare, "selected-items", flags);
            fontlist.bind_property("selected-children", compare, "selected-children", flags);
            preview.bind_property("page", sidebar, "mode", flags);
            sidebar.bind_property("selected-orthography", preview, "orthography", flags);
            notify["mode"].connect(on_mode_changed);
            fontlist.selection_changed.connect(on_selection_changed);
            sidebar.changed.connect(() => { fontlist.queue_update(); });
            fontlist.collection_changed.connect(() => { sidebar.update_collections(); });
            clicked_area = Gdk.Rectangle();
            Gtk.Gesture right_click = new Gtk.GestureClick() {
                button = Gdk.BUTTON_SECONDARY
            };
            ((Gtk.GestureClick) right_click).pressed.connect(on_show_context_menu);
            preview.add_controller(right_click);
            notify["waterfall-settings"].connect(() => {
                BindingFlags _flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
                waterfall_settings.bind_property("predefined-size", this, "predefined-size", _flags);
                waterfall_settings.bind_property("show-line-size", this, "show-line-size", _flags);
            });
            notify["predefined-size"].connect_after(() => {
                waterfall_settings.on_selection_changed();
                preview.set_waterfall_size(waterfall_settings.minimum,
                                           waterfall_settings.maximum,
                                           waterfall_settings.ratio);
            });
            preview.restore_state(settings);
        }

        public void search (string needle) {
            mode = Mode.MANAGE;
            preview.page = PreviewPanePage.PREVIEW;
            select_first_category();
            select_first_font();
            fontlist.set_search_term(needle);
            return;
        }

        public void select_first_category () {
            sidebar.select_first_category();
            return;
        }

        public void select_first_font () {
            fontlist.select_item(0);
            return;
        }

        public void focus_search_entry () {
            fontlist.focus_search_entry();
            return;
        }

        void on_mode_changed (ParamSpec? pspec) {
            if (mode == Mode.MANAGE || mode == Mode.COMPARE)
                content.set_visible_child_name(((Mode) mode).to_string());
            return;
        }

        void on_selection_changed (Object? item) {
            return_if_fail(item is Font || item is Family);
            var font = new Font();
            if (item is Font)
                font = (Font) item;
            else
                font.source_object = ((Family) item).get_default_variant();
            preview.font = font;
            return;
        }

        void on_show_context_menu (int n_press, double x, double y) {
            if (waterfall_settings == null)
                return;
            if (preview.page != PreviewPanePage.PREVIEW || preview.preview_mode != PreviewPageMode.WATERFALL)
                return;
            clicked_area.x = (int) x;
            clicked_area.y = (int) y;
            clicked_area.width = 2;
            clicked_area.height = 2;
            if (waterfall_settings.context_menu.get_parent() != null)
                waterfall_settings.context_menu.unparent();
            waterfall_settings.context_menu.set_parent(preview);
            waterfall_settings.context_menu.set_pointing_to(clicked_area);
            waterfall_settings.context_menu.popup();
            return;
        }

    }

}



