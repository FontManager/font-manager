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

    public struct FontData {
        public File file;
        public FontConfig.Font font;
        public FontInfo fontinfo;

        public FontData (File file, string? rmdir = null) {
            this.file = file;
            font = FontConfig.get_font_from_file(file.get_path());
            fontinfo = new FontInfo.from_filepath(file.get_path());
        }
    }

    namespace Library {

        public static ProgressCallback? progress = null;
        private static ArchiveManager? archive_manager = null;
        private static Gee.ArrayList <string>? supported_archives = null;

        public static bool is_installed (FontData fontdata) {
            var filelist = FontConfig.list_files();
            if (fontdata.font.filepath in filelist) {
                message("Font already installed : path match");
                return true;
            }
            var _filelist = db_match_checksum(fontdata.fontinfo.checksum);
            foreach (var f in _filelist)
                if (filelist.contains(f)) {
                    message("Font already installed : checksum match");
                    return true;
                }
//            if (_filelist.contains(fontdata.font.filepath))
//                return true;
            return false;
        }

        /*
         * Prevent an older version from being installed.
         *
         * XXX:
         * Todo:
         * Extend to catch crappy fonts... would need notification/resolution
         */
        public static int conflicts (FontData fontdata) {
            var unique = db_match_unique_names(fontdata);
            var filelist = FontConfig.list_files();
            foreach (var f in unique.keys)
                if (filelist.contains(f)) {
                    message("%s conflicts with %s", fontdata.font.filepath, f);
                    return natural_cmp(unique[f], fontdata.fontinfo.version);
                }
            return -1;
        }

        private bool is_metrics_file (string name) {
            foreach (var ext in FONT_METRICS)
                if (name.has_suffix(ext))
                    return true;
            return false;
        }

        private static Gee.ArrayList <string> db_match_checksum (string checksum) {
            var results = new Gee.ArrayList <string> ();
            Database? db;
            try {
                db = get_database();
                db.reset();
                db.table = "Fonts";
                db.select = "filepath";
                db.search = "checksum=\"%s\"".printf(checksum);
                db.execute_query();
                foreach (var row in db)
                    results.add(row.column_text(0));
            } catch (DatabaseError e) {
                error("Database Error : %s", e.message);
            }
            if (db != null)
                db.close();
            return results;
        }

        private static Gee.HashMap <string, string> db_match_unique_names (FontData fontdata) {
            var results = new Gee.HashMap <string, string> ();
            Database? db;
            try {
                db = get_database();
                db.reset();
                db.table = "Fonts";
                db.select = "filepath, version";
                db.search = "psname=\"%s\" OR font_description=\"%s\"".printf(fontdata.fontinfo.psname, fontdata.font.description);
                db.execute_query();
                foreach (var row in db)
                    results[row.column_text(0)] = row.column_text(1);
            } catch (DatabaseError e) {
                error("Database Error : %s", e.message);
            }
            if (db != null)
                db.close();
            return results;
        }

        public class Sorter : Object {

            public Gee.ArrayList <File> files { get; private set; }
            public Gee.ArrayList <File> archives { get; private set; }

            construct {
                files = new Gee.ArrayList <File> ();
                archives  = new Gee.ArrayList <File> ();
                if (archive_manager == null) {
                    archive_manager = new ArchiveManager();
                    supported_archives = archive_manager.get_supported_types();
                }
            }

            public void sort (Gee.ArrayList <File> filelist) {
                files.clear();
                archives.clear();
                process_files(filelist);
                return;
            }

            private void process_directory (File dir) {
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
                        string name = fileinfo.get_name();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY)
                            process_directory(dir.get_child(name));
                        else
                            if (content_type.contains("font") && !is_metrics_file(name))
                                files.add(dir.get_child(name));
                            else if (content_type in supported_archives && !(content_type in ARCHIVE_IGNORE_LIST))
                                archives.add(dir.get_child(name));
                        processed++;
                        if (progress != null)
                            progress(null, processed, total);
                    }
                } catch (Error e) {
                    warning("%s :: %s", e.message, dir.get_path());
                }
                return;
            }

            private void process_files (Gee.ArrayList <File> filelist) {
                int total = filelist.size;
                int processed = 0;
                foreach (var file in filelist) {
                    var attrs = "%s,%s".printf(FileAttribute.STANDARD_CONTENT_TYPE, FileAttribute.STANDARD_TYPE);
                    try {
                        var fileinfo = file.query_info(attrs, FileQueryInfoFlags.NONE, null);
                        string content_type = fileinfo.get_content_type();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY)
                            process_directory(file);
                        else if (content_type.contains("font") && !is_metrics_file(fileinfo.get_name()))
                            files.add(file);
                        else if (content_type in supported_archives)
                            archives.add(file);
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
        public class Install {

            public static Gee.ArrayList <File>? installed = null;
            public static Gee.HashMap <string, string>? install_failed = null;

            static File? tmpdir = null;

            public static void from_file_array (File? [] files) {
                init();
                var _files = new Gee.ArrayList <File> ();
                foreach (var file in files) {
                    if (file == null)
                        break;
                    _files.add(file);
                }
                process_files(_files);
                fini();
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
                fini();
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
                fini();
            }

            private static void init () {
                if (archive_manager == null) {
                    archive_manager = new ArchiveManager();
                    supported_archives = archive_manager.get_supported_types();
                }
                return;
            }

            private static void fini () {
                if (tmpdir == null)
                    return;
                remove_directory(tmpdir);
                tmpdir = null;
                return;
            }

            private static void try_copy (File original, File copy) {
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

            public static bool install_font (FontData data) {
                if (data.font == null || data.fontinfo == null) {
                    if (install_failed == null)
                        install_failed = new Gee.HashMap <string, string> ();
                    install_failed[data.file.get_path()] = "Failed to create FontInfo";
                    warning("Failed to create FontInfo : %s", data.file.get_path());
                    return false;
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
                    string par = data.file.get_parent().get_path();
                    foreach (var ext in FONT_METRICS) {
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
                return true;
            }

            private static File? get_temp_dir () {
                string? _tmpdir = null;
                try {
                    _tmpdir = DirUtils.make_tmp(TMPL);
                } catch (FileError e) {
                    error("Error creating temporary working directory : %s", e.message);
                }
                return _tmpdir != null ? File.new_for_path(_tmpdir) : null;
            }

            private static void process_files (Gee.ArrayList <File> filelist) {
                var sorter = new Sorter();
                sorter.sort(filelist);
                int processed = 0;
                int total = sorter.files.size + sorter.archives.size;
                foreach (var f in sorter.files) {
                    var data = FontData(f);
                    if (!is_installed(data) && (conflicts(data) < 0))
                        install_font(data);
                    processed++;
                    if (progress != null)
                        progress(null, processed, total);
                }
                if (sorter.archives.size == 0)
                    return;
                tmpdir = get_temp_dir();
                var uri = tmpdir.get_uri();
                foreach (var a in sorter.archives) {
                    if (!archive_manager.extract(a.get_uri(), uri, false)) {
                        if (install_failed == null)
                            install_failed = new Gee.HashMap <string, string> ();
                        install_failed[a.get_path()] = "Failed to extract archive";
                    }
                    processed++;
                    if (progress != null)
                        progress(null, processed, total);
                }
                var l = new Gee.ArrayList <File> ();
                l.add(tmpdir);
                process_files(l);
                return;
            }

        }

        [Compact]
        public class Remove {

            public static Gee.ArrayList <File>? removed = null;
            public static Gee.HashMap <string, string>? remove_failed = null;

            public static void from_file_array (File? [] files) {
                Database? db = null;
                try {
                    db = get_database();
                    db.table = "Fonts";
                } catch (DatabaseError e) {
                    warning(e.message);
                }
                int total = files.length;
                int processed = 0;
                foreach (var file in files) {
                    try {
                        File parent = file.get_parent();
                        if (db != null) {
                            try {
                                db.remove("filepath=\"%s\"".printf(file.get_path()));
                            } catch (DatabaseError e) {
                                warning(e.message);
                            }
                        }
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
                if (db != null) {
                    try {
                        db.vacuum();
                        db.close();
                    } catch (DatabaseError e) {
                        warning(e.message);
                    }
                }
            }

        }

    }

}
