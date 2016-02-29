/* FontPreviewPane.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

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

        public signal void preview_mode_changed (FontPreviewMode mode);
        public signal void preview_text_changed (string preview_text);
        public signal void updated ();

        public FontPreview preview { get; private set; }
        public Gtk.Notebook notebook { get; private set; }
        public Metadata.Properties properties { get; private set; }
        public Metadata.License license { get; private set; }
        public CharacterTable charmap { get; private set; }

        public double preview_size { get; set; }

        public FontData? font_data {
            get {
                return _font_data;
            }
            set {
                _font_data = value;
                Idle.add(() => {
                    update();
                    return false;
                });
            }
        }

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
        FontData? _font_data = null;

        public FontPreviewPane () {
            Object(name: "FontManagerFontPreviewPane", orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            notebook = new Gtk.Notebook();
            notebook.show_border = false;
            preview = new FontPreview();
            preview.margin_top = 4;
            preview_tab_label = new Gtk.Label(FontPreviewMode.PREVIEW.to_translatable_string());
            notebook.insert_page(preview, preview_tab_label, 0);
            properties = new Metadata.Properties();
            license = new Metadata.License();
            charmap = new CharacterTable();
            var block_model = new Gucharmap.BlockChaptersModel();
            Gtk.TreeIter iter;
            block_model.get_iter_from_string(out iter, "0");
            charmap.table.codepoint_list = block_model.get_codepoint_list(iter);
            notebook.append_page(properties, new Gtk.Label(_("Properties")));
            notebook.append_page(license, new Gtk.Label(_("License")));
            notebook.append_page(charmap, new Gtk.Label(_("Characters")));
            construct_menu_button();
            notebook.set_action_widget(menu_button, Gtk.PackType.START);
            pack_end(notebook, true, true, 0);
            connect_signals();
        }

        void connect_signals () {
            notebook.switch_page.connect((p, n) => {
                menu_button.sensitive = ((FontPreviewMode) n == FontPreviewMode.PREVIEW);
            });
            preview.mode_changed.connect((m) => {
                preview_tab_label.set_text(mode.to_translatable_string());
                var actions = ((SimpleActionGroup) get_action_group("preview"));
                actions.lookup_action("mode").change_state(mode.to_string());
                Idle.add(() => {
                    if (menu_button.use_popover) {
                        menu_button.popover.hide();
                        return menu_button.popover.visible;
                    } else {
                        menu_button.popup.hide();
                        return menu_button.popup.visible;
                    }
                });
                debug("Selected preview mode : %s", m);
                this.preview_mode_changed(FontPreviewMode.parse(m));
            });
            preview.preview_text_changed.connect((p) => {
                this.preview_text_changed(p);
            });
            bind_property("preview-size", preview, "preview-size", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

        public override void show () {
            notebook.show();
            preview.show();
            properties.show();
            license.show();
            charmap.show();
            menu_button.show_all();
            base.show();
            return;
        }

        public virtual void show_uri (string uri) {
            this.open(uri);
            return;
        }

        public virtual void open (string arg)  {
            var file = File.new_for_commandline_arg(arg);
            if (file.query_exists())
                font_data = FontData(file);
            return;
        }

        public void set_preview_text (string preview_text) {
            preview.set_preview_text(preview_text);
            return;
        }

        public virtual void update () {
            if (font_data != null && font_data.file != null)
                FontConfig.add_app_font(font_data.file.get_path());
            Idle.add(() => {
                properties.update(font_data);
                license.update(font_data);
                if (font_data != null && font_data.font != null)
                    preview.font_desc = charmap.font_desc =
                    Pango.FontDescription.from_string(font_data.font.description);
                else
                    preview.font_desc = charmap.font_desc =
                    Pango.FontDescription.from_string(DEFAULT_FONT);
                return false;
            });
            this.updated();
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
                    this.open(selection_data.get_uris()[0]);
                    break;
                default:
                    warning("Unsupported drag target.");
                    return;
            }
            return;
        }

        void construct_menu_button () {
            menu_button = new Gtk.MenuButton();
            menu_button.border_width = 2;
            menu_button.margin_start = 6;
            menu_button.direction = Gtk.ArrowType.DOWN;
            menu_button.relief = Gtk.ReliefStyle.NONE;
            menu_button.can_focus = false;
            var menu_button_icon = new Gtk.Image.from_icon_name("view-more-symbolic", Gtk.IconSize.MENU);
            menu_button.add(menu_button_icon);
            var action_group = new SimpleActionGroup();
            var mode_section = new GLib.Menu();
            string [] modes = { "Preview", "Waterfall", "Body Text" };
            var mode_action = new SimpleAction.stateful("mode", VariantType.STRING, "Preview");
            mode_action.activate.connect((a, s) => {
                mode = FontPreviewMode.parse((string) s);
            });
            action_group.add_action(mode_action);
            mode_action.set_state("Preview");
            int i = 0;
            foreach (var mode in modes) {
                i++;
                GLib.MenuItem item = new MenuItem(FontPreviewMode.parse(mode).to_translatable_string(), "preview.mode::%s".printf(mode));
                item.set_attribute("accel", "s", "<Ctrl>%i".printf(i));
                mode_section.append_item(item);
            }
            insert_action_group("preview", action_group);
            menu_button.set_menu_model((GLib.MenuModel) mode_section);
            menu_button.set_tooltip_text(_("Select preview type"));
            return;
        }

    }

}
