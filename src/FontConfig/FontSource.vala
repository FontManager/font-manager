/* FontSource.vala
 *
 * Copyright © ? Jerry Casiano
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

namespace FontConfig {

    public class FontSource : Object {

        public signal void changed (File file, File? new_file, FileMonitorEvent event_type);

        public new string name {
            get {
                try {
                    return _name;
                } catch (Error e) {
                    return path;
                }
            }
        }

        public new string condition {
            get {
                return _condition;
            }
        }

        public new bool active {
            get {
                if (filetype == FileType.REGULAR || filetype == FileType.SYMBOLIC_LINK) {
                    return false;
                } else if (filetype == FileType.DIRECTORY || filetype == FileType.MOUNTABLE) {
                    return (path in FontManager.Main.instance.fontconfig.dirs);
                } else {
                    return false;
                }
            }
            set {
                var main = FontManager.Main.instance;
                if (value)
                    main.fontconfig.dirs.add(path);
                else
                    main.fontconfig.dirs.remove(path);
                main.fontconfig.dirs.save();
            }
        }

        public string uri {
            get {
                return _uri;
            }
        }

        public string path {
            get {
                return _path;
            }
        }

        public FileType filetype {
            get {
                return file.query_file_type(FileQueryInfoFlags.NONE);
            }
        }

        private File? file = null;
        private FileMonitor? monitor = null;

        internal string? _name = null;
        internal string? _uri = null;
        internal string? _path = null;
        internal string? _condition = null;

        public FontSource (File file) {
            this.file = file;
            _uri = file.get_uri();
            _path = file.get_path();
            var pattern = "\"%" + "%s".printf(file.get_path()) + "%\"";
            _condition = "filepath LIKE %s".printf(pattern);
            FileInfo info = file.query_info(FileAttribute.STANDARD_DISPLAY_NAME, FileQueryInfoFlags.NONE);
            _name = Markup.escape_text(info.get_display_name());
        }

    }

}
