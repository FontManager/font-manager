/* Source.vala
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


namespace FontConfig {

    public class Source : Object {

        public signal void activated (bool active);

        public new string? name {
            get {
                return _name != null ? _name : path;
            }
        }

        public string icon_name {
            get {
                if (available)
                    return "folder-symbolic";
                else
                    return "action-unavailable-symbolic";
            }
        }

        public new bool active {
            get {
                return _active;
            }
            set {
                _active = value;
                this.activated(_active);
            }
        }

        public string? path {
            get {
                return _path;
            }
        }

        public bool available {
            get {
                return file.query_exists();
            }
        }

        bool _active = false;
        File? file = null;
        string? _name = null;
        string? _path = null;

        public Source (File file) {
            this.file = file;
            this.update();
        }

        public void update () {
             _path = file.get_path();
            try {
                FileInfo info = file.query_info(FileAttribute.STANDARD_DISPLAY_NAME, FileQueryInfoFlags.NONE);
                _name = Markup.escape_text(info.get_display_name());
            } catch (Error e) {
                _name = _("Source Unavailable");
            }
            return;
        }

    }

}
