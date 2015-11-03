/* Install.vala
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

        public class Install {

            public static Gee.ArrayList <File>? installed = null;
            public static Gee.HashMap <string, string>? install_failed = null;

            static File? tmpdir = null;

            public static void from_file_array (File? [] files) {
                init();
                var _files = new Gee.ArrayList <File> ();
                foreach (var file in files)
                    _files.add(file);
                process_files(_files);
                fini();
            }

            public static void from_path_array (string? [] paths) {
                init();
                var files = new Gee.ArrayList <File> ();
                foreach (var path in paths)
                    files.add(File.new_for_path(path));
                process_files(files);
                fini();
            }

            public static void from_uri_array (string? [] uris) {
                init();
                var files = new Gee.ArrayList <File> ();
                foreach (var uri in uris)
                    files.add(File.new_for_uri(uri));
                process_files(files);
                fini();
            }

            static void init () {
                installed = new Gee.ArrayList <File> ();
                install_failed = new Gee.HashMap <string, string> ();
            #if HAVE_FILE_ROLLER
                if (archive_manager == null) {
                    archive_manager = new ArchiveManager();
                    supported_archives = archive_manager.get_supported_types();
                }
            #endif
                return;
            }

            static void fini () {
                if (tmpdir == null)
                    return;
                debug("Removing temporary directory used during installation");
                remove_directory(tmpdir);
                tmpdir = null;
                return;
            }

            static void try_copy (File original, File copy) {
                try {
                    original.copy(copy, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
                    debug("Successfully copied %s to %s", original.get_path(), copy.get_path());
                    installed.add(original);
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
                debug("Preparing to install %s", data.file.get_path());
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
                    try {
                        FileInfo inf = data.file.query_info(FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
                        string name = inf.get_name().split_set(".")[0];
                        foreach (var ext in TYPE1_METRICS) {
                            string poss = Path.build_filename(par, name + ext);
                            File f = File.new_for_path(poss);
                            if (f.query_exists()) {
                                string path = Path.build_filename(dest, filename + ext);
                                File _f = File.new_for_path(path);
                                try_copy(f, _f);
                            }
                        }
                    } catch (Error e) {
                        critical("Error querying file information : %s", e.message);
                        //show_error_message(_("Error querying file information"), e);
                    }
                }
                return true;
            }

        #if HAVE_FILE_ROLLER
            static File? get_temp_dir () {
                string? _tmpdir = null;
                try {
                    _tmpdir = DirUtils.make_tmp(TMP_TMPL);
                } catch (FileError e) {
                    critical("Error creating temporary working directory : %s", e.message);
                    //show_error_message(_("Error creating temporary working directory"), e);
                }
                return _tmpdir != null ? File.new_for_path(_tmpdir) : null;
            }
        #endif

            static void process_files (Gee.ArrayList <File> filelist) {
                debug("Processing files for installation");
                var sorter = new Sorter();
                sorter.sort(filelist);
                int processed = 0;
                foreach (var f in sorter.files) {
                    var data = FontData(f);
                    if (!is_installed(data) && (conflicts(data) < 0))
                        install_font(data);
                    processed++;
                    if (progress != null)
                        progress(_("Installing files"), processed, sorter.total);
                }
            #if HAVE_FILE_ROLLER
                if (sorter.archives.size == 0)
                    return;
                tmpdir = get_temp_dir();
                if (tmpdir == null)
                    /* XXX : FIXME */
                    return;
                var uri = tmpdir.get_uri();
                debug("Preparing Archives");
                foreach (var a in sorter.archives) {
                    if (!archive_manager.extract(a.get_uri(), uri, false)) {
                        if (install_failed == null)
                            install_failed = new Gee.HashMap <string, string> ();
                        install_failed[a.get_path()] = "Failed to extract archive";
                    } else {
                        debug("Successfully extracted the contents of %s", a.get_basename());
                    }
                    processed++;
                    if (progress != null)
                        progress(_("Preparing Archives"), processed, sorter.total);
                }
                var l = new Gee.ArrayList <File> ();
                l.add(tmpdir);
                process_files(l);
            #endif
                return;
            }

        }

    }

}
