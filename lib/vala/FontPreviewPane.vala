/* FontPreviewPane.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

    /**
     * FontPreview - Full featured font preview widget
     *
     * -----------------------------------------------------------------
     * |                    |                       |                  |
     * |   #ActivePreview   |   #WaterfallPreview   |   #TextPreview   |
     * |                    |                       |                  |
     * -----------------------------------------------------------------
     */
    public class FontPreview : Gtk.Stack {

        /**
         * FontPreview::mode_changed:
         *
         * Emmitted when a different mode is selected by user
         */
        public signal void mode_changed (string mode);

        /**
         * FontPreview::preview_text_changed:
         *
         * Emitted when the preview text has changed
         */
        public signal void preview_text_changed (string preview_text);

        /**
         * FontPreview:pangram:
         *
         * The pangram displayed in #WaterfallPreview
         */
        public string pangram {
            get {
                return waterfall.pangram;
            }
            set {
                waterfall.pangram = "%s\n".printf(value);
            }
        }

        /**
         * FontPreview:preview_size:
         *
         * Font point size
         */
        public double preview_size {
            get {
                return preview.preview_size;
            }
            set {
                adjustment.value = value;
            }
        }

        /**
         * FontPreview:selected_font:
         *
         * #FontConfigFont in use
         */
        public Font? selected_font { get; set; default = null; }

        /**
         * FontPreview:mode:
         *
         * One of "Preview", "Waterfall" or "Body Text"
         */
        public string mode {
            get {
                return get_visible_child_name();
            }
            set {
                set_visible_child_name(value);
            }
        }

        public Json.Object? samples { get; set; default = null; }
        public bool restore_default_preview = false;

        protected ActivePreview preview;
        protected WaterfallPreview waterfall;
        protected TextPreview body_text;
        protected StandardTextTagTable tag_table;
        protected Gtk.Adjustment adjustment;

        bool _visible_ = false;

        public FontPreview () {
            Object(name: "FontPreview");
            tag_table = new StandardTextTagTable();
            preview = new ActivePreview(tag_table);
            waterfall = new WaterfallPreview(tag_table);
            body_text = new TextPreview(tag_table);
            body_text.preview.name = "BodyTextPreview";
            adjustment = new Gtk.Adjustment(DEFAULT_PREVIEW_SIZE,
                                              MIN_FONT_SIZE, MAX_FONT_SIZE,
                                              0.5, 1.0, 0);
            preview.adjustment = body_text.adjustment = adjustment;
            add_titled(preview, "Preview", _("Preview"));
            add_titled(waterfall, "Waterfall", _("Waterfall"));
            add_titled(body_text, "Body Text", _("Body Text"));
            set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            connect_signals();
        }

        void connect_signals () {
            preview.preview_text_changed.connect((n) => { preview_text_changed(n); });
            preview.notify["preview-size"].connect(() => { notify_property("preview-size"); });
            notify["visible-child-name"].connect(() => { mode_changed(mode); });
            notify["selected-font"].connect(() => { update_text_tag(); });
            adjustment.value_changed.connect(() => { update_text_tag(); });
            map.connect(() => { _visible_ = true; update_text_tag(); });
            unmap.connect(() => { _visible_ = false; });
        }

        /**
         * set_preview_text:
         * @preview_text:   text to display in preview
         */
        public void set_preview_text (string preview_text) {
            preview.set_preview_text(preview_text);
            return;
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            preview.show();
            waterfall.show();
            body_text.show();
            base.show();
            return;
        }

        void update_text_tag () {
            if (!_visible_)
                return;
            string description = is_valid_source(selected_font) ? selected_font.description : "";
            Gtk.TextTag tag = tag_table.lookup("FontDescription");
            tag.set("font-desc", Pango.FontDescription.from_string(description),
                     "size-points", preview_size,
                     "fallback", false, null);
            preview.controls.title = description;
            /* Prevent tofu if possible */
            if (samples != null && samples.has_member(description)) {
                string sample = samples.get_string_member(description);
                waterfall.pangram = sample;
                if (restore_default_preview || preview.get_preview_text() == get_localized_preview_text()) {
                    restore_default_preview = true;
                    preview.set_preview_text(sample);
                }
            } else if (waterfall.pangram != get_localized_pangram()) {
                waterfall.pangram = null;
                if (restore_default_preview) {
                    restore_default_preview = false;
                    preview.set_preview_text(get_localized_preview_text());
                }
            }
            return;
        }

    }

    public enum FontPreviewMode {
        PREVIEW,
        WATERFALL,
        BODY_TEXT,
        N_MODES;

        public static FontPreviewMode parse (string mode) {
            switch (mode.down()) {
                case "waterfall":
                    return FontPreviewMode.WATERFALL;
                case "body text":
                    return FontPreviewMode.BODY_TEXT;
                default:
                    return FontPreviewMode.PREVIEW;
            }
        }

        public string to_string () {
            switch (this) {
                case WATERFALL:
                    return "Waterfall";
                case BODY_TEXT:
                    return "Body Text";
                default:
                    return "Preview";
            }
        }

        public string to_translatable_string () {
            switch (this) {
                case WATERFALL:
                    return _("Waterfall");
                case BODY_TEXT:
                    return _("Body Text");
                default:
                    return _("Preview");
            }
        }

    }

    public class FontPreviewPane : Gtk.Box {

        public signal void changed ();
        public signal void preview_mode_changed (FontPreviewMode mode);
        public signal void preview_text_changed (string preview_text);

        public Gtk.Notebook notebook { get; private set; }
        public FontPreview preview { get; private set; }
        public CharacterTable charmap { get; private set; }

        public double preview_size { get; set; }

        public Font? selected_font { get; set; default = null; }
        public Metadata? metadata { get; set; default = null; }

        public FontPreviewMode mode {
            get {
                return FontPreviewMode.parse(preview.mode);
            }
            set {
                preview.mode = value.to_string();
            }
        }

        Gtk.Label preview_tab_label;
        Gtk.MenuButton menu_button;

        public FontPreviewPane () {
            Object(name: "FontManagerFontPreviewPane", orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            insert_action_group("default", new SimpleActionGroup());
            notebook = new Gtk.Notebook();
            notebook.show_border = false;
            preview = new FontPreview();
            preview_tab_label = new Gtk.Label(FontPreviewMode.PREVIEW.to_translatable_string());
            notebook.append_page(preview, preview_tab_label);
            metadata = new Metadata();
            charmap = new CharacterTable();
            notebook.append_page(charmap, new Gtk.Label(_("Characters")));
            notebook.append_page(metadata.properties, new Gtk.Label(_("Properties")));
            notebook.append_page(metadata.license, new Gtk.Label(_("License")));
            menu_button = construct_menu_button();
            notebook.set_action_widget(menu_button, Gtk.PackType.START);
            pack_end(notebook, true, true, 0);
            connect_signals();
            bind_properties();
        }

        void connect_signals () {
            notebook.switch_page.connect((p, n) => {
                menu_button.sensitive = ((FontPreviewMode) n == FontPreviewMode.PREVIEW);
            });
            preview.mode_changed.connect((m) => {
                preview_tab_label.set_text(mode.to_translatable_string());
                var actions = ((SimpleActionGroup) get_action_group("default"));
                actions.lookup_action("preview_mode").change_state(mode.to_string());
                if (menu_button.use_popover)
                    menu_button.popover.hide();
                else
                    menu_button.popup.hide();
                preview_mode_changed(FontPreviewMode.parse(m));
            });
            preview.preview_text_changed.connect((p) => {
                preview_text_changed(p);
            });
            notify["selected-font"].connect_after(() => { changed(); });
            return;
        }

        void bind_properties () {
            bind_property("preview-size", preview, "preview-size", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("selected-font", charmap, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            bind_property("selected-font", metadata, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            bind_property("selected-font", preview, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
        }

        public override void show () {
            notebook.show();
            preview.show();
            charmap.show();
            metadata.show();
            base.show();
            return;
        }

        public virtual void show_uri (string uri) {
            File file = File.new_for_commandline_arg(uri);
            try {
                FileInfo info = file.query_info(FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
                if (!info.get_content_type().contains("font")) {
                    warning("Ignoring unsupported filetype");
                    return;
                }
            } catch (Error e) {
                critical(e.message);
            }
            string path = file.get_path();
            clear_application_fonts();
            add_application_font(path);
            Font font = new Font();
            font.source_object = get_attributes_from_filepath(path, 0);
            {
                Json.Object orthography = get_orthography_results(font.source_object);
                if (!orthography.has_member("Basic Latin")) {
                    GLib.List <unichar> charset = get_charset_from_filepath(path, 0);
                    if (preview.samples == null)
                        preview.samples = new Json.Object();
                    string? sample = get_sample_string_for_orthography(orthography, charset);
                    if (sample != null)
                        preview.samples.set_string_member(font.description, sample);
                }
            }
            selected_font = font;
            return;
        }

        public void set_preview_text (string preview_text) {
            preview.set_preview_text(preview_text);
            return;
        }

        public override void drag_data_received (Gdk.DragContext context,
                                                     int x,
                                                     int y,
                                                     Gtk.SelectionData selection_data,
                                                     uint info,
                                                     uint time) {
            switch (info) {
                case DragTargetType.EXTERNAL:
                    show_uri(selection_data.get_uris()[0]);
                    break;
                default:
                    warning("Unsupported drag target.");
                    return;
            }
            return;
        }

        Gtk.MenuButton construct_menu_button () {
            var application = (Gtk.Application) GLib.Application.get_default();
            var mb = new Gtk.MenuButton();
            mb.margin = MINIMUM_MARGIN_SIZE;
            mb.direction = Gtk.ArrowType.DOWN;
            mb.relief = Gtk.ReliefStyle.NONE;
            mb.can_focus = false;
            var mb_icon = new Gtk.Image.from_icon_name("view-more-symbolic", Gtk.IconSize.MENU);
            mb.add(mb_icon);
            var actions = ((SimpleActionGroup) get_action_group("default"));
            var mode_section = new GLib.Menu();
            string [] modes = { "Preview", "Waterfall", "Body Text" };
            var mode_action = new SimpleAction.stateful("preview_mode", VariantType.STRING, "Preview");
            mode_action.set_state(modes[0]);
            application.add_action(mode_action);
            actions.add_action(mode_action);
            mode_action.activate.connect((a, s) => {
                this.mode = FontPreviewMode.parse((string) s);
                a.set_state((string) s);
            });
            int i = 0;
            foreach (string mode in modes) {
                i++;
                string? accels [] = {"<Alt>%i".printf(i), null };
                string action_name = "app.preview_mode::%s".printf(mode);
                application.set_accels_for_action(action_name, accels);
                string display_name = FontPreviewMode.parse(mode).to_translatable_string();
                GLib.MenuItem item = new MenuItem(display_name, action_name);
                item.set_attribute("accel", "s", accels[0]);
                mode_section.append_item(item);
            }
            mb.set_menu_model((GLib.MenuModel) mode_section);
            mb.set_tooltip_text(_("Select preview type"));
            mb.show_all();
            return mb;
        }

    }

}
