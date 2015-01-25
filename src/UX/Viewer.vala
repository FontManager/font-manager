/* Viewer.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    [DBus (name = "org.gnome.FontManager.FontViewer")]
    public class Viewer : Gtk.Window {

        [DBus (visible = false)]
        public FontData? fontdata {
            get {
                return _fontdata;
            }
            set {
                _fontdata = value;
                update();
            }
        }

        private FontData? _fontdata = null;
        private Gtk.Box box;
        private Metadata.Pane metadata;
        private ActivePreview preview;
        private weak Gtk.Application _parent_;
        private Gtk.Button button;
        private Gee.ArrayList <string> _installed;

        public Viewer () {
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            _parent_ = ((Application) GLib.Application.get_default());
            title = _("Font Viewer");
            set_icon_name(About.ICON);
            _installed = new Gee.ArrayList <string> ();
            metadata = new Metadata.Pane();
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add_separator(box, Gtk.Orientation.HORIZONTAL);
            box.pack_end(metadata, true, true, 0);
            preview = new ActivePreview(new StandardTextTagTable());
            preview.margin_top = 4;
            metadata.notebook.insert_page(preview, new Gtk.Label(_("Preview")), 0);
            button = new Gtk.Button();
            button.set_label(_("Install Font"));
            button.margin = 2;
            button.opacity = 0.725;
            button.clicked.connect(() => {
                if (Library.Install.install_font(fontdata))
                    _installed.add(fontdata.fontinfo.checksum);
                update_button_state();
            });
            update_button_state();
            metadata.notebook.set_action_widget(button, Gtk.PackType.END);
            add(box);
            set_default_size(600, 400);
        }

        public void show_uri (string uri)  {
            var file = File.new_for_uri(uri);
            if (file.query_exists())
                fontdata = FontData(file);
            return;
        }

        public bool ready () {
            return this.visible;
        }

        public override void show () {
            button.show();
            metadata.show();
            preview.show();
            box.show();
            /* Prevent Application from closing. */
            _parent_.add_window(this);
            base.show();
            return;
        }

        public override bool delete_event (Gdk.EventAny event) {
            if (_parent_.get_windows().length() == 1)
                quit();
            return hide_on_delete();
        }

        public void quit () {
            hide();
            _parent_.remove_window(this);
            return;
        }

        public void update () {
            update_button_state();
            if (fontdata != null) {
                FontConfig.add_app_font(fontdata.file.get_path());
                metadata.update(fontdata);
                preview.font_desc = Pango.FontDescription.from_string(fontdata.font.description);
            } else {
                metadata.update(null);
                preview.font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            }
            return;
        }

        public override void drag_data_received (Gdk.DragContext context,
                                                    int x,
                                                    int y,
                                                    Gtk.SelectionData selection_data,
                                                    uint info,
                                                    uint time)
        {
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

        private void update_button_state () {
            if (fontdata == null) {
                button.hide();
                return;
            } else {
                button.show();
            }
            FontConfig.clear_app_fonts();
            bool installed = Library.is_installed(fontdata);
            if (_installed.contains(fontdata.fontinfo.checksum))
                installed = true;
            if (Library.conflicts(fontdata) > 0) {
                button.set_label(_("Newer version already installed"));
                button.sensitive = false;
                button.relief = Gtk.ReliefStyle.NONE;
                return;
            } else if (installed) {
                button.set_label(_("Installed"));
                button.sensitive = false;
                button.relief = Gtk.ReliefStyle.NONE;
            } else {
                button.set_label(_("Install Font"));
                button.sensitive = true;
                button.relief = Gtk.ReliefStyle.NORMAL;
            }
            return;
        }

    }


}
