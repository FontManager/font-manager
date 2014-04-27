/* Utils.vala
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

public delegate void ProgressCallback (string? message, int processed, int total);
delegate void MenuCallback ();

struct MenuEntry {
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

class MenuCallbackWrapper {
    public MenuCallback run;
    public MenuCallbackWrapper (MenuCallback c) {
        run = () => { c(); };
    }
}

string get_localized_pangram () {
    return Pango.Language.get_default().get_sample_string();
}

string get_localized_preview_text () {
    return FontManager.DEFAULT_PREVIEW_TEXT.printf(get_localized_pangram());
}

string get_local_time () {
    DateTime creation_time = new DateTime.now_local();
    return "%s".printf(creation_time.format("%c"));
}

int natural_cmp (string a, string b) {
    return strcmp(a.collate_key_for_filename(-1), b.collate_key_for_filename(-1));
}

string get_file_extension (string path) {
    var arr = path.split_set(".");
    return ".%s".printf(arr[arr.length - 1]);
}

Gee.ArrayList <string> sorted_list_from_collection (Gee.Collection <string> iter) {
    var l = new Gee.ArrayList <string> ();
    l.add_all(iter);
    l.sort((CompareDataFunc) natural_cmp);
    return l;
}

void builder_append (StringBuilder builder, string? val) {
    if (val == null)
        return;
    builder.append(" ");
    builder.append(val);
    return;
}

void add_action_from_menu_entry (ActionMap map, MenuEntry entry) {
    var action = new SimpleAction(entry.action_name, null);
    action.activate.connect((a, p) => { entry.method.run(); } );
    map.add_action(action);
    return;
}

bool remove_directory (File dir, bool recursive = true) {
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
