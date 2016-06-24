/* Remove.vala
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

    namespace Library {

        public bool remove_directory_tree_if_empty (File? dir) {
            if (dir == null)
                return false;
            try {
                var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME,
                                                        FileQueryInfoFlags.NONE);
                if (enumerator.next_file() != null)
                    return false;
                File parent = dir.get_parent();
                dir.delete();
                if (parent != null)
                    remove_directory_tree_if_empty(parent);
                return true;
            } catch (Error e) {
                warning(e.message);
            }
            return false;
        }

        [Compact]
        public class Remove {

            public static Gee.HashMap <string, string>? remove_failed = null;

            public static bool from_file_array (File? [] files, Database? db = null) {
                remove_failed = null;
                bool res = true;
                int total = files.length;
                int processed = 0;
                foreach (var file in files) {
                    try {
                        string path = file.get_path();
                        if (db != null)
                            purge_database_entry(db, path);
                        if (!file.query_exists())
                            continue;
                        File parent = file.get_parent();
                        FileInfo info = file.query_info(FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
                        string basename = file.get_basename();

                        if (file.delete()) {
                            debug("Successfully removed %s", path);
                            if (info.get_content_type() == "application/x-font-type1")
                                purge_type1_files(parent.get_path(), basename);
                        } else {
                            log_failure(path, "Failed to remove file");
                            res = false;
                        }

                        remove_directory_tree_if_empty(parent);
                        processed++;
                        if (progress != null)
                            progress(_("Removing files"), processed, total);
                    } catch (Error e) {
                        log_failure(file.get_path(), e.message);
                        res = false;
                    }
                }
                return res;
            }

            static void log_failure (string path, string message) {
                if (remove_failed == null)
                    remove_failed = new Gee.HashMap <string, string> ();
                remove_failed[path] = message;
                warning("%s : %s", message, path);
                return;
            }

            static void purge_type1_files (string dir, string filename) {
                try {
                    string name = filename.split_set(".")[0];
                    foreach (var ext in TYPE1_METRICS) {
                        File metrics = File.new_for_path(Path.build_filename(dir, name + ext));
                        if (metrics.query_exists())
                            metrics.delete();
                    }
                } catch (Error e) {
                    log_failure(Path.build_filename(dir, filename), e.message);
                }
                return;
            }

            static void purge_database_entry (Database db, string path) {
                try {
                    db.remove("filepath=\"%s\"".printf(path));
                    debug("Successfully removed entry for %s from database", path);
                } catch (DatabaseError e) {
                    warning(e.message);
                }
                return;
            }

        }

    }

}
