/* MainWindow.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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

    namespace FontViewer {

        internal const string w1 = _("Font Viewer");
        internal const string w2 = _("Preview font files before installing them.");
        internal const string w3 = _("To preview a font simply drag it onto this area.");
        internal const string welcome_tmpl = "<span size=\"xx-large\" weight=\"bold\">%s</span>\n<span size=\"large\">\n\n%s\n</span>\n\n\n<span size=\"x-large\">%s</span>";

        public class MainWindow : Gtk.ApplicationWindow {

            public signal void mode_changed (FontPreviewMode mode);

            public FontPreviewMode mode { get; set; }
            public FontPreviewPane preview { get; private set; }

            Gtk.Box box;
            Gtk.Overlay overlay;
            WelcomeLabel welcome;
            Gtk.Button install_button;
            Gee.ArrayList <string> installed;
            Metadata.Title titlebar;

            public MainWindow () {
                /* Note: Type hint used to prevent notification on every selection */
                Object(title: _("Font Viewer"), icon_name: About.ICON, type_hint: Gdk.WindowTypeHint.UTILITY);
                Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
                installed = new Gee.ArrayList <string> ();
                preview = new FontPreviewPane();
                install_button = new Gtk.Button();
                install_button.set_label(_("Install Font"));
                install_button.margin = 2;
                install_button.opacity = 0.725;
                install_button.clicked.connect(() => {
                    Library.Install.from_font_data(preview.font_data);
                    installed.add(preview.font_data.fontinfo.checksum);
                    update_install_button_state();
                });
                preview.notebook.set_action_widget(install_button, Gtk.PackType.END);
                welcome = new WelcomeLabel(welcome_tmpl.printf(w1, w2, w3));
                box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                titlebar = new Metadata.Title();
                add_separator(box, Gtk.Orientation.HORIZONTAL);
                box.pack_end(preview, true, true, 0);
                box.pack_start(titlebar, false, true, 0);
                overlay = new Gtk.Overlay();
                /* XXX : Bug? */
                var force_label_resizing_in_an_overlay = new Gtk.ScrolledWindow(null, null);
                force_label_resizing_in_an_overlay.add(box);
                force_label_resizing_in_an_overlay.show();
                overlay.add(force_label_resizing_in_an_overlay);
                overlay.add_overlay(welcome);
                add(overlay);
                set_default_size(600, 400);
                update_install_button_state();
                connect_signals();
            }

            void connect_signals () {
                delete_event.connect((w, e) => {
                    ((Application) GLib.Application.get_default()).quit();
                    return true;
                });
                bind_property("mode", preview, "mode", BindingFlags.BIDIRECTIONAL);
                preview.preview_mode_changed.connect((m) => { mode_changed(m); });
                preview.updated.connect(() => { this.update(); });
            }

            public override void show () {
                titlebar.show();
                install_button.show();
                preview.show();
                box.show();
                overlay.show();
                base.show();
                return;
            }

            public bool ready () {
                return this.visible;
            }

            public void show_uri (string uri) {
                preview.open(uri);
                return;
            }

            public void open (string arg)  {
                preview.open(arg);
                return;
            }

            public void set_preview_text (string preview_text) {
                preview.set_preview_text(preview_text);
                return;
            }

            public void update () {
                update_install_button_state();
                if (preview.font_data == null)
                    titlebar.update(null, null, "");
                else
                    titlebar.update(preview.font_data.font.family,
                                    preview.font_data.font.style,
                                    preview.font_data.fontinfo.filetype);
                if (preview.font_data != null) {
                    welcome.hide();
                    box.show();
                } else {
                    box.hide();
                    welcome.show();
                }
                return;
            }

            void update_install_button_state () {
                if (preview.font_data == null) {
                    install_button.hide();
                    return;
                } else {
                    install_button.show();
                }
                FontConfig.clear_app_fonts();
                bool _installed = Library.is_installed(preview.font_data);
                if (installed.contains(preview.font_data.fontinfo.checksum))
                    _installed = true;
                if (Library.conflicts(preview.font_data) > 0) {
                    install_button.set_label(_("Newer version already installed"));
                    install_button.sensitive = false;
                    install_button.relief = Gtk.ReliefStyle.NONE;
                    return;
                } else if (_installed) {
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

        }

    }

}
