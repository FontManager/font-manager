/* ArchiveManager.vala
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

[DBus (name = "org.gnome.ArchiveManager1")]
internal interface DBusService : Object {

    public signal void progress (double percent, string message);

    public abstract void add_to_archive (string archive, string [] files, bool use_progress_dialog) throws IOError;
    public abstract void compress (string [] files, string destination, bool use_progress_dialog) throws IOError;
    public abstract void extract (string archive, string destination, bool use_progress_dialog) throws IOError;
    public abstract void extract_here (string archive, bool use_progress_dialog) throws IOError;
    /* Valid actions -> "create", "create_single_file", "extract" */
    public abstract HashTable <string, string> [] get_supported_types (string action) throws IOError;

}

public class ArchiveManager : Object {

    public signal void progress (string? message, int processed, int total);

    internal DBusService? service = null;

    internal void init () {
        Logger.verbose("File Roller - Initialize");
        try {
            service = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.ArchiveManager1", "/org/gnome/ArchiveManager1");
            service.progress.connect((p, m) => { progress(m, (int) p, 100); });
        } catch (IOError e) {
            warning("Features which depend on Archive Manager will not function correctly");
            error("Failed to contact Archive Manager service : %s", e.message);
        }
        return;
    }

    internal DBusService file_roller {
        get {
            init();
            return service;
        }
    }

    public bool add_to_archive (string archive, string [] uris, bool use_progress_dialog = true) {
        Logger.verbose("File Roller - Add to archive : %s", archive);
        try {
            file_roller.add_to_archive(archive, uris, use_progress_dialog);
            return true;
        } catch (IOError e) {
            warning("Failed to contact Archive Manager service : %s", e.message);
        }
        return false;
    }

    public bool compress (string [] uris, string destination, bool use_progress_dialog = true) {
        Logger.verbose("File Roller - Compress : %s", destination);
        try {
            file_roller.compress(uris, destination, use_progress_dialog);
            return true;
        } catch (IOError e) {
            warning("Failed to contact Archive Manager service : %s", e.message);
        }
        return false;
    }

    public bool extract (string archive, string destination, bool use_progress_dialog = true) {
        Logger.verbose("File Roller - Extract %s to %s", archive, destination);
        try {
            file_roller.extract(archive, destination, use_progress_dialog);
            return true;
        } catch (IOError e) {
            warning("Failed to contact Archive Manager service : %s", e.message);
        }
        return false;
    }

    public bool extract_here (string archive, bool use_progress_dialog = true) {
        Logger.verbose("File Roller - Extract here : %s", archive);
        try {
            file_roller.extract_here(archive, use_progress_dialog);
            return true;
        } catch (IOError e) {
            warning("Failed to contact Archive Manager service : %s", e.message);
        }
        return false;
    }

    public Gee.ArrayList <string> get_supported_types (string action = "extract") {
        Logger.verbose("File Roller - Get supported types");
        var types = new Gee.ArrayList <string> ();
        try {
            HashTable <string, string> [] array = file_roller.get_supported_types(action);
            foreach (var hashtable in array)
                types.add(hashtable.get("mime-type"));
        } catch (Error e) {
            warning("Failed to contact Archive Manager service : %s", e.message);
        }
        return types;
    }

}

