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
        service = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.ArchiveManager1", "/org/gnome/ArchiveManager1");
        service.progress.connect((p, m) => { progress(m, (int) p, 100); });
        return;
    }

    internal DBusService file_roller {
        get {
            init();
            return service;
        }
    }

    public void add_to_archive (string archive, string [] uris, bool use_progress_dialog = true) throws Error {
        file_roller.add_to_archive(archive, uris, use_progress_dialog);
        return;
    }

    public void compress (string [] uris, string destination, bool use_progress_dialog = true) throws Error {
        file_roller.compress(uris, destination, use_progress_dialog);
        return;
    }

    public void extract (string archive, string destination, bool use_progress_dialog = true) throws Error {
        file_roller.extract(archive, destination, use_progress_dialog);
        return;
    }

    public void extract_here (string archive, bool use_progress_dialog = true) throws Error {
        file_roller.extract_here(archive, use_progress_dialog);
        return;
    }

    public Gee.ArrayList <string> get_supported_types (string action = "extract") throws Error {
        HashTable <string, string> [] array = file_roller.get_supported_types(action);
        var types = new Gee.ArrayList <string> ();
        foreach (var hashtable in array)
            types.add(hashtable.get("mime-type"));
        return types;
    }

}

