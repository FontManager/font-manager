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

    namespace Library {

        const string [] TYPE1_METRICS = { ".afm", ".pfa", ".pfm" };

        bool is_metrics_file (string name) {
            foreach (var ext in TYPE1_METRICS)
                if (name.down().has_suffix(ext))
                    return true;
            return false;
        }

        public class Installer : Object {

            public signal void progress (string message, uint processed, uint total);

            File? tmp_file = null;

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

            static void install_filelist (Task task,
                                          Object source,
                                          void* data,
                                          Cancellable? cancellable = null) {
                return_if_fail(source is Installer);
                Installer self = (Installer) source;
                StringSet filelist = self.get_data("filelist");
                var sorter = new Sorter();
                sorter.sort(filelist);
                self.process_files(sorter.fonts);
                self.process_archives(sorter.archives);
                if (self.tmp_file != null)
                    remove_directory(self.tmp_file);
                self.tmp_file = null;
                self.set_data("filelist", null);
                filelist = null;
                return;
            }

            public void process (StringSet filelist, TaskReadyCallback callback) {
                this.set_data("filelist", filelist);
                GLib.Task task = new GLib.Task(this, null, callback);
                task.run_in_thread(install_filelist);
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

        class Sorter : Object {

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
                    StringSet files = new StringSet();
                    FileInfo fileinfo;
                    var attrs = "%s,%s,%s".printf(FileAttribute.STANDARD_NAME,
                                                  FileAttribute.STANDARD_CONTENT_TYPE,
                                                  FileAttribute.STANDARD_TYPE);
                    var enumerator = dir.enumerate_children(attrs, FileQueryInfoFlags.NONE);
                    while ((fileinfo = enumerator.next_file ()) != null) {
                        string name = fileinfo.get_name();
                        string path = dir.get_child(name).get_path();
                        if (fileinfo.get_file_type() == FileType.DIRECTORY)
                            process_directory(dir.get_child(name));
                        else
                            files.add(path);
                    }
                    process_files(files);
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
