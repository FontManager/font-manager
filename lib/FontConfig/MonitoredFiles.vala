/* MonitoredFiles.vala
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

/**
 * MonitoredFiles
 *
 * add() paths to monitor and connect to the changed signal to be notified.
 */
public class MonitoredFiles :  Object {

    /**
     * Per GLib.FileMonitor.changed 2.46.2
     *
     * In all cases file will be a child of the monitored directory.
     * For renames, file will be the old name and other_file is the new name.
     * For "moved in" events, file is the name of the file that appeared and
     * other_file is the old name that it was moved from (in another directory).
     * For "moved out" events, file is the name of the file that used to be in
     * this directory and other_file is the name of the file at its new location.
     */
    public signal void changed (File file, File? other_file, FileMonitorEvent event_type);

    public int size {
        get {
            return monitors.size;
        }
    }

    Gee.HashMap <string, FileMonitor> monitors;
    VolumeMonitor volume_monitor;

    /* Only notifies if the mounts default path is interesting */
    void notify_on_mount_event (Mount mount) {
        string? path = mount.get_default_location().get_path();
        if (path == null || monitors.size < 1)
            return;
        foreach (var s in monitors.keys) {
            if (path.contains((string) s)) {
                changed(mount.get_root(), null, FileMonitorEvent.CHANGED);
            }
        }
        return;
    }

    construct {
        monitors = new Gee.HashMap <string, FileMonitor> ();
        volume_monitor = VolumeMonitor.get();
        volume_monitor.mount_added.connect((m) => {
            notify_on_mount_event(m);
        });
        volume_monitor.mount_changed.connect((m) => {
            notify_on_mount_event(m);
        });
        volume_monitor.mount_removed.connect((m) => {
            notify_on_mount_event(m);
        });
    }

    public new FileMonitor? get (string path) {
        return monitors.get(path);
    }

    public bool contains (string path) {
        return monitors.has_key(path);
    }

    public bool add (string path) {
        if (this.contains(path))
            return true;
        try {
            File file = File.new_for_path(path);
            FileMonitor monitor = file.monitor(FileMonitorFlags.WATCH_MOUNTS);
            assert(monitor != null);
            monitors.set(path, monitor);
            assert(monitors.get(path) != null);
            monitor.changed.connect((f, of, ev) => { changed(f, of, ev); });
            monitor.set_rate_limit(3000);
        } catch (Error e) {
            warning("Failed to create FileMonitor for %s : %s", path, e.message);
            return false;
        }
        if (!(monitors.has_key(path)))
            return false;
        return true;
    }

    public bool remove (string path) {
        return (monitors.get(path).cancel() && monitors.unset(path));
    }

}
