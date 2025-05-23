/* Utils.vala
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

namespace FontManager {

    public struct MenuEntry {
        string action_name;
        string display_name;
    }

    public class BaseContextMenu : Object {

        public Gtk.PopoverMenu popover { get; private set; }
        public Gtk.Label menu_title { get; private set; }
        public GLib.Menu menu { get; private set; }

        public BaseContextMenu (Gtk.Widget parent) {
            var root = new GLib.Menu();
            var title_item = new GLib.MenuItem(null, null);
            title_item.set_attribute("custom", "s", "menu-title");
            menu_title = new Gtk.Label("") {
                margin_start = DEFAULT_MARGIN * 2,
                margin_end = DEFAULT_MARGIN * 2,
                css_classes = { "heading", "dim-label" }
            };
            root.prepend_item(title_item);
            menu = new GLib.Menu();
            root.append_section(null, menu);
            popover = new Gtk.PopoverMenu.from_model(root);
            popover.set_parent(parent);
            popover.add_child(menu_title, "menu-title");
            popover.set_offset(0, 6);
            return;
        }

    }

    internal const string SELECT_NON_LOCAL_FONTS = """
    SELECT DISTINCT description, Orthography.sample FROM Fonts
    JOIN Orthography USING (filepath, findex)
    WHERE Orthography.sample IS NOT NULL;
    """;

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-list-item-row.ui")]
    public class ListItemRow : Gtk.Box {

        public signal void item_state_changed (Object? item);

        public Object? item { get; set; default = null; }

        [GtkChild] public unowned Gtk.Label item_label { get; }
        [GtkChild] public unowned Gtk.Label item_count { get; }
        [GtkChild] public unowned Gtk.Image item_icon { get; }
        [GtkChild] public unowned Gtk.CheckButton item_state { get; }
        [GtkChild] public unowned Gtk.Inscription item_preview { get; }
        [GtkChild] public unowned Gtk.EditableLabel edit_label { get; }
        [GtkChild] public unowned Gtk.Box drag_area { get; }
        [GtkChild] public unowned Gtk.Image drag_handle { get; }

        construct {
            notify["item"].connect((pspec) => { on_item_set(); });
            item_state.toggled.connect((pspec) => { item_state_changed(item); });
        }

        protected virtual void on_item_set () {}
        public virtual void reset () {}

    }

    public class TreeListItemRow : ListItemRow {

        public Gtk.TreeExpander? expander { get; set; default = null; }
        public Gtk.SelectionModel? selection { get; set; default = null; }

        protected virtual void show_context_menu (Gdk.Event event ,double x, double y) {}

        construct {
            var click = new Gtk.GestureClick();
            add_controller(click);
            click.pressed.connect(on_click);
        }

        void on_click (Gtk.GestureClick click, int n_press, double x, double y) {
            if (expander == null || selection == null)
                return;
            Gtk.TreeListRow? row = expander.get_list_row();
            if (row == null)
                return;
            uint position = row.get_position();
            if (selection.is_selected(position)) {
                if (edit_label.visible)
                    edit_label.editable = true;
                Gdk.Event event = click.get_current_event();
                if (event == null)
                    return;
                if (event.triggers_context_menu()) {
                    show_context_menu(event, x, y);
                    return;
                }
                bool expanded = row.expanded;
                if (row.expandable)
                    row.expanded = !expanded;
            } else {
                edit_label.editable = false;
            }
            return;
        }

    }

    public HashTable <string, string> get_non_local_samples () {
        var result = new HashTable <string, string> (str_hash, str_equal);
        try {
            Database db = DatabaseProxy.get_default_db();
            db.execute_query(SELECT_NON_LOCAL_FONTS);
            foreach (unowned Sqlite.Statement row in db) {
                string? description = row.column_text(0);
                string? sample = row.column_text(1);
                // XXX: Why is this a thing during reloads?
                // This should not happen, our query excludes NULL sample values...
                // And descriptions are never NULL
                if (description == null || sample == null)
                    continue;
                result.insert(description, sample);
            }
            db.end_query();
        } catch (Error e) {
            message(e.message);
        }
        return result;
    }

    public void update_item_preview_text (Json.Array available_fonts) {
        HashTable <string, string> samples = get_non_local_samples();
        available_fonts.foreach_element((array, index, node) => {
            Json.Object item = node.get_object();
            string description = item.get_string_member("description");
            if (samples.contains(description))
                item.set_string_member("preview-text", samples.lookup(description));
            Json.Array variants = item.get_array_member("variations");
            variants.foreach_element((a, i, n) => {
                Json.Object v = n.get_object();
                description = v.get_string_member("description");
                if (samples.contains(description))
                    v.set_string_member("preview-text", samples.lookup(description));
            });
        });
        return;
    }

    public Gtk.Image inline_help_widget (string message) {
        var help = new Gtk.Image.from_icon_name("dialog-question-symbolic")
        {
            pixel_size = 24,
            opacity = 0.333,
            hexpand = true,
            halign = Gtk.Align.END,
            margin_start = DEFAULT_MARGIN,
            margin_end = DEFAULT_MARGIN,
            tooltip_text = message
        };
        return help;
    }

    public Gtk.Window? get_parent_window (Gtk.Widget widget) {
        Gtk.Widget? ancestor = widget.get_ancestor(typeof(Gtk.Window));
        return ancestor != null ? (Gtk.Window) ancestor : null;
    }

    public void set_control_sensitivity (Gtk.Widget? widget, bool sensitive) {
        if (widget == null || !(widget is Gtk.Widget))
            return;
        widget.sensitive = sensitive;
        widget.opacity = sensitive ? 0.9 : 0.45;
        widget.has_tooltip = sensitive;
        return;
    }

    // Adds user configured font sources (directories) and rejected fonts to our
    // FcConfig so that we can render fonts which are not actually "installed".
    public bool load_user_font_resources (Reject? reject = null) {
        clear_application_fonts();
        bool res = true;
        var legacy_font_dir = Path.build_filename(Environment.get_home_dir(), ".fonts");
        if (!add_application_font_directory(legacy_font_dir)) {
            res = false;
            warning("Failed to add legacy user font directory to configuration!");
        }
        if (!add_application_font_directory(get_user_font_directory())) {
            res = false;
            critical("Failed to add default user font directory to configuration!");
        }
        UserSourceModel? source_model = new UserSourceModel();
        source_model.reload();
        source_model.items.foreach((source) => {
            if (source.available && !add_application_font_directory(source.path)) {
                res = false;
                warning("Failed to register user font source! : %s", source.path);
            }
            debug("Loaded user font resource : %s", source.path);
        });
        source_model = null;
        StringSet? files = null;
        if (reject == null) {
            var _reject = new Reject();
            _reject.load();
            try {
                Database db = DatabaseProxy.get_default_db();
                files = _reject.get_rejected_files(db);
            } catch (Error e) {
                warning(e.message);
            }
        } else {
            files = new StringSet();
            foreach (string family in reject)
                files.add_all(get_files_for_family(family));
        }
        if (files != null) {
            foreach (string path in files) {
                add_application_font(path);
                debug("Added rejected path to application configuration :%s", path);
            }
        }
        return res;
    }

    Reject? have_missing_rejects () {
        var res = new Reject();
        res.load();
        try {
            Database db = DatabaseProxy.get_default_db();
            StringSet? files = res.get_rejected_files(db);
            // This means files were either removed outside of the application,
            // the database was deleted or database version was bumped.
            if (files.size == res.size)
                res = null;
        } catch (Error e) {
            warning(e.message);
        }
        return res;
    }

    Json.Array get_sorted_font_list (Pango.Context? ctx) {
        Reject? reject = have_missing_rejects();
        if (reject != null) {
            // If there is a discrepancy between families listed as disabled
            // and families in the database delete the configuration so that
            // Fontconfig returns a full list.
            File config = File.new_for_path(reject.get_filepath());
            try {
                config.delete();
            } catch (Error e) {
                warning(e.message);
            }
        }
        update_font_configuration();
        if (load_user_font_resources(reject)) {
            if (ctx != null)
                clear_pango_cache(ctx);
        } else {
            critical("Failed to load user font resources, will be unable to render properly");
        }
        var fonts = get_available_fonts(null);
        var sorted_fonts = sort_json_font_listing(fonts);
        if (reject != null)
            reject.save();
        return sorted_fonts;
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

    public async void copy_files (StringSet filelist, File destination, bool show_progress) {
        assert(destination.query_file_type(FileQueryInfoFlags.NONE) == FileType.DIRECTORY);
        uint total = filelist.size;
        uint processed = 0;
        ProgressDialog? progress = null;
        if (show_progress) {
            Gtk.Window? parent = get_default_application().main_window;
            progress = new ProgressDialog(parent, _("Copying files…"));
            progress.present();
        }
        foreach (string filepath in filelist) {
            File original = File.new_for_path(filepath);
            string filename = original.get_basename();
            string path = Path.build_filename(destination.get_path(), filename);
            File copy = File.new_for_path(path);
            try {
                FileCopyFlags flags = FileCopyFlags.OVERWRITE |
                                      FileCopyFlags.ALL_METADATA |
                                      FileCopyFlags.TARGET_DEFAULT_PERMS;
                original.copy(copy, flags);
            } catch (Error e) {
                critical(e.message);
            }
            Idle.add(copy_files.callback);
            if (progress != null) {
                var progress_data = new ProgressData(filename, ++processed, total);
                progress.update(progress_data);
            }
            yield;
        }
        if (progress != null) {
            progress.destroy();
        }
        progress = null;
        return;
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

    public int64 get_filelist_file_size (StringSet filelist) {
        int64 total = 0;
        foreach (string path in filelist) {
            try {
                File file = File.new_for_path(path);
                FileInfo info = file.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
                total += info.get_size();
            } catch (Error e) {
                critical(e.message);
            }
        }
        return total;
    }

    public StringSet? get_command_line_input (VariantDict options) {
        Variant argv = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
        if (argv == null)
            return null;
        (unowned string) [] list = argv.get_bytestring_array();
        if (list.length == 0)
            return null;
        var input = new StringSet();
        foreach (var str in list)
            input.add(str);
        return input;
    }

}

