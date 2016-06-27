/* Utils.vala
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
 * along with Font Manager.  If not, see <https://opensource.org/licenses/GPL-3.0>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

public delegate void ReloadFunc ();
public delegate void MenuCallback ();
[CCode (has_target = false)]
public delegate void ProgressCallback (string? message, int processed, int total);
[CCode (has_target = false)]
public delegate void ErrorCallback (string message);

public struct MenuEntry {
    public string action_name;
    public string display_name;
    public string detailed_action_name;
    public string? accelerator;
    public MenuCallbackWrapper method;

    public MenuEntry (string name, string label, string detailed_signal, string? accel, MenuCallbackWrapper cbw) {
        action_name = name;
        display_name = label;
        detailed_action_name = detailed_signal;
        accelerator = accel;
        method = cbw;
    }
}

public class MenuCallbackWrapper {
    public MenuCallback run;
    public MenuCallbackWrapper (MenuCallback c) {
        run = () => { c(); };
    }
}

public void add_action_from_menu_entry (ActionMap map, MenuEntry entry) {
    var action = new SimpleAction(entry.action_name, null);
    action.activate.connect((a, p) => { entry.method.run(); } );
    map.add_action(action);
    return;
}

public File []? get_command_line_files (ApplicationCommandLine cl) {
    VariantDict options = cl.get_options_dict();
    Variant argv = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
    if (argv == null)
        return null;
    string* [] filelist = argv.get_bytestring_array();
    if (filelist.length == 0)
        return null;
    File [] files = null;
    foreach (var file in filelist)
        files += cl.create_file_for_arg(file);
    return files;
}

public int get_command_line_status (string cmd) {
    try {
        int exit_status;
        Process.spawn_command_line_sync(cmd, null, null, out exit_status);
        return exit_status;
    } catch (Error e) {
        warning("Execution of %s failed : %s", cmd, e.message);
        return -1;
    }
}

public string? get_command_line_output (string cmd) {
    try {
        string std_out;
        Process.spawn_command_line_sync(cmd, out std_out);
        return std_out;
    } catch (Error e) {
        warning("Execution of %s failed : %s", cmd, e.message);
        return null;
    }
}

public string get_user_font_dir () {
    return Path.build_filename(Environment.get_user_data_dir(), "fonts");
}

public string get_localized_pangram () {
    return Pango.Language.get_default().get_sample_string();
}

public string get_localized_preview_text () {
    return DEFAULT_PREVIEW_TEXT.printf(get_localized_pangram());
}

public string get_local_time () {
    DateTime creation_time = new DateTime.now_local();
    return "%s".printf(creation_time.format("%c"));
}

public int natural_cmp (string a, string b) {
    return strcmp(a.collate_key_for_filename(-1), b.collate_key_for_filename(-1));
}

public string get_file_extension (string path) {
    var arr = path.split_set(".");
    return "%s".printf(arr[arr.length - 1]);
}

public Gee.ArrayList <string> sorted_list_from_collection (Gee.Collection <string> iter) {
    var l = new Gee.ArrayList <string> ();
    l.add_all(iter);
    l.sort((CompareDataFunc) natural_cmp);
    return l;
}

public bool remove_directory (File? dir, bool recursive = true) {
    if (dir == null)
        return false;
    try {
        if (recursive) {
            FileInfo fileinfo;
            var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
            while ((fileinfo = enumerator.next_file ()) != null) {
                try {
                    dir.get_child(fileinfo.get_name()).delete();
                } catch (Error e) {
                    remove_directory(dir.get_child(fileinfo.get_name()), recursive);
                }
            }
        }
        dir.delete();
        return true;
    } catch (Error e) {
        warning(e.message);
    }
    return false;
}

