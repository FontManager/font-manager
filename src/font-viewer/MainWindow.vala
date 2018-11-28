/* MainWindow.vala
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

    namespace FontViewer {

        internal const string w1 = _("Font Viewer");
        internal const string w2 = _("Preview font files before installing them.");
        internal const string w3 = _("To preview a font simply drag it onto this area.");
        internal const string welcome_tmpl = "<span size=\"xx-large\" weight=\"bold\">%s</span>\n<span size=\"large\">\n\n%s\n</span>\n\n\n<span size=\"x-large\">%s</span>";

        internal const int DEFAULT_WIDTH = 600;
        internal const int DEFAULT_HEIGHT = 400;

        struct FontTypeEntry {

            public string name;
            public string tooltip;
            public string url;

            public FontTypeEntry (string name, string tooltip, string url) {
                this.name = name;
                this.tooltip = tooltip;
                this.url = url;
            }

        }

        class TypeInfoCache : Object {

            FontTypeEntry [] types = {
                FontTypeEntry("null", "", ""),
                FontTypeEntry("opentype", _("OpenType Font"), "http://wikipedia.org/wiki/OpenType"),
                FontTypeEntry("truetype", _("TrueType Font"), "http://wikipedia.org/wiki/TrueType"),
                FontTypeEntry("type1", _("PostScript Type 1 Font"), "http://wikipedia.org/wiki/Type_1_Font#Type_1"),
            };

            public new FontTypeEntry get (string key) {
                var _key = key.down().replace(" ", "");
                foreach (var entry in types)
                    if (entry.name == _key)
                        return entry;
                return types[0];
            }

            public void update (Gtk.Image icon, string key) {
                var entry = this[key];
                icon.set_from_icon_name(entry.name, Gtk.IconSize.LARGE_TOOLBAR);
                icon.set_tooltip_text(entry.tooltip);
            }

        }

        public class TitleBar : Gtk.HeaderBar {

            Gtk.Image type_icon;
            TypeInfoCache type_info_cache;

            construct {
                show_close_button = true;
                spacing = 6;
                type_info_cache = new TypeInfoCache();
                type_icon = new Gtk.Image();
                reset();
                pack_start(type_icon);
            }

            public override void show () {
                type_icon.show();
                base.show();
                return;
            }

            void reset () {
                set_title(null);
                set_subtitle(null);
                type_info_cache.update(type_icon, "null");
                return;
            }

            public virtual void update (string? family, string? style, string? filetype) {
                this.reset();
                if (family == null && style == null) {
                    set_title(_("No file selected"));
                    set_subtitle(_("Or unsupported filetype."));
                    return;
                }
                set_title(family);
                set_subtitle(style);
                const string tt_tmpl = "<big><b>%s</b> </big><b>%s</b>";
                set_tooltip_markup(tt_tmpl.printf(Markup.escape_text(family), style));
                type_info_cache.update(type_icon, filetype);
                return;
            }

        }

        public class MainWindow : Gtk.ApplicationWindow {

            public signal void mode_changed (FontPreviewMode mode);

            public FontPreviewMode mode { get; set; }
            public FontPreviewPane preview { get; private set; }
            public Settings? settings { get; set; default = null; }

            Gtk.Stack stack;
            Gtk.EventBox blend;
            Gtk.Button install_button;
            PlaceHolder welcome;
            TitleBar titlebar;
            StringHashset installed;

            /* Type hint used to prevent notification on every selection.
             * Happens in gnome-shell and I assume other environments if
             * one of the file manager extensions are in use.
             */
            public MainWindow () {
                Object(title: _("Font Viewer"), icon_name: "font-x-generic",
                       type_hint: Gdk.WindowTypeHint.UTILITY,
                       settings: get_gsettings(BUS_ID));
                installed = new StringHashset();
                preview = new FontPreviewPane();
                install_button = new Gtk.Button();
                install_button.margin = MINIMUM_MARGIN_SIZE;
                install_button.set_label(_("Install Font"));
                install_button.opacity = 0.725;
                install_button.clicked.connect(() => {
                    var filelist = new StringHashset();
                    filelist.add(preview.selected_font.filepath);
                    var installer = new Library.Installer();
                    installer.process.begin(filelist, (obj, res) => {
                        installer.process.end(res);
                        installed.add(preview.metadata.info.checksum);
                        update_install_button_state();
                    });
                });
                preview.notebook.set_action_widget(install_button, Gtk.PackType.END);
                welcome = new PlaceHolder(welcome_tmpl.printf(w1, w2, w3), "font-x-generic-symbolic");
                titlebar = new TitleBar();
                set_titlebar(titlebar);
                stack = new Gtk.Stack();
                blend = new Gtk.EventBox();
                blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                blend.expand = true;
                blend.add(welcome);
                stack.add_named(preview, "Preview");
                stack.add_named(blend, "Placeholder");
                stack.set_visible_child_name("Placeholder");
                add(stack);
                set_default_size(600, 400);
                update_install_button_state();
                Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
                Gtk.drag_dest_set(stack, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
                connect_signals();
            }

            void connect_signals () {
                realize.connect(() => { on_realize(); });
                delete_event.connect((w, e) => {
                    settings.apply();
                    ((Application) GLib.Application.get_default()).quit();
                    return true;
                });
                bind_property("mode", preview, "mode", BindingFlags.BIDIRECTIONAL);
                preview.preview_mode_changed.connect((m) => { mode_changed(m); });
                stack.drag_data_received.connect(_drag_data_recieved);
                preview.changed.connect(() => { this.update(); });

                insert_action_group("default", new SimpleActionGroup());

                var action = new SimpleAction("zoom_in", null);
                action.activate.connect((a, v) => { preview.preview_size += 0.5; });
                string? [] accels = { "<Ctrl>plus", "<Ctrl>equal", null };
                add_keyboard_shortcut(this, action, "zoom_in", accels);

                action = new SimpleAction("zoom_out", null);
                action.activate.connect((a, v) => { preview.preview_size -= 0.5; });
                accels = { "<Ctrl>minus", null };
                add_keyboard_shortcut(this, action, "zoom_out", accels);

                action = new SimpleAction("zoom_default", null);
                action.activate.connect((a, v) => { preview.preview_size = DEFAULT_PREVIEW_SIZE; });
                accels = { "<Ctrl>0", null };
                add_keyboard_shortcut(this, action, "zoom_default", accels);

            }

            public override void show () {
                titlebar.show();
                install_button.show();
                preview.show();
                welcome.show();
                blend.show();
                stack.show();
                base.show();
                return;
            }

            public bool ready () {
                return this.visible;
            }

            public void show_uri (string uri) {
                preview.show_uri(uri);
                update();
                return;
            }

            public void open (string arg)  {
                preview.show_uri(arg);
                return;
            }

            public void set_preview_text (string preview_text) {
                preview.set_preview_text(preview_text);
                return;
            }

            public void update () {
                bool have_valid_source = is_valid_source(preview.selected_font);
                if (have_valid_source) {
                    preview.metadata.update();
                    titlebar.update(preview.selected_font.family,
                                    preview.selected_font.style,
                                    preview.metadata.info.filetype);
                } else {
                    titlebar.update(null, null, "");
                }
                stack.set_visible_child_name(have_valid_source ? "Preview" : "Placeholder");
                update_install_button_state();
                queue_draw();
                return;
            }

            void update_install_button_state () {
                bool have_valid_source = is_valid_source(preview.selected_font);
                install_button.set_visible(have_valid_source);
                if (!have_valid_source)
                    return;
                clear_application_fonts();
                return_if_fail(preview.metadata.info != null);
                bool _installed = Library.is_installed(preview.metadata.info);
                add_application_font(preview.metadata.info.filepath);
                if (!_installed && installed.contains(preview.metadata.info.checksum))
                    _installed = true;
                /* XXX : Check for conflicts */
                if (_installed) {
                    install_button.set_label(_("Installed"));
                    install_button.sensitive = false;
                    install_button.relief = Gtk.ReliefStyle.NONE;
                } else {
                    install_button.set_label(_("Install Font"));
                    install_button.sensitive = true;
                    install_button.relief = Gtk.ReliefStyle.NORMAL;
                }
                return;
            }

            public void bind_settings () {
                if (settings == null)
                    return;
                configure_event.connect((w, e) => {
                    /* Avoid tiny windows on Wayland */
                    if (e.width < DEFAULT_WIDTH || e.height < DEFAULT_HEIGHT)
                        return false;
                    /* Size provided by event is not usable on Gtk+ > 3.18 */
                    int actual_window_width, actual_window_height;
                    get_size(out actual_window_width, out actual_window_height);
                    settings.set("window-size", "(ii)", actual_window_width, actual_window_height);
                    settings.set("window-position", "(ii)", e.x, e.y);
                    return false;
                });
                mode_changed.connect((m) => {
                    settings.set_enum("mode", ((int) m));
                });
                preview.preview_text_changed.connect((p) => { settings.set_string("preview-text", p); });
                settings.bind("preview-font-size", preview, "preview-size", SettingsBindFlags.DEFAULT);
                settings.bind("charmap-font-size", preview.charmap, "preview-size", SettingsBindFlags.DEFAULT);
                settings.delay();
                return;
            }

            public void on_realize () {
                if (settings == null)
                    return;
                int x, y, w, h;
                settings.get("window-size", "(ii)", out w, out h);
                settings.get("window-position", "(ii)", out x, out y);
                set_default_size(w, h);
                move(x, y);
                preview.preview_size = settings.get_double("preview-font-size");
                var preview_text = settings.get_string("preview-text");
                if (preview_text != "DEFAULT")
                    preview.set_preview_text(preview_text);
                preview.mode = ((FontPreviewMode) settings.get_enum("mode"));
                Idle.add(() => { bind_settings(); return false; });
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

            void _drag_data_recieved (Gtk.Widget widget,
                                      Gdk.DragContext context,
                                      int x,
                                      int y,
                                      Gtk.SelectionData selection_data,
                                      uint info,
                                      uint time) {
                drag_data_received(context, x, y, selection_data, info, time);
            }

        }

    }

}
