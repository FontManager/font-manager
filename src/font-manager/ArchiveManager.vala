/* ArchiveManager.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

[DBus (name = "org.gnome.ArchiveManager1")]
interface FileRollerDBusService : Object {

    public signal void progress (double percent, string message);

    public abstract void add_to_archive (string archive, [CCode (array_null_terminated = true)] string? [] uris, bool use_progress_dialog) throws DBusError, IOError;
    public abstract void compress ([CCode (array_null_terminated = true)] string? [] uris, string destination, bool use_progress_dialog) throws DBusError, IOError;
    public abstract void extract (string archive, string destination, bool use_progress_dialog) throws DBusError, IOError;
    public abstract void extract_here (string archive, bool use_progress_dialog) throws DBusError, IOError;
    /* Valid actions -> "create", "create_single_file", "extract" */
    public abstract HashTable <string, string> [] get_supported_types (string action) throws DBusError, IOError;

}

namespace FontManager {

    /* Mimetypes that are likely to cause an error, unlikely to contain usable fonts.
     * i.e.
     * Windows .FON files are classified as "application/x-ms-dos-executable"
     * but file-roller is unlikely to extract one successfully.
     */
    const string [] MIMETYPE_IGNORE_LIST = {
        "application/x-ms-dos-executable"
    };

    public class ArchiveManager : Object {

        int SERVICE_UNKNOWN_ERROR = 2;
        int SERVICE_TIMED_OUT = 24;
        static bool SERVICE_UNKNOWN = false;

        public signal void progress (double percent, string message);

        FileRollerDBusService? service = null;

        void post_error_message (Error e) {
            if (e.code == SERVICE_UNKNOWN_ERROR) {
                SERVICE_UNKNOWN = true;
                message("Install file-roller to enable archive support");
            } else if (e.code != SERVICE_TIMED_OUT) {
                critical("%i : %s", e.code, e.message);
            }
            return;
        }

         void init () {
            try {
                if (SERVICE_UNKNOWN)
                    return;
                service = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.ArchiveManager1", "/org/gnome/ArchiveManager1");
                if (service.get_supported_types("extract").length > 0)
                    service.progress.connect((p, m) => { progress(p, m); });
            } catch (Error e) {
                service = null;
                post_error_message(e);
            }
            return;
        }

        FileRollerDBusService? file_roller {
            get {
                init();
                return service;
            }
        }

        public bool available {
            get {
                return file_roller != null;
            }
        }

        public bool add_to_archive (string archive, [CCode (array_null_terminated = true)] string? [] uris, bool use_progress_dialog = true)
        requires (file_roller != null) {
            try {
                file_roller.add_to_archive(archive, uris, use_progress_dialog);
                return true;
            } catch (Error e) {
                post_error_message(e);
            }
            return false;
        }

        public bool compress ([CCode (array_null_terminated = true)] string? [] uris, string destination, bool use_progress_dialog = true)
        requires (file_roller != null) {
            try {
                file_roller.compress(uris, destination, use_progress_dialog);
                return true;
            } catch (Error e) {
                post_error_message(e);
            }
            return false;
        }

        public bool extract (string archive, string destination, bool use_progress_dialog = true)
        requires (file_roller != null) {
            try {
                file_roller.extract(archive, destination, use_progress_dialog);
                return true;
            } catch (Error e) {
                post_error_message(e);
            }
            return false;
        }

        public bool extract_here (string archive, bool use_progress_dialog = true)
        requires (file_roller != null) {
            try {
                file_roller.extract_here(archive, use_progress_dialog);
                return true;
            } catch (Error e) {
                post_error_message(e);
            }
            return false;
        }

        public StringSet get_supported_types (string action = "extract")
        requires (file_roller != null) {
            var supported_types = new StringSet();
            try {
                HashTable <string, string> [] array = file_roller.get_supported_types(action);
                foreach (var hashtable in array) {
                    if (hashtable.get("mime-type") in MIMETYPE_IGNORE_LIST)
                        continue;
                    supported_types.add(hashtable.get("mime-type"));
                }
            } catch (Error e) {
                supported_types = null;
                post_error_message(e);
            }
            return supported_types;
        }

    }

}

