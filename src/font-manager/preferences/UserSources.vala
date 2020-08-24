/* UserSources.vala
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

    public class UserSourceModel : Directories, ListModel {

        public List <Source>? items = null;

        construct {
            config_dir = get_package_config_directory();
            target_element = "source";
            target_file = "Sources.xml";
            load();
            foreach (var path in this)
                add_item(new Source(File.new_for_path(path)));
            items_changed.connect(() => {
                Idle.add(() => { save(); save_active_items(); return false; });
            });
        }

        public Type get_item_type () {
            return typeof(Source);
        }

        public uint get_n_items () {
            return items != null ? items.length() : 0;
        }

        public Object? get_item (uint position) {
            return items.nth_data(position);
        }

        public void add_items (Source [] _items) {
            uint start = items.length();
            foreach (Source item in _items) {
                add(item.path);
                items.append(item);
                uint position = items.length() - 1;
                item.changed.connect(() => { items_changed(position, 0, 0); });
                item.notify["active"].connect(() => { items_changed(position, 0, 0); });
            }
            uint end = items.length();
            items_changed(start, 0, end - start);
            return;
        }

        public void add_item (Source item) {
            add(item.path);
            items.append(item);
            uint position = items.length() - 1;
            items_changed(position, 0, 1);
            item.changed.connect(() => { items_changed(position, 0, 0); });
            item.notify["active"].connect(() => { items_changed(position, 0, 0); });
            return;
        }

        public void remove_item (uint position) {
            var item = items.nth_data(position);
            remove(item.path);
            items.remove(item);
            items_changed(position, 1, 0);
            Idle.add(() => {
                purge_database_entries.begin(item.path, (obj, res) => {
                    purge_database_entries.end(res);
                });
                return false;
            });
            return;
        }

        void save_active_items () {
            var active = new Directories();
            foreach (var item in items)
                if (item.active)
                    active.add(item.path);
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

        [GtkChild] Gtk.Image icon;
        [GtkChild] Gtk.Label title;
        [GtkChild] Gtk.Label description;
        [GtkChild] Gtk.Switch active;

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

        const string help_text =

_("""Fonts in any folders listed here will be available within the application.

They will not be visible to other applications until the source is actually enabled.

Note that not all environments/applications will honor these settings.""");

        [GtkChild] Gtk.ListBox list;
        [GtkChild] BaseControls controls;

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
            controls.remove_button.set_visible(false);
            help = new InlineHelp();
            help.margin_start = help.margin_end = 2;
            help.message.set_text(help_text);
            ((Gtk.Image) help.get_child()).set_pixel_size(22);
            controls.box.pack_end(help, false, false, 0);
            controls.add_selected.connect(() => {
                Source [] sources = {};
                foreach (var uri in FileSelector.get_selected_sources())
                    sources += new Source(File.new_for_uri(uri));
                model.add_items(sources);
            });
            controls.remove_selected.connect(() => {
                uint position = list.get_selected_row().get_index();
                model.remove_item(position);
                uint max = model.get_n_items() - 1;
                while (position > max)
                    position--;
                list.select_row(list.get_row_at_index((int) position));
            });
            list.row_selected.connect((row) => {
                controls.remove_button.set_visible(row != null);
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

        public override void drag_data_received (Gdk.DragContext context,
                                                 int x,
                                                 int y,
                                                 Gtk.SelectionData selection_data,
                                                 uint info,
                                                 uint time) {
            if (info == DragTargetType.EXTERNAL) {
                Source [] sources = {};
                foreach (var uri in selection_data.get_uris())
                    sources += new Source(File.new_for_uri(uri));
                model.add_items(sources);
            } else {
                warning("Ignoring unsupported drag target.");
            }
            return;
        }

    }

}
