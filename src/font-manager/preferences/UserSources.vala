/* UserSources.vala
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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

    public class UserSourceModel : Directories, ListModel {

        public GenericArray <Source> items { get; private set; }

        construct {
            config_dir = get_package_config_directory();
            target_element = "source";
            target_file = "Sources.xml";
            load();
            items = new GenericArray <Source> ();
            var _items = new GenericArray<Source> ();
            foreach (var path in this)
                _items.add(new Source(File.new_for_path(path)));
            _items.sort((a, b) => { return natural_sort(a.name, b.name); });
            _items.foreach((item) => { add_item(item); });
            items_changed.connect(() => {
                Idle.add(() => { save(); save_active_items(); return GLib.Source.REMOVE; });
            });
        }

        public Type get_item_type () {
            return typeof(Source);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position) {
            return items[position];
        }

        public void add_item (Source item) {
            add(item.path);
            items.add(item);
            uint position = get_n_items() - 1;
            items_changed(position, 0, 1);
            item.changed.connect(() => { items_changed(position, 0, 0); });
            item.notify["active"].connect(() => { items_changed(position, 0, 0); });
            return;
        }

        public void remove_item (uint position) {
            var item = items[position];
            remove(item.path);
            items.remove(item);
            items_changed(position, 1, 0);
            Idle.add(() => {
                purge_database_entries.begin(item.path, (obj, res) => {
                    purge_database_entries.end(res);
                });
                return GLib.Source.REMOVE;
            });
            return;
        }

        void save_active_items () {
            var active = new Directories();
            items.foreach((item) => {
                if (item.active)
                    active.add(item.path);
            });
            active.save();
            return;
        }

        async void purge_database_entries (string path) {
            DatabaseType [] types = { DatabaseType.FONT, DatabaseType.METADATA, DatabaseType.ORTHOGRAPHY };
            try {
                Database? db = get_database(DatabaseType.BASE);
                foreach (var type in types) {
                    var name = Database.get_type_name(type);
                    db.execute_query("DELETE FROM %s WHERE filepath LIKE \"%%s%\"".printf(name, path));
                    db.stmt.step();
                }
                db = null;
                foreach (var type in types) {
                    db = get_database(type);
                    db.execute_query("VACUUM");
                    db.stmt.step();
                    Idle.add(purge_database_entries.callback);
                    yield;
                }
            } catch (DatabaseError e) {
                if (e.code != 1)
                    warning(e.message);
            }
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-user-source-row.ui")]
    public class UserSourceRow : Gtk.Box {

        [GtkChild] unowned Gtk.Image icon;
        [GtkChild] unowned Gtk.Label title;
        [GtkChild] unowned Gtk.Label description;
        [GtkChild] unowned Gtk.Switch active;

        public static UserSourceRow from_item (Object item) {
            Source source = (Source) item;
            UserSourceRow row = new UserSourceRow();
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            source.bind_property("icon-name", row.icon, "icon-name", flags);
            source.bind_property("name", row.title, "label", flags);
            source.bind_property("active", row.active, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            source.bind_property("available", row.active, "sensitive", flags);
            row.description.set_text(source.get_status_message());
            source.notify["available"].connect(() => {
                row.description.set_text(source.get_status_message());
            });
            return row;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-user-source-list.ui")]
    public class UserSourceList : Gtk.Box {

        bool refresh_required = false;
        const string help_text =

_("""Fonts in any folders listed here will be available within the application.

They will not be visible to other applications until the source is actually enabled.

Note that not all environments/applications will honor these settings.""");

        [GtkChild] unowned Gtk.ListBox list;
        [GtkChild] unowned BaseControls controls;

        InlineHelp help;

        public UserSourceModel model { get; set; }

        public UserSourceList () {
            notify["model"].connect(() => { list.bind_model(model, UserSourceRow.from_item); });
            model = new UserSourceModel();
            string w1 = _("Font Sources");
            string w2 = _("Easily add or preview fonts without actually installing them.");
            string w3 = _("To add a new source simply drag a folder onto this area or click the add button in the toolbar.");
            var place_holder = new PlaceHolder(w1, w2, w3, "folder-symbolic");
            list.set_placeholder(place_holder);
            set_control_sensitivity(controls.remove_button, false);
            help = new InlineHelp();
            help.margin_start = help.margin_end = 2;
            help.message.set_text(help_text);
            ((Gtk.Image) help.get_child()).set_pixel_size(22);
            controls.box.pack_end(help, false, false, 0);
            controls.add_selected.connect(() => {
                foreach (var uri in FileSelector.get_selected_sources())
                    model.add_item(new Source(File.new_for_uri(uri)));
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
            model.items_changed.connect(() => { refresh_required = true; });
            unmap.connect(() => {
                if (refresh_required) {
                    Idle.add(() => {
                        get_default_application().refresh();
                        refresh_required = false;
                        return GLib.Source.REMOVE;
                    });
                }
            });
        }

        [GtkCallback]
        void on_list_row_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            set_control_sensitivity(controls.remove_button, row != null);
            return;
        }

        public override void drag_data_received (Gdk.DragContext context,
                                                 int x,
                                                 int y,
                                                 Gtk.SelectionData selection_data,
                                                 uint info,
                                                 uint time) {
            if (info == DragTargetType.EXTERNAL) {
                foreach (var uri in selection_data.get_uris())
                    model.add_item(new Source(File.new_for_uri(uri)));
            } else {
                warning("Ignoring unsupported drag target.");
            }
            return;
        }

    }

}
