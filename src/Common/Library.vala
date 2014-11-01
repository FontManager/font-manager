/* Library.vala
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

    namespace Library {

        public static ProgressCallback? progress = null;
        internal static ArchiveManager? archive_manager = null;
        internal static Gee.ArrayList <string>? supported_archives = null;

        public struct InstallData {
            public File file;
            public FontConfig.Font font;
            public FontInfo fontinfo;

            public InstallData (File file, string? rmdir = null) {
                this.file = file;
                font = FontConfig.get_font_from_file(file.get_path());
                fontinfo = new FontInfo(file.get_path());
            }
        }

        [Compact]
        public class Install {

            public static Gee.ArrayList <File>? installed = null;
            public static Gee.HashMap <string, string>? install_failed = null;

            internal static void init () {
                if (archive_manager != null)
                    return;
                archive_manager = new ArchiveManager();
                supported_archives = archive_manager.get_supported_types();
                return;
            }

            public static void from_file_array (File? [] files) {
                init();
                var _files = new Gee.ArrayList <File> ();
                foreach (var file in files) {
                    if (file == null)
                        break;
                    _files.add(file);
                }
                process_files(_files);
            }

            public static void from_path_array (string? [] paths) {
                init();
                var files = new Gee.ArrayList <File> ();
                foreach (var path in paths) {
                    if (path == null)
                        break;
                    files.add(File.new_for_path(path));
                }
                process_files(files);
            }

            public static void from_uri_array (string? [] uris) {
                init();
                var files = new Gee.ArrayList <File> ();
                foreach (var uri in uris) {
                    if (uri == null)
                        break;
                    files.add(File.new_for_uri(uri));
                }
                process_files(files);
            }

            internal static void try_copy (File original, File copy) {
                try {
                    original.copy(copy, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
                } catch (Error e) {
                    string path = original.get_path();
                    if (install_failed == null)
                        install_failed = new Gee.HashMap <string, string> ();
                    install_failed[path] = e.message;
                    warning("%s : %s", e.message, path);
                }
                return;
            }

            internal static void install_font (InstallData data) {
                if (data.font == null || data.fontinfo == null) {
                    if (install_failed == null)
                        install_failed = new Gee.HashMap <string, string> ();
                    install_failed[data.file.get_path()] = "Failed to create FontInfo";
                    warning("Failed to create FontInfo :: %s", data.file.get_path());
                    return;
                }
                string dest = Path.build_filename(get_user_font_dir(),
                                                    data.fontinfo.vendor,
                                                    data.fontinfo.filetype,
                                                    data.font.family);
                DirUtils.create_with_parents(dest, 0755);
                string filename = data.font.to_filename();
                string filepath = Path.build_filename(dest, "%s.%s".printf(filename, get_file_extension(data.file.get_path())));
                var file = File.new_for_path(filepath);
                try_copy(data.file, file);
                /* XXX */
                if (data.fontinfo.filetype == "Type 1") {
                    foreach (var ext in FONT_METRICS) {
                        string par = data.file.get_parent().get_path();
                        try {
                            FileInfo inf = data.file.query_info(FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
                            string name = inf.get_name().split_set(".")[0] + ext;
                            string poss = Path.build_filename(par, name);
                            File f = File.new_for_path(poss);
                            if (f.query_exists()) {
                                string path = Path.build_filename(dest, filename + ext);
                                File _f = File.new_for_path(path);
                                try_copy(f, _f);
                            }
                        } catch (Error e) {
                            error("Error querying file information : %s", e.message);
                        }
                    }
                }
                if (installed == null)
                    installed = new Gee.ArrayList <File> ();
                installed.add(data.file);
                return;
            }

            internal static void process_file (File file) {
                string filepath = file.get_path();
                foreach (var ext in FONT_METRICS)
                    if (filepath.down().has_suffix(ext))
                        return;
                install_font(InstallData(file));
                return;
            }

            internal static void process_directory (File dir) {
                try {
                    FileInfo fileinfo;
                    var attrs = "%s,%s,%s".printf(FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_CONTENT_TYPE, FileAttribute.STANDARD_TYPE);
                    var enumerator = dir.enumerate_children(attrs, FileQueryInfoFlags.NONE);
                    int processed = 0;
                    int total = 0;
                    while ((fileinfo = enumerator.next_file ()) != null)
                        total++;
                    enumerator = dir.enumerate_children(attrs, FileQueryInfoFlags.NONE);
                    while ((fileinfo = enumerator.next_file ()) != null) {
                        string content_type = fileinfo.get_content_type();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY) {
                            process_directory(dir.get_child(fileinfo.get_name()));
                        } else {
                            if (content_type.contains("font")) {
                                process_file(dir.get_child(fileinfo.get_name()));
                            } else if (content_type in supported_archives) {
                                if (content_type in ARCHIVE_IGNORE_LIST)
                                    continue;
                                process_archive(dir.get_child(fileinfo.get_name()));
                            } else if (content_type == "application/octet-stream") {
                                bool metrics_file = false;
                                foreach (var ext in FONT_METRICS) {
                                    if (fileinfo.get_name().has_suffix(ext)) {
                                        metrics_file = true;
                                        break;
                                    }
                                }
                                if (metrics_file)
                                    continue;
                                warning("Ignoring unsupported file : %s", dir.get_child(fileinfo.get_name()).get_path());
                            }
                        }
                        processed++;
                        if (progress != null)
                            progress(null, processed, total);
                    }
                } catch (Error e) {
                    warning("%s :: %s", e.message, dir.get_path());
                }
                return;
            }

            internal static void process_archive (File file) {
                string? _tmpdir = null;
                try {
                    _tmpdir = DirUtils.make_tmp(TMPL);
                } catch (FileError e) {
                    error("Error creating temporary working directory : %S", e.message);
                }
                if (_tmpdir == null) {
                    if (install_failed == null)
                        install_failed = new Gee.HashMap <string, string> ();
                    install_failed[file.get_path()] = "Failed to create temporary directory";
                    return;
                }
                var tmpdir = File.new_for_path(_tmpdir);
                if (archive_manager.extract(file.get_uri(), tmpdir.get_uri(), false))
                    process_directory(tmpdir);
                else {
                    if (install_failed == null)
                        install_failed = new Gee.HashMap <string, string> ();
                    install_failed[file.get_path()] = "Failed to extract archive";
                }
                remove_directory(tmpdir);
                return;
            }

            internal static void process_files (Gee.ArrayList <File> filelist) {
                int total = filelist.size;
                int processed = 0;
                foreach (var file in filelist) {
                    var attrs = "%s,%s".printf(FileAttribute.STANDARD_CONTENT_TYPE, FileAttribute.STANDARD_TYPE);
                    try {
                        var fileinfo = file.query_info(attrs, FileQueryInfoFlags.NONE, null);
                        string content_type = fileinfo.get_content_type();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY) {
                            process_directory(file);
                        } else if (content_type.contains("font")) {
                            process_file(file);
                        } else if (content_type in supported_archives) {
                            process_archive(file);
                        }
                    } catch (Error e) {
                        error("Error querying file information : %s", e.message);
                    }
                    processed++;
                    if (progress != null)
                        progress(null, processed, total);
                }
                return;
            }
        }

        [Compact]
        public class Remove {

            public static Gee.ArrayList <File>? removed = null;
            public static Gee.HashMap <string, string>? remove_failed = null;

            public static void from_file_array (File? [] files) {
                int total = files.length;
                int processed = 0;
                foreach (var file in files) {
                    try {
                        File parent = file.get_parent();
                        file.delete();
                        remove_directory_tree_if_empty(parent);
                        processed++;
                        if (progress != null)
                            progress(null, processed, total);
                    } catch (Error e) {
                        if (remove_failed == null)
                            remove_failed = new Gee.HashMap <string, string> ();
                        remove_failed[file.get_path()] = e.message;
                        warning("%s : %s", e.message, file.get_path());
                    }
                }
            }

        }

    }

}
