/* Library.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    // XXX : Type 1 are unsupported
    // TODO : Remove code related to Type 1 fonts?
    public const string [] TYPE1_METRICS = {
        ".afm",
        ".pfa",
        ".pfm"
    };

    namespace Library {

        public async void remove (StringSet selections) {
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
                purge_database_entries(selections);
                Idle.add((owned) callback);
                return null;
            };
            new Thread <Object?> ("remove", (owned) _remove);
            yield;
            return;
        }


        public class Installer : Object {

            public signal void progress (string message, uint processed, uint total);

            static File? tmp_file = null;

            public void process_sync (StringSet filelist) {
                var sorter = new Sorter();
                sorter.sort(filelist);
                process_files(sorter.fonts);
                process_archives(sorter.archives);
                if (tmp_file != null)
                    remove_directory(tmp_file);
                tmp_file = null;
                return;
            }

            public async void process (StringSet filelist) {
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

            void process_files (StringSet filelist) {
                uint total = filelist.size;
                uint processed = 0;
                File install_dir = File.new_for_path(get_user_font_directory());
                foreach (var path in filelist) {
                    if (path.contains("XtraStuf.mac") || path.contains("__MACOSX"))
                        continue;
                    File file = File.new_for_path(path);
                    try {
                        install_file(file, install_dir);
                    } catch (Error e) {
                        critical("%s : %s", e.message, path);
                    }
                    processed++;
                    try {
                        FileInfo info = file.query_info(FileAttribute.STANDARD_DISPLAY_NAME, FileQueryInfoFlags.NONE);
                        progress(info.get_display_name(), processed, total);
                    } catch (Error e) {
                        warning(e.message);
                    }

                }
                return;
            }

            void process_archives (StringSet filelist) {

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
                    var list = new StringSet();
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

        void purge_database_entries (StringSet selections) {
            ThreadFunc <void> run_in_thread = () => {
                try {
                    Database db = new Database();
                    string [] tables = { "Metadata", "Orthography", "Panose" };
                    foreach (string table in tables) {
                        foreach (var path in selections) {
                            db.execute_query("DELETE FROM %s WHERE filepath LIKE \"%%s%\"".printf(table, path));
                            db.get_cursor().step();
                            db.end_query();
                        }
                    }
                    db.vacuum();
                    db.close();
                } catch (Error e) {
                    warning(e.message);
                }
            };
            new Thread <void> ("purge_database_entries", (owned) run_in_thread);
            return;
        }

        internal bool is_metrics_file (string name) {
            foreach (var ext in TYPE1_METRICS)
                if (name.down().has_suffix(ext))
                    return true;
            return false;
        }

        internal class Sorter : Object {

            public StringSet? fonts { get; private set; default = null; }
            public StringSet? archives { get; private set; default = null; }

            StringSet? supported_archives = null;

            public uint total {
                get {
                    return fonts.size + archives.size;
                }
            }

            construct {
                supported_archives = new StringSet();
                var file_roller = new ArchiveManager();
                if (file_roller.available)
                    supported_archives = file_roller.get_supported_types();
            }

            public void sort (StringSet filelist) {
                fonts = new StringSet ();
                archives  = new StringSet ();
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
                            else
                                message("Ignoring unsupported filetype : %s", name);
                        }
                    }
                } catch (Error e) {
                    warning("%s :: %s", e.message, dir.get_path());
                }
                return;
            }

            void process_files (StringSet filelist) {
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
                        else
                            message("Ignoring unsupported filetype : %s", name);
                    } catch (Error e) {
                        critical("Error querying file information : %s", e.message);
                    }
                }
                return;
            }

        }

    }

}
