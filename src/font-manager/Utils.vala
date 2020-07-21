/* Utils.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    public delegate void ReloadFunc ();
    public delegate void MenuCallback ();

    public const string SELECT_FROM_FONTS = "SELECT DISTINCT family, description FROM Fonts";
    public const string SELECT_FROM_METADATA_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Metadata USING (filepath, findex) WHERE";
    public const string SELECT_FROM_PANOSE_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Panose USING (filepath, findex) WHERE";

    public const Gtk.TargetEntry [] DragTargets = {
        { "font-family", Gtk.TargetFlags.SAME_APP, DragTargetType.FAMILY },
        { "text/uri-list", 0, DragTargetType.EXTERNAL }
    };

    public Pango.FontDescription get_font (Gtk.Widget widget, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL) {
        Pango.FontDescription desc;
        var ctx = widget.get_style_context();
        ctx.save();
        ctx.set_state(flags);
        ctx.get(flags, "font", out desc);
        ctx.restore();
        return desc.copy();
    }

    public Gtk.Separator add_separator (Gtk.Box box,
                                        Gtk.Orientation orientation = Gtk.Orientation.VERTICAL,
                                        Gtk.PackType pack_type = Gtk.PackType.START) {
        var separator = new Gtk.Separator(orientation);
        switch (pack_type) {
            case Gtk.PackType.END:
                box.pack_end(separator, false, true, 0);
                break;
            default:
                box.pack_start(separator, false, true, 0);
                break;
        }
        separator.show();
        separator.get_style_context().add_class("thin-separator");
        return separator;
    }

    public void set_button_relief_style (Gtk.Container container,
                                         Gtk.ReliefStyle relief = Gtk.ReliefStyle.NONE) {
        foreach (Gtk.Widget widget in container.get_children())
            if (widget is Gtk.Button)
                ((Gtk.Button) widget).relief = relief;
        return;
    }

    public class MenuCallbackWrapper {
        public MenuCallback run;
        public MenuCallbackWrapper (MenuCallback c) {
            run = () => { c(); };
        }
    }

    public struct MenuEntry {
        public string action_name;
        public string display_name;
        public string detailed_action_name;
        public string []? accelerator;
        public MenuCallbackWrapper method;

        public MenuEntry (string name, string label, string detailed_signal, string []? accel, MenuCallbackWrapper cbw) {
            action_name = name;
            display_name = label;
            detailed_action_name = detailed_signal;
            accelerator = accel;
            method = cbw;
        }
    }

    public void add_action_from_menu_entry (ActionMap map, MenuEntry entry) {
        var action = new SimpleAction(entry.action_name, null);
        action.activate.connect((a, p) => { entry.method.run(); } );
        map.add_action(action);
        return;
    }

    /**
     * Adds user configured font sources (directories) and rejected fonts to our
     * FcConfig so that we can render fonts which are not actually "installed".
     */
    public bool load_user_font_resources (StringHashset? files, GLib.List <weak Source> sources) {
        clear_application_fonts();
        bool res = true;
        if (!add_application_font_directory(get_user_font_directory())) {
            res = false;
            critical("Failed to add default user font directory to configuration!");
        }
        foreach (Source source in sources) {
            if (source.available && !add_application_font_directory(source.path)) {
                res = false;
                warning("Failed to register user font source! : %s", source.path);
            }
        }
        if (files != null)
            foreach (string path in files)
                add_application_font(path);
        return res;
    }

    public bool remove_directory_tree_if_empty (File dir) {
        try {
            var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME,
                                                    FileQueryInfoFlags.NONE);
            if (enumerator.next_file() != null)
                return false;
            File parent = dir.get_parent();
            dir.delete();
            if (parent != null)
                remove_directory_tree_if_empty(parent);
            return true;
        } catch (Error e) {
            warning(e.message);
        }
        return false;
    }

    public bool remove_directory (File dir, bool recursive = true) {
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

    public bool copy_directory (File source, File destination, FileCopyFlags flags) {
        return_val_if_fail(source.query_exists(), false);
        return_val_if_fail(source.query_file_type(FileQueryInfoFlags.NONE) == FileType.DIRECTORY, false);
        bool result = true;
        try {
            if (!destination.query_exists())
                destination.make_directory_with_parents();
            var enumerator = source.enumerate_children(FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
            FileInfo fileinfo = enumerator.next_file();
            while (result && fileinfo != null) {
                var source_type = fileinfo.get_file_type();
                string name = fileinfo.get_name();
                if (source_type == GLib.FileType.DIRECTORY) {
                    string source_path = source.get_path();
                    string destination_path = destination.get_path();
                    source.get_child(name).copy_attributes(destination, flags);
                    File s = File.new_for_path(Path.build_filename(source_path, name));
                    File d = File.new_for_path(Path.build_filename(destination_path, name));
                    result = copy_directory(s, d, flags);
                } else if (source_type == GLib.FileType.REGULAR) {
                    File original = source.get_child(name);
                    string outp = Path.build_filename(destination.get_path(), name);
                    File dest = File.new_for_path(outp);
                    result = original.copy(dest, flags);
                }
                fileinfo = enumerator.next_file();
            }
        } catch (Error e) {
            critical(e.message);
            result = false;
        }
        return result;
    }

    public StringHashset? get_command_line_files (ApplicationCommandLine cl) {
        VariantDict options = cl.get_options_dict();
        Variant argv = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
        if (argv == null)
            return null;
        (unowned string) [] filelist = argv.get_bytestring_array();
        if (filelist.length == 0)
            return null;
        var files = new StringHashset();
        foreach (var file in filelist)
            files.add(cl.create_file_for_arg(file).get_path());
        return files;
    }

    public StringHashset? get_command_line_input (VariantDict options) {
        Variant argv = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
        if (argv == null)
            return null;
        (unowned string) [] list = argv.get_bytestring_array();
        if (list.length == 0)
            return null;
        var input = new StringHashset();
        foreach (var str in list)
            input.add(str);
        return input;
    }

}
