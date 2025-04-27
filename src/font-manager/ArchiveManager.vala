/* ArchiveManager.vala
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

#if HAVE_LIBARCHIVE

namespace FontManager {

/**
 * SECTION: font-manager-archive-manager
 * @short_description: Extract and generate compressed files using libarchive.
 * @title: Archive Manager
 *
 * Utility functions to extract formats supported by libarchive and generate ZIP files.
 */

    /**
     * Mimetypes supported during extraction operations.
     */
    public const string LIBARCHIVE_MIME_TYPES [] = {
        "application/epub+zip",
        "application/vnd.debian.binary-package",
        "application/vnd.ms-cab-compressed",
        "application/vnd.rar",
        "application/x-7z-compressed",
        "application/x-ar",
        "application/x-bzip-compressed-tar",
        "application/x-cbr",
        "application/x-cbz",
        "application/x-cd-image",
        "application/x-compressed-tar",
        "application/x-cpio",
        "application/x-deb",
        "application/x-lha",
        "application/x-lrzip-compressed-tar",
        "application/x-lzip-compressed-tar",
        "application/x-lzma-compressed-tar",
        "application/x-rar",
        "application/x-rpm",
        "application/x-tar",
        "application/x-tarz",
        "application/x-tzo",
        "application/x-xar",
        "application/x-xz-compressed-tar",
        "application/x-zstd-compressed-tar",
        "application/zip"
    };

    namespace ArchiveManager {

        Archive.Entry add_entry (Archive.Write archive, File file, FileInfo file_info, string path) {
            Archive.Entry entry = new Archive.Entry();
            entry.set_pathname(path);
            entry.set_size((Archive.int64_t) file_info.get_size());
            bool IFREG = (file_info.get_file_type() == FileType.REGULAR);
            entry.set_filetype(IFREG ? Archive.FileType.IFREG : Archive.FileType.IFDIR);
            entry.unset_birthtime();
            entry.set_atime((time_t) file_info.get_attribute_uint64(FileAttribute.TIME_ACCESS),
                            file_info.get_attribute_uint32(FileAttribute.TIME_ACCESS_USEC) * 1000);
            entry.set_ctime((time_t) file_info.get_attribute_uint64(FileAttribute.TIME_CREATED),
                            file_info.get_attribute_uint32(FileAttribute.TIME_CREATED_USEC) * 1000);
            entry.set_mtime((time_t) file_info.get_attribute_uint64(FileAttribute.TIME_MODIFIED),
                            file_info.get_attribute_uint32(FileAttribute.TIME_MODIFIED_USEC) * 1000);
            entry.set_uid(file_info.get_attribute_uint32(FileAttribute.UNIX_UID));
            entry.set_gid(file_info.get_attribute_uint32(FileAttribute.UNIX_GID));
            entry.set_mode(file_info.get_attribute_uint32(FileAttribute.UNIX_MODE));
            if (archive.write_header(entry) != Archive.Result.OK)
                critical("Error adding entry for '%s': %s (%d)", file.get_path(), archive.error_string(), archive.errno());
            return entry;
        }

        int64 add_data (Archive.Write archive, File file, FileInfo file_info, string path) {
            int64 size = 0;
            add_entry(archive, file, file_info, Path.build_filename(path, file.get_basename()));
            try {
                FileInputStream input_stream = file.read();
                DataInputStream data_input_stream = new DataInputStream(input_stream);
                size_t bytes_read;
                uint8 [] buffer = new uint8[1024];
                while (data_input_stream.read_all(buffer, out bytes_read)) {
                    if (bytes_read <= 0)
                        break;
                    archive.write_data(buffer);
                    size += (int64) bytes_read;
                }
            } catch (Error e) {
                critical("Error adding data for '%s' : %s (%d)", file.get_path(), archive.error_string(), archive.errno());
                critical(e.message);
            }
            return size;
        }

        void add_directory (Archive.Write archive, File file, FileInfo file_info, string path) {
            string root = Path.build_filename(path, file.get_basename());
            add_entry(archive, file, file_info, root);
            try {
                var enumerator = file.enumerate_children("*", FileQueryInfoFlags.NONE);
                FileInfo child_info = enumerator.next_file();
                while (child_info != null) {
                    var child_type = child_info.get_file_type();
                    File child = file.get_child(child_info.get_name());
                    if (child_type == GLib.FileType.DIRECTORY)
                        add_directory(archive, child, child_info, root);
                    else if (child_type == GLib.FileType.REGULAR)
                        add_data(archive, child, child_info, root);
                    child_info = enumerator.next_file();
                }
            } catch (Error e) {
                critical("Error adding directory '%s' : %s (%d)", file.get_path(), archive.error_string(), archive.errno());
                critical(e.message);
            }
            return;
        }

        /**
         * font_manager_archive_manager_compress:
         *
         * Generates a ZIP archive from the provided set of file paths
         *
         * @self: #FontManagerArchiveManager
         * @filelist #FontManagerStringSet of paths to include in archive
         * @output_file #GFile used to determine name and directory of resulting archive file
         *
         * Returns: %TRUE if archive was successfully extracted
         */
        public bool compress (StringSet filelist, File output_file) {

            return_val_if_fail(filelist.size > 0, false);
            File output_dir = File.new_for_path(output_file.get_parent().get_path());
            return_val_if_fail(output_dir.query_exists(), false);

            Archive.Write archive = new Archive.Write();
            archive.set_format_zip();

            string root = output_file.get_basename();
            if (root.contains("."))
                root = root.split(".")[0];

            string filename = Path.build_filename(output_dir.get_path(), @"$root.zip");

            if (archive.open_filename(filename) != Archive.Result.OK) {
                critical("Error opening '%s' : %s (%d)", output_file.get_path(), archive.error_string(), archive.errno());
                return false;
            }

            foreach (var filepath in filelist) {
                GLib.File file = GLib.File.new_for_path(filepath);
                try {
                    GLib.FileInfo file_info = file.query_info("*", GLib.FileQueryInfoFlags.NONE);
                    GLib.FileType file_type = file_info.get_file_type();
                    if (file_type == GLib.FileType.REGULAR)
                        add_data(archive, file, file_info, root);
                    else if (file_type == GLib.FileType.DIRECTORY)
                        add_directory(archive, file, file_info, root);
                } catch (Error e) {
                    critical(e.message);
                    return false;
                }
            }

            if (archive.close() != Archive.Result.OK) {
                critical("Error closing '%s' : %s (%d)", filename, archive.error_string(), archive.errno());
                return false;
            }

            return true;
        }

        /**
         * font_manager_archive_manager_extract:
         *
         * Extract the supplied archive into the specified directory
         *
         * @self: #FontManagerArchiveManager
         * @file #GFile to extract
         * @dest_dir #GFile directory to use for extraction
         *
         * Returns: %TRUE if archive was successfully created
         */
        public bool extract (File file, File dest_dir) {

            return_val_if_fail(file.query_exists(), false);
            return_val_if_fail(dest_dir.query_exists(), false);

            Archive.ExtractFlags EXTRACT_FLAGS;
            EXTRACT_FLAGS = Archive.ExtractFlags.TIME;
            EXTRACT_FLAGS |= Archive.ExtractFlags.PERM;
            EXTRACT_FLAGS |= Archive.ExtractFlags.ACL;
            EXTRACT_FLAGS |= Archive.ExtractFlags.FFLAGS;

            Archive.Read archive = new Archive.Read();
            Archive.WriteDisk extractor = new Archive.WriteDisk ();
            archive.support_format_all();
            archive.support_filter_all();
            extractor.set_options(EXTRACT_FLAGS);
            extractor.set_standard_lookup();

            Environment.set_current_dir(dest_dir.get_path());
            string filepath = file.get_path();

            if (archive.open_filename(filepath, 10240) != Archive.Result.OK) {
                critical("Error opening '%s' : %s (%d)", filepath, archive.error_string(), archive.errno());
                return false;
            }

            unowned Archive.Entry entry;
            Archive.Result last_result;
            while ((last_result = archive.next_header(out entry)) == Archive.Result.OK) {

                if (extractor.write_header(entry) != Archive.Result.OK) {
                    unowned string archived_path = entry.pathname();
                    critical(@"Failed to write header entry for $archived_path");
                    continue;
                }

                Posix.off_t offset;
                uint8 [] buffer = null;
                while (archive.read_data_block(out buffer, out offset) == Archive.Result.OK)
                    if (extractor.write_data_block(buffer, offset) < Archive.Result.OK)
                        break;

            }

            if (last_result != Archive.Result.EOF) {
                critical("Error extracting '%s' : %s (%d)", filepath, archive.error_string(), archive.errno());
                return false;
            }

            return true;
        }

    }

}

#endif

