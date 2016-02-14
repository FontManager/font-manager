/* Install.vala
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

namespace FontManager {

    namespace Library {

        [Compact]
        public class Install {

            public static Gee.ArrayList <File>? installed = null;
            public static Gee.HashMap <string, string>? install_failed = null;

            static File? tmpdir = null;

            public static void from_file_array (File? [] files) {
                init();
                var _files = new Gee.ArrayList <File> ();
                foreach (var file in files)
                    _files.add(file);
                process_filelist(_files);
                fini();
            }

            public static void from_path_array (string? [] paths) {
                init();
                var files = new Gee.ArrayList <File> ();
                foreach (var path in paths)
                    files.add(File.new_for_path(path));
                process_filelist(files);
                fini();
            }

            public static void from_uri_array (string? [] uris) {
                init();
                var files = new Gee.ArrayList <File> ();
                foreach (var uri in uris)
                    files.add(File.new_for_uri(uri));
                process_filelist(files);
                fini();
            }

            public static bool from_font_data (FontData data) {
                init();
                debug("Preparing to install %s", data.file.get_path());
                if (data.font == null || data.fontinfo == null) {
                    install_failed[data.file.get_path()] = "Failed to create FontInfo";
                    warning("Failed to create FontInfo : %s", data.file.get_path());
                    return false;
                }
                string dest = Path.build_filename(install_dir,
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
                    }
                }
                return true;
            }

        #if HAVE_FILE_ROLLER
            static File? get_temp_dir () {
                if (tmpdir != null)
                    return tmpdir;
                string? _tmpdir = null;
                try {
                    _tmpdir = DirUtils.make_tmp(TMP_TMPL);
                } catch (FileError e) {
                    critical("Error creating temporary working directory : %s", e.message);
                }
                tmpdir = _tmpdir != null ? File.new_for_path(_tmpdir) : null;
                return tmpdir;
            }
        #endif

            static void process_filelist (Gee.ArrayList <File> filelist) {
                var sorter = new Sorter();
                sorter.sort(filelist);
                if (sorter.archives.size > 0)
                    process_archives(sorter.archives);
                process_files(sorter.files);
                return;
            }

            static void process_files (Gee.ArrayList <File> filelist) {
                debug("Processing files for installation");
                int processed = 0;
                foreach (var f in filelist) {
                    var data = FontData(f);
                    /* XXX: FIXME : notify */
                    if (!is_installed(data) && (conflicts(data) < 0))
                        from_font_data(data);
                    processed++;
                    if (progress != null)
                        progress(_("Installing files"), processed, filelist.size);
                }
            }

            static void process_archives (Gee.ArrayList <File> filelist) {
                if (filelist.size == 0)
                    return;
            #if HAVE_FILE_ROLLER
                int processed = 0;
                get_temp_dir();
                if (tmpdir == null) {
                    /* XXX : FIXME : notify */
                    critical("Failed to create temporary working directory!");
                    return;
                }
                debug("Preparing Archives");
                foreach (var a in filelist) {
                    if (!archive_manager.extract(a.get_uri(), tmpdir.get_uri(), false))
                        install_failed[a.get_path()] = "Failed to extract archive";
                    else
                        debug("Successfully extracted the contents of %s", a.get_basename());
                    if (a.get_uri().contains(tmpdir.get_uri()))
                        try {
                            a.delete();
                        } catch (Error e) {
                            warning("Failed to delete temporary file : %s", e.message);
                            warning("Aborting installation...");
                            fini();
                            return;
                        }
                    processed++;
                    if (progress != null)
                        progress(_("Preparing Archives"), processed, filelist.size);
                }
                var sorter = new Sorter();
                var l = new Gee.ArrayList <File> ();
                l.add(tmpdir);
                sorter.sort(l);
                if (sorter.archives.size > 0)
                    process_archives(sorter.archives);
                else
                    process_files(sorter.files);
            #endif
                return;
            }

            static void init () {
                installed = new Gee.ArrayList <File> ();
                install_failed = new Gee.HashMap <string, string> ();
                if (install_dir == null)
                    install_dir = get_user_font_dir();
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
                install_dir = null;
                return;
            }

            static void try_copy (File original, File copy) {
                try {
                    original.copy(copy, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
                    debug("Successfully copied %s to %s", original.get_path(), copy.get_path());
                    installed.add(original);
                } catch (Error e) {
                    string path = original.get_path();
                    install_failed[path] = e.message;
                    warning("%s : %s", e.message, path);
                }
                return;
            }

        }

    }

}
