/* Library.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    namespace Library {

        public string? conflicts (Font font) {
            try {
                Database db = get_database(DatabaseType.FONT);
                db.execute_query("SELECT DISTINCT filepath FROM Fonts WHERE description = \"%s\"".printf(font.description));
                if (db.stmt.step() == Sqlite.ROW)
                    return db.stmt.column_text(0);
            } catch (Error e) {
                warning(e.message);
            }
            return null;
        }

        public bool is_installed (FontInfo info) {
            GLib.List <string> filelist = list_available_font_files();
            if (filelist.find_custom(info.filepath, strcmp) != null)
                return true;
            try {
                Database db = get_database(DatabaseType.METADATA);
                db.execute_query("SELECT DISTINCT filepath FROM Metadata WHERE checksum = \"%s\"".printf(info.checksum));
                foreach (unowned Sqlite.Statement row in db)
                    if (filelist.find_custom(row.column_text(0), strcmp) != null)
                        return true;
            } catch (Error e) {
                warning(e.message);

            }
            return false;
        }

        public async void remove (StringHashset selections) {
            SourceFunc callback = remove.callback;
            ThreadFunc <Object?> _remove = () => {
                foreach (var path in selections) {
                    try {
                        File file = File.new_for_path(path);
                        if (!file.query_exists())
                            continue;
                        File parent = file.get_parent();
                        FileInfo info = file.query_info(FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
                        if (file.delete()) {
                            if (info.get_content_type().contains("type1"))
                                purge_type1_files(file, parent);
                        } else {
                            warning("Failed to remove %s", path);
                        }
                        remove_directory_tree_if_empty(parent);
                    } catch (Error e) {
                        warning(e.message);
                    }
                }
                purge_entries(selections);
                Idle.add((owned) callback);
                return null;
            };
            new Thread <Object?> ("remove", (owned) _remove);
            yield;
            return;
        }


        public class Installer : Object {

            public signal void progress (string message, int processed, int total);

            static File? tmp_file = null;

            public void process_sync (StringHashset filelist) {
                var sorter = new Sorter();
                sorter.sort(filelist);
                process_files(sorter.fonts);
                process_archives(sorter.archives);
                if (tmp_file != null)
                    remove_directory(tmp_file);
                tmp_file = null;
                return;
            }

            public async void process (StringHashset filelist) {
                SourceFunc callback = process.callback;
                ThreadFunc <Object?> install = () => {
                    var sorter = new Sorter();
                    sorter.sort(filelist);
                    process_files(sorter.fonts);
                    process_archives(sorter.archives);
                    if (tmp_file != null)
                        remove_directory(tmp_file);
                    tmp_file = null;
                    Idle.add((owned) callback);
                    return null;
                };
                new Thread <Object?> ("Install -> process", (owned) install);
                yield;
                return;
            }

            public static void try_copy (File original, File copy) {
                try {
                    FileCopyFlags flags = FileCopyFlags.OVERWRITE |
                                          FileCopyFlags.ALL_METADATA |
                                          FileCopyFlags.TARGET_DEFAULT_PERMS;
                    original.copy(copy, flags);
                } catch (Error e) {
                    critical(e.message);
                }
                return;
            }

            public static void copy_font_metrics (File file, FontInfo info, string destdir) {
                string basename = file.get_basename().split_set(".")[0];
                foreach (var _ext in TYPE1_METRICS) {
                    string dir = file.get_parent().get_path();
                    string child = "%s%s".printf(basename, _ext);
                    File metrics = File.new_for_path(Path.build_filename(dir, child));
                    if (metrics.query_exists()) {
                        string _name = "%s %s%s".printf(info.family, info.style, _ext).replace(" ", "_");
                        string _path = Path.build_filename(destdir, _name);
                        File _target = File.new_for_path(_path);
                        try_copy(file, _target);
                    }
                }
                return;
            }

            void process_files (StringHashset filelist) {
                var font = new FontInfo();
                string install_dir = get_user_font_directory();
                foreach (var path in filelist) {
                    if (path.contains("XtraStuf.mac") || path.contains("__MACOSX"))
                        return;
                    File file = File.new_for_path(path);
                    font.source_object = get_metadata(path, 0);
                    if (font.source_object.has_member("err")) {
                        string filepath = font.source_object.get_string_member("filepath");
                        string message = font.source_object.get_string_member("err_msg");
                        int code = (int) font.source_object.get_int_member("err_code");
                        critical("%i :: %s :: %s", code, message, filepath);
                        continue;
                    }

                    string dest = Path.build_filename(install_dir, font.vendor, font.filetype, font.family);
                    assert(DirUtils.create_with_parents(dest, 0755) == 0);
                    string ext = get_file_extension(path).down();
                    string filename = FontManager.to_filename("%s %s.%s".printf(font.family, font.style, ext));
                    string filepath = Path.build_filename(dest, filename);
                    File target = File.new_for_path(filepath);
                    try_copy(file, target);

                    try {
                        FileInfo info = file.query_info(FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
                        if (info.get_content_type().contains("type1"))
                            copy_font_metrics(file, font, dest);
                    } catch (Error e) {
                        warning(e.message);
                    }

                }
                return;
            }

            void process_archives (StringHashset filelist) {

                if (filelist.size == 0)
                    return;

                if (tmp_file == null) {
                    try {
                        tmp_file = File.new_for_path(DirUtils.make_tmp(TMP_TMPL));
                        assert(tmp_file.query_exists());
                    } catch (Error e) {
                        critical(e.message);
                        return;
                    }
                }

                var file_roller = new ArchiveManager();
                return_if_fail(file_roller.available);

                foreach (var path in filelist) {

                    var file = File.new_for_path(path);
                    string uri = file.get_uri();

                    string tmp_path = Path.build_filename(tmp_file.get_path(), "archive_XXXXXX");
                    File tmp = File.new_for_path(DirUtils.mkdtemp(tmp_path));
                    assert(tmp.query_exists());
                    string tmp_uri = tmp.get_uri();

                    if (!file_roller.extract(uri, tmp_uri, false)) {
                        critical("Failed to extract archive : %s", path);
                        continue;
                    }

                    if (uri.contains(tmp_file.get_uri())) {
                        try {
                            file.delete();
                        } catch (Error e) {
                            critical(e.message);
                        }
                    }

                    var sorter = new Sorter();
                    var list = new StringHashset();
                    list.add(tmp.get_path());
                    sorter.sort(list);
                    process_files(sorter.fonts);
                    process_archives(sorter.archives);

                }

                return;
            }

        }

        internal void purge_type1_files (File file, File parent) {
            try {
                string name = file.get_basename().split_set(".")[0];
                foreach (string ext in TYPE1_METRICS) {
                    string dir = parent.get_path();
                    string child = name + ext;
                    File metrics = File.new_for_path(Path.build_filename(dir, child));
                    if (metrics.query_exists())
                        metrics.delete();
                }
            } catch (Error e) {
                warning(e.message);
            }
            return;
        }

        internal void purge_entries (StringHashset selections) {
            DatabaseType [] types = { DatabaseType.FONT, DatabaseType.METADATA, DatabaseType.ORTHOGRAPHY };
            try {
                Database? db = get_database(DatabaseType.BASE);
                var reject = new Reject();
                reject.load();
                foreach (var path in selections) {
                    db.execute_query("SELECT family FROM Fonts WHERE filepath = \"%s\"".printf(path));
                    foreach (unowned Sqlite.Statement row in db)
                        reject.remove(row.column_text(0));
                    foreach (var type in types) {
                        var name = Database.get_type_name(type);
                        db.execute_query("DELETE FROM %s WHERE filepath = \"%s\"".printf(name, path));
                        db.stmt.step();
                    }
                }
                reject.save();
                db = null;
                foreach (var type in types) {
                    db = get_database(type);
                    db.execute_query("VACUUM");
                    db.stmt.step();
                }
            } catch (DatabaseError e) {
                warning(e.message);
            }
            return;
        }

        internal bool is_metrics_file (string name) {
            foreach (var ext in TYPE1_METRICS)
                if (name.down().has_suffix(ext))
                    return true;
            return false;
        }

        internal class Sorter : Object {

            public StringHashset? fonts { get; private set; default = null; }
            public StringHashset? archives { get; private set; default = null; }

            StringHashset? supported_archives = null;

            public uint total {
                get {
                    return fonts.size + archives.size;
                }
            }

            construct {
                supported_archives = new StringHashset();
                var file_roller = new ArchiveManager();
                if (file_roller.available)
                    supported_archives = file_roller.get_supported_types();
            }

            public void sort (StringHashset filelist) {
                fonts = new StringHashset ();
                archives  = new StringHashset ();
                process_files(filelist);
                return;
            }

            void process_directory (File dir) {
                try {
                    FileInfo fileinfo;
                    var attrs = "%s,%s,%s".printf(FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_CONTENT_TYPE, FileAttribute.STANDARD_TYPE);
                    var enumerator = dir.enumerate_children(attrs, FileQueryInfoFlags.NONE);
                    while ((fileinfo = enumerator.next_file ()) != null) {
                        string content_type = fileinfo.get_content_type();
                        string name = fileinfo.get_name();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY) {
                            process_directory(dir.get_child(name));
                        } else {
                            string path = dir.get_child(name).get_path();
                            if (content_type.contains("font") && !is_metrics_file(name))
                                fonts.add(path);
                            else if (content_type in supported_archives)
                                archives.add(path);
                        }
                    }
                } catch (Error e) {
                    warning("%s :: %s", e.message, dir.get_path());
                }
                return;
            }

            void process_files (StringHashset filelist) {
                foreach (var path in filelist) {
                    var file = File.new_for_path(path);
                    var attrs = "%s,%s,%s".printf(FileAttribute.STANDARD_CONTENT_TYPE, FileAttribute.STANDARD_TYPE, FileAttribute.STANDARD_NAME);
                    try {
                        var fileinfo = file.query_info(attrs, FileQueryInfoFlags.NONE, null);
                        string name = fileinfo.get_name();
                        string content_type = fileinfo.get_content_type();
                        string filepath = file.get_path();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY)
                            process_directory(file);
                        else if (content_type.contains("font") && !is_metrics_file(name))
                            fonts.add(filepath);
                        else if (content_type in supported_archives)
                            archives.add(filepath);
                    } catch (Error e) {
                        critical("Error querying file information : %s", e.message);
                    }
                }
                return;
            }

        }

    }

}
