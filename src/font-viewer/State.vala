/* State.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    namespace FontViewer {

        public class State : Object {

            internal const int DEFAULT_WIDTH = 600;
            internal const int DEFAULT_HEIGHT = 400;

            public Settings? settings { get; set; default = null; }
            public weak MainWindow? main_window { get; set; default = null; }

            public State (MainWindow main_window, string schema_id) {
                Object(main_window: main_window, settings: get_gsettings(schema_id));
            }

            public void save () {
                if (settings == null)
                    return;
                settings.apply();
                return;
            }

            public void restore () {
                if (settings == null)
                    return;
                int x, y, w, h;
                settings.get("window-size", "(ii)", out w, out h);
                settings.get("window-position", "(ii)", out x, out y);
                main_window.set_default_size(w, h);
                main_window.move(x, y);
                main_window.preview.preview_size = settings.get_double("preview-font-size");
                var preview_text = settings.get_string("preview-text");
                if (preview_text != "DEFAULT")
                    main_window.preview.set_preview_text(preview_text);
                return;
            }

            public void bind () {
                if (settings == null)
                    return;
                main_window.configure_event.connect((w, e) => {
                    /* Avoid tiny windows on Wayland */
                    if (e.width < DEFAULT_WIDTH || e.height < DEFAULT_HEIGHT)
                        return false;
                    /* Size provided by event is not usable on Gtk+ > 3.18 */
                    int actual_window_width, actual_window_height;
                    main_window.get_size(out actual_window_width, out actual_window_height);
                    settings.set("window-size", "(ii)", actual_window_width, actual_window_height);
                    settings.set("window-position", "(ii)", e.x, e.y);
                    return false;
                });
                main_window.mode_changed.connect((m) => {
                    settings.set_enum("mode", ((int) m));
                });
                main_window.preview.preview_text_changed.connect((p) => { settings.set_string("preview-text", p); });
                settings.bind("preview-font-size", main_window.preview, "preview-size", SettingsBindFlags.DEFAULT);
                settings.bind("charmap-font-size", main_window.preview.charmap, "preview-size", SettingsBindFlags.DEFAULT);
                settings.delay();
                return;
            }

            public void post_activate () {
                main_window.preview.mode = ((FontPreviewMode) settings.get_enum("mode"));
                return;
            }

        }

    }

}
