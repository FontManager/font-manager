/* Sorter.vala
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

    namespace Library {

        internal bool is_metrics_file (string name) {
            foreach (var ext in TYPE1_METRICS)
                if (name.has_suffix(ext))
                    return true;
            return false;
        }

        public class Sorter : Object {

            public Gee.ArrayList <File> files { get; private set; }
            public Gee.ArrayList <File> archives { get; private set; }

            public int total {
                get {
                    return files.size + archives.size;
                }
            }

            construct {
                files = new Gee.ArrayList <File> ();
                archives  = new Gee.ArrayList <File> ();
            #if HAVE_FILE_ROLLER
                if (archive_manager == null) {
                    archive_manager = new ArchiveManager();
                    supported_archives = archive_manager.get_supported_types();
                }
            #endif
            }

            public void sort (Gee.ArrayList <File> filelist) {
                files.clear();
                archives.clear();
                process_files(filelist);
                return;
            }

            void process_directory (File dir) {
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
                        #if HAVE_FILE_ROLLER
                            else if (content_type in supported_archives)
                                archives.add(dir.get_child(name));
                        #endif
                        processed++;
                        if (progress != null)
                            progress(_("Processing directories"), processed, total);
                    }
                } catch (Error e) {
                    warning("%s :: %s", e.message, dir.get_path());
                }
                return;
            }

            void process_files (Gee.ArrayList <File> filelist) {
                int total = filelist.size;
                int processed = 0;
                foreach (var file in filelist) {
                    var attrs = "%s,%s,%s".printf(FileAttribute.STANDARD_CONTENT_TYPE, FileAttribute.STANDARD_TYPE, FileAttribute.STANDARD_NAME);
                    try {
                        var fileinfo = file.query_info(attrs, FileQueryInfoFlags.NONE, null);
                        string name = fileinfo.get_name();
                        string content_type = fileinfo.get_content_type();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY)
                            process_directory(file);
                        else if (content_type.contains("font") && !is_metrics_file(name))
                            files.add(file);
                    #if HAVE_FILE_ROLLER
                        else if (content_type in supported_archives)
                            archives.add(file);
                    #endif
                    } catch (Error e) {
                        critical("Error querying file information : %s", e.message);
                    }
                    processed++;
                    if (progress != null)
                        progress(_("Processing files"), processed, total);
                }
                return;
            }

        }

    }

}
