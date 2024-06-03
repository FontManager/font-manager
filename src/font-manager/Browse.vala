/* Browse.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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

    public enum PreviewTileSize {

        SMALL = 96,
        MEDIUM = 128,
        LARGE = 144,
        XLARGE = 192,
        XXLARGE = 256;

        public int to_preview_size () {
            switch (this) {
                case SMALL:
                    return 10;
                case MEDIUM:
                    return 12;
                case XLARGE:
                    return 20;
                case XXLARGE:
                    return 24;
                default:
                    return 14;
            }
        }

        public double to_double () {
            switch (this) {
                case SMALL:
                    return 0.0f;
                case MEDIUM:
                    return 1.0f;
                case XLARGE:
                    return 3.0f;
                case XXLARGE:
                    return 4.0;
                default:
                    return 2.0f;
            }
        }

        public static PreviewTileSize from_double (double val)
        requires (val >= 0.0f && val <= 4.0f) {
            if (val == 0.0)
                return PreviewTileSize.SMALL;
            else if (val == 1.0)
                return PreviewTileSize.MEDIUM;
            else if (val == 2.0)
                return PreviewTileSize.LARGE;
            else if (val == 3.0)
                return PreviewTileSize.XLARGE;
            else
                return PreviewTileSize.XXLARGE;
        }

    }

    public class FontPreviewTile : Gtk.Frame {

        public Object? item { get; set; default = null; }
        public PreviewTileSize size { get; set; default = PreviewTileSize.LARGE; }

        public Gtk.Inscription preview { get; protected set; }

        public FontPreviewTile () {
            widget_set_name(this, "FontManagerFontPreviewTile");
            widget_set_margin(this, 6);
            preview = new Gtk.Inscription(null) {
                halign = Gtk.Align.FILL,
                valign = Gtk.Align.FILL,
                xalign = 0.5f,
                yalign = 0.5f,
                hexpand = true,
                vexpand = true
            };
            set_child(preview);
            notify["item"].connect((pspec) => { on_item_set(); });
        }

        public void reset () {
            preview.set_text(null);
            set_size_request(size, size);
            return;
        }

        public void on_item_set () {
            reset();
            if (item == null)
                return;
            Family f = (Family) item;
            set_tooltip_text(f.family);
            string preview_text = f.preview_text != null ? f.preview_text : f.family;
            preview.set_text(preview_text);
            Pango.FontDescription font_desc;
            font_desc = Pango.FontDescription.from_string(f.description);
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            attrs.insert(Pango.AttrSize.new(size.to_preview_size() * Pango.SCALE));
            attrs.insert(new Pango.AttrFontDesc(font_desc));
            preview.set_attributes(attrs);
            return;
        }

    }

    public class FontGridView : FontListBase {

        public PreviewTileSize size { get; set; default = PreviewTileSize.LARGE; }

        unowned Gtk.ScrolledWindow container;

        public FontGridView (Gtk.ScrolledWindow parent) {
            container = parent;
            model = new FontModel();
            parent.map.connect(() => { update(); });
            notify["size"].connect(() => { create_gridview(); });
            bind_property("available-fonts", model, "entries", BindingFlags.DEFAULT, null, null);
        }

        public void set_search_entry (Gtk.SearchEntry entry) {
            search_entry = entry;
            return;
        }

        public void create_gridview () {
            uint previous_selection = current_selection;
            list = null;
            container.set_child(null);
            if (container.visible)
                container.set_visible(false);
            list = new Gtk.GridView(null, null) { hexpand = true, vexpand = true };
            selection = new Gtk.SingleSelection(model) { autoselect = false };
            container.set_child(list);
            container.set_visible(true);
            if (model.get_n_items() > 0)
                Idle.add(() => {
                    uint select = previous_selection < model.get_n_items() ?
                                  previous_selection : 0;
                    select_item(select);
                    return GLib.Source.REMOVE;
                });
            return;
        }

        public override void update (uint position = 0) {
            if (list == null)
                create_gridview();
            base.update(position);
            return;
        }

        protected override void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var child = new FontPreviewTile();
            bind_property("size", child, "size", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            list_item.set_child(child);
            return;
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var row = (FontPreviewTile) list_item.get_child();
            Object? tmp = list_item.get_item();
            // Setting item triggers update to row widget
            row.item = tmp;
            return;
        }

        protected override void on_selection_changed (uint position, uint n_items) {
            base.on_selection_changed(position, n_items);
            selected_item = null;
            Object? item = model.get_item(current_selection);
            selected_item = item;
            selection_changed(item);
            return;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-browse-preview.ui")]
    public class BrowsePreview : Gtk.Box {

        public Reject? disabled_families { get; set; default = null; }
        public Object? selected_item { get; protected set; default = null; }
        public BaseFontModel? model { get; protected set; default = null; }

        [GtkChild] unowned Gtk.Label family_label;
        [GtkChild] unowned Gtk.Label n_glyphs;
        [GtkChild] unowned Gtk.DropDown style_drop_down;
        [GtkChild] unowned Gtk.ScrolledWindow character_map_scroll;
        [GtkChild] unowned Gtk.Expander glyph_expander;
        [GtkChild] unowned Gtk.Expander preview_expander;
        [GtkChild] unowned Gtk.MenuButton preview_menu;
        [GtkChild] unowned Gtk.Switch font_state;

        PreviewPage preview_page;
        UnicodeCharacterMap character_map;

        bool ignore_activation = false;

        construct {
            widget_set_name(this, "FontManagerBrowsePreview");
            style_drop_down.set_factory(get_style_factory());
            var button = style_drop_down.get_first_child();
            if (button is Gtk.ToggleButton)
                button.has_frame = false;
            character_map = new UnicodeCharacterMap() { hexpand = true, vexpand = true };
            character_map.add_css_class("BrowsePaneCharacterMap");
            widget_set_name(n_glyphs, "BrowsePaneGlyphCount");
            character_map_scroll.set_child(character_map);
            character_map_scroll.set_size_request(-1, 360);
            preview_page = new PreviewPage() { hexpand = true, vexpand = true, show_line_size = false };
            preview_page.set_size_request(-1, 360);
            preview_page.set_waterfall_size(-1, 36, -1);
            preview_page.get_last_child().set_visible(false);
            preview_expander.set_child(preview_page);
            set_preview_page_mode_menu_and_actions(this, preview_menu, (GLib.Callback) on_preview_mode_activated);
            ((GLib.Menu) preview_menu.menu_model).remove(0);
            var scroll = preview_page.get_first_child().get_next_sibling();
            if (scroll is Gtk.ScrolledWindow)
                ((Gtk.ScrolledWindow) scroll).set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER);
            glyph_expander.notify["expanded"].connect(() => {
                preview_expander.expanded = !glyph_expander.expanded;
            });
            preview_expander.notify["expanded"].connect(() => {
                glyph_expander.expanded = !preview_expander.expanded;
            });
            font_state.notify["active"].connect(() => { on_item_state_changed(); });
            notify["selected-item"].connect(() => { on_item_selected(); });
            style_drop_down.notify["selected"].connect(() => {  on_variant_selected(); });
            character_map.selection_changed.connect((codepoint, name, n_codepoints) => {
                n_glyphs.set_label(n_codepoints);
            });
            notify["disabled-families"].connect(() => {
                font_state.sensitive = disabled_families != null;
                if (disabled_families != null)
                    disabled_families.changed.connect(() => { on_item_selected(); });
            });
        }

        [CCode (instance_pos = -1)]
        void on_preview_mode_activated (SimpleAction action, Variant parameter) {
            PreviewPageMode mode = PreviewPageMode.LOREM_IPSUM;
            string param = (string) parameter;
            if (param == "Waterfall")
                mode = PreviewPageMode.WATERFALL;
            if (param == "Preview")
                mode = PreviewPageMode.PREVIEW;
            preview_page.preview_mode = mode;
            action.set_state(parameter);
            return;
        }

        void on_item_state_changed () {
            if (ignore_activation || selected_item == null)
                return;
            Family family = ((Family) selected_item);
            family.active = font_state.active;
            if (family.active)
                disabled_families.remove(family.family);
            else
                disabled_families.add(family.family);
            disabled_families.save();
            return;
        }

        void on_item_selected () {
            if (selected_item == null)
                return;
            Family family = ((Family) selected_item);
            int default_index = family.get_default_index();
            family_label.set_label(family.family);
            var child_model = ((FontModel) model).get_child_model(selected_item);
            uint child_size = child_model.get_n_items();
            style_drop_down.set_model(child_model);
            style_drop_down.set_show_arrow(child_size > 1);
            // Index of default variant may be out of range due to filtering. Select the first
            // available option if index is larger than model it *should* be the right one.
            style_drop_down.set_selected(default_index < child_size ? default_index : 0);
            ignore_activation = true;
            font_state.set_active(family.active);
            ignore_activation = false;
            return;
        }

        void on_variant_selected () {
            uint selected_variant = style_drop_down.selected;
            if (selected_variant == Gtk.INVALID_LIST_POSITION)
                return;
            Font selected_font = (Font) style_drop_down.get_model().get_item(selected_variant);
            Pango.FontDescription font_desc = Pango.FontDescription.from_string(selected_font.description);
            font_desc.set_size(10 * Pango.SCALE);
            character_map.set_font_desc(font_desc);
            preview_page.set_font(selected_font);
            return;
        }

        protected void setup_style_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var child = new Gtk.Label(null);
            child.add_css_class("heading");
            list_item.set_child(child);
            return;
        }

        protected void bind_style_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var label = (Gtk.Label) list_item.get_child();
            Font? font = (Font) list_item.get_item();
            return_if_fail(font != null);
            label.set_label(font.style);
            return;
        }

        Gtk.SignalListItemFactory get_style_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_style_row);
            factory.bind.connect(bind_style_row);
            return factory;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-browse-pane.ui")]
    public class BrowsePane : Gtk.Box {

        public GLib.Settings? settings { get; protected set; default = null; }

        public Json.Array? available_fonts { get; set; default = null; }
        public Reject? disabled_families { get; set; default = null; }
        public PreviewTileSize size { get; set; default = PreviewTileSize.LARGE; }

        public double pane_position { get; set; default = 55.0f; }

        [GtkChild] unowned Gtk.SearchBar search_bar;
        [GtkChild] unowned Gtk.SearchEntry search_entry;
        [GtkChild] unowned Gtk.Revealer panel_revealer;
        [GtkChild] unowned Gtk.ToggleButton panel_toggle;
        [GtkChild] unowned Gtk.ToggleButton search_toggle;
        [GtkChild] unowned Gtk.Adjustment icon_size_adjustment;
        [GtkChild] unowned Gtk.ScrolledWindow gridview_container;
        [GtkChild] unowned Gtk.Paned paned;

        BrowsePreview preview;
        FontGridView gridview;

        static construct {
            install_action("toggle-search", null, (Gtk.WidgetActionActivateFunc) toggle_search);
            Gdk.ModifierType mode_mask = Gdk.ModifierType.CONTROL_MASK;
            add_binding_action(Gdk.Key.F, mode_mask, "toggle-search", null);
        }

        public BrowsePane (GLib.Settings? settings) {
            Object(settings: settings);
            widget_set_name(this, "FontManagerBrowsePane");
            gridview = new FontGridView(gridview_container);
            gridview.set_search_entry(search_entry);
            gridview_container.set_child(gridview);
            preview = new BrowsePreview();
            preview.margin_bottom = 0;
            panel_revealer.set_child(preview);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            gridview.bind_property("model", preview, "model", flags);
            gridview.bind_property("selected-item", preview, "selected-item", flags);
            bind_property("available-fonts", gridview, "available-fonts", flags, null, null);
            bind_property("disabled-families", gridview, "disabled-families", flags, null, null);
            bind_property("disabled-families", preview, "disabled-families", flags, null, null);
            flags = BindingFlags.BIDIRECTIONAL;
            bind_property("size", gridview, "size", flags, null, null);
            panel_toggle.bind_property("active", panel_revealer, "visible", flags);
            panel_toggle.bind_property("active", panel_revealer, "reveal-child", flags);
            search_toggle.bind_property("active", search_bar, "search-mode-enabled", flags);
            icon_size_adjustment.set_value(size.to_double());
            paned.notify["position"].connect(() => {
                double new_position = position_to_percentage();
                if (pane_position != new_position)
                    pane_position = new_position;
            });
            notify["pane-position"].connect(() => {
                double current_position = position_to_percentage();
                if (pane_position != current_position)
                    paned.position = percentage_to_position(pane_position);
            });
            gridview.activated.connect(() => {
                panel_toggle.set_active(!panel_toggle.active);
            });
            map.connect_after(on_map);
        }

        public void on_map () {
            Idle.add(() => {
                if (settings != null) {
                    pane_position = settings.get_double("browse-pane-position");
                    panel_toggle.set_active(settings.get_boolean("browse-preview-visible"));
                    settings.bind("browse-pane-position", this, "pane-position", SettingsBindFlags.DEFAULT);
                    settings.bind("browse-preview-visible"\, panel_toggle, "active", SettingsBindFlags.DEFAULT);
                }
                paned.set_position(percentage_to_position(pane_position));
                return GLib.Source.REMOVE;
            });
        }

        public void queue_update () {
            gridview.update();
            return;
        }

        void toggle_search (Gtk.Widget widget, string? action, Variant? parameter) {
            search_bar.set_search_mode(!search_bar.get_search_mode());
            return;
        }

        [GtkCallback]
        public void on_decrease_size (Gtk.Button unused) {
            icon_size_adjustment.set_value(icon_size_adjustment.get_value() - 1);
            return;
        }

        [GtkCallback]
        public void on_increase_size (Gtk.Button unused) {
            icon_size_adjustment.set_value(icon_size_adjustment.get_value() + 1);
            return;
        }

        [GtkCallback]
        public void on_scale_changed (Gtk.Range range) {
            range.set_value(Math.round(range.adjustment.get_value()));
            size = PreviewTileSize.from_double(range.get_value());
            return;
        }

        double position_to_percentage () {
            return ((double) paned.position / (double) get_width()) * 100;
        }

        int percentage_to_position (double percent) {
            return (int) ((percent / 100) * (double) get_width());
        }

    }

}


