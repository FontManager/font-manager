/* UserActions.vala
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

namespace FontManager {

    public class UserAction : Cacheable {

        public string action_icon { get; set; default = "system-run-symbolic"; }
        public string action_name { get; set; default = ""; }
        public string comment { get; set; default = ""; }
        public string executable { get; set; default = ""; }
        public string arguments { get; set; default = ""; }

        construct {
            notify["executable"].connect(() => {
                /* Try to retrieve application details, if available. */
                var exec = executable.contains("/") ? Path.get_basename(executable) : executable;
                var desktop_files = DesktopAppInfo.search(exec);
                if (desktop_files != null && desktop_files[0] != null) {
                    var app_info = new DesktopAppInfo(desktop_files[0][0]);
                    if (app_info.get_executable() == exec) {
                        action_icon = app_info.get_icon().to_string();
                        if (action_name == "")
                            action_name = app_info.get_display_name();
                        if (comment == "")
                            comment = app_info.get_description();
                    } else {
                        action_icon = "system-run-symbolic";
                    }
                    app_info = null;
                }
            });
            notify.connect(() => { changed(); });
        }

        public void run (Font? font) {
            StringBuilder builder = new StringBuilder();
            if (exists(executable))
                builder.append(executable);
            else
                builder.append(Environment.find_program_in_path(executable));
            builder.append(" ");
            string args = arguments;
            if (font.is_valid()) {
                string filepath = Shell.quote(font.filepath);
                args.replace("FILEPATH", filepath).replace("FAMILY", font.family).replace("STYLE", font.style);
                builder.append(args);
                if (!args.contains(font.filepath)) {
                    builder.append(" ");
                    builder.append(filepath);
                }
            } else {
                builder.append(args);
            }
            try {
                Process.spawn_command_line_async(builder.str);
            } catch (Error e) {
                critical(e.message);
            }
            return;
        }

    }

    public class UserActionModel : Object, ListModel {

        public GenericArray <UserAction> items { get; private set; }

        construct {
            items = new GenericArray <UserAction> ();
            load();
            items_changed.connect(() => { save(); });
        }

        public Type get_item_type () {
            return typeof(UserAction);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position) {
            return items[position];
        }

        public uint size {
            get {
                return get_n_items();
            }
        }

        public new UserAction get (uint index) {
            assert(index < size);
            return ((UserAction) get_item(index));
        }

        public void add_item (UserAction item) {
            items.add(item);
            uint position = size - 1;
            items_changed(position, 0, 1);
            item.changed.connect(() => { items_changed(position, 0, 0); });
            return;
        }

        public void remove_item (uint position) {
            items.remove_index(position);
            items_changed(position, 1, 0);
            return;
        }

        public static string get_cache_file () {
            string dirpath = get_package_config_directory();
            string filepath = Path.build_filename(dirpath, "Actions.json");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        public void load () {
            Json.Node? node = load_json_file(get_cache_file());
            if (node != null) {
                node.get_array().foreach_element(
                    (arr, index, node) => {
                        var item = Json.gobject_deserialize(typeof(UserAction), node);
                        add_item((UserAction) item);
                    }
                );
            }
            return;
        }

        public void save () {
            Json.Node node = new Json.Node(Json.NodeType.ARRAY);
            Json.Array array = new Json.Array.sized(size);
            items.foreach((item) => {
                var item_node = Json.gobject_serialize(item);
                array.add_object_element(item_node.get_object());
            });
            node.set_array(array);
            write_json_file(node, get_cache_file(), true);
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-user-action-row.ui")]
    public class UserActionRow : Gtk.Grid {

        [GtkChild] unowned Gtk.Image action_icon;
        [GtkChild] unowned Gtk.Entry action_name;
        [GtkChild] unowned Gtk.Entry comment;
        [GtkChild] unowned Gtk.Entry executable;
        [GtkChild] unowned Gtk.Entry arguments;

        public static UserActionRow from_item (Object item) {
            UserAction action = ((UserAction) item);
            UserActionRow row = new UserActionRow();
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            action.bind_property("action_icon", row.action_icon, "icon-name", flags);
            action.bind_property("action_name", row.action_name, "text", flags);
            action.bind_property("comment", row.comment, "text", flags);
            action.bind_property("executable", row.executable, "text", flags);
            action.bind_property("arguments", row.arguments, "text", flags);
            return row;
        }

        [GtkCallback]
        void on_executable_icon_press (Gtk.EntryIconPosition position, Gdk.Event event) {
            var bin = FileSelector.get_executable();
            executable.set_text(bin != null ? bin : "");
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-user-action-list.ui")]
    public class UserActionList : Gtk.Box {

        const string help_text =

_("""Actions defined here will be added to the font list context menu.

By default the filepath for the selected font will be appended to the end of the argument list.
To control where the filepath is inserted use FILEPATH as a placeholder.
If FAMILY or STYLE are found in the argument list they will also be replaced.""");

        [GtkChild] unowned Gtk.ListBox list;
        [GtkChild] unowned BaseControls controls;

        InlineHelp help;

        public UserActionModel model { get; set; }

        public UserActionList () {
            notify["model"].connect(() => { list.bind_model(model, UserActionRow.from_item); });
            model = new UserActionModel();
            var place_holder = new PlaceHolder(_("User Actions"), null, _("Custom context menu entries"), "open-menu-symbolic");
            list.set_placeholder(place_holder);
            set_control_sensitivity(controls.remove_button, false);
            help = new InlineHelp();
            help.margin_start = help.margin_end = 2;
            help.message.set_text(help_text);
            ((Gtk.Image) help.get_child()).set_pixel_size(22);
            controls.box.pack_end(help, false, false, 0);
            controls.add_selected.connect(() => {
                model.add_item(new UserAction());
            });
            controls.remove_selected.connect(() => {
                if (list.get_selected_row() == null)
                    return;
                uint position = list.get_selected_row().get_index();
                model.remove_item(position);
                while (position > 0 && position >= model.get_n_items()) { position--; }
                list.select_row(list.get_row_at_index((int) position));
            });
            place_holder.map.connect(() => {
                controls.add_button.set_relief(Gtk.ReliefStyle.NORMAL);
                controls.add_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            place_holder.unmap.connect(() => {
                controls.add_button.set_relief(Gtk.ReliefStyle.NONE);
                controls.add_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            place_holder.show();
        }

        [GtkCallback]
        void on_list_row_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            set_control_sensitivity(controls.remove_button, row != null);
            return;
        }

    }

}
