/* UserSources.vala
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

    public class UserSourceModel : Object, ListModel {

        public GenericArray <Source> items { get; private set; default = new GenericArray <Source> (); }

        Directories sources;

        construct {
            reload();
        }

        public void clear () {
            uint n_items = get_n_items();
            items = null;
            items_changed(0, n_items, 0);
            items = new GenericArray <Source> ();
            return;
        }

        public void reload () {
            clear();
            sources = new Directories() {
                config_dir = get_package_config_directory(),
                target_element = "source",
                target_file = "Sources.xml"
            };
            sources.load();
            var active = new Directories();
            active.load();
            foreach (string path in sources) {
                if (path == null)
                    continue;
                var item = new Source(File.new_for_path(path));
                item.active = (item.path in active);
                add_item(item);
            }
            items.sort((a, b) => { return natural_sort(a.name, b.name); });
            items_changed.connect_after(() => {
                // XXX : FIXME : Timing issue at startup
                Idle.add(() => {
                    sources.save();
                    save_active_items();
                    return GLib.Source.REMOVE;
                });
            });
            return;
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
            sources.add(item.path);
            items.add(item);
            uint position = get_n_items() - 1;
            items_changed(position, 0, 1);
            item.changed.connect(() => { items_changed(position, 0, 0); });
            item.notify["active"].connect(() => { items_changed(position, 0, 0); });
            return;
        }

        // FIXME : We need to disable remove button until database purge is complete.
        public void remove_item (uint position) {
            var item = items[position];
            sources.remove(item.path);
            items.remove(item);
            items_changed(position, 1, 0);
            GLib.Task task = new GLib.Task(this, null, on_database_purged);
            task.set_task_data(item.path, null);
            task.run_in_thread(purge_database_entries);
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

        // Error reporting happens in TaskThreadFunc
        // This only exists to silence warning about null callback when creating Task
        void on_database_purged (Object? unused_object, Task unused_task) {}

        static void purge_database_entries (Task task,
                                            Object unused_source,
                                            void* data,
                                            Cancellable? cancellable = null) {
            string path = (string) data;
            try {
                Database db = DatabaseProxy.get_default_db();
                string [] tables = { "Fonts", "Metadata", "Orthography", "Panose" };
                foreach (string table in tables) {
                    db.execute_query("DELETE FROM %s WHERE filepath LIKE \"%%s%\"".printf(table, path));
                    db.get_cursor().step();
                    db.end_query();
                }
                db.vacuum();
            } catch (Error e) {
                warning("Failed to remove database entries for %s : %s", path, e.message);
            }
            return;
        }

    }

    public class UserSourceList : PreferenceList {

        bool refresh_required = false;
        const string help_text =

_("""Fonts in any folders listed here will be available within the application.

They will not be visible to other applications until the source is actually enabled.""");

        public UserSourceModel model { get; set; }

        public UserSourceList () {
            widget_set_name(this, "FontManagerUserSourceList");
            controls.visible = true;
            notify["model"].connect(() => { list.bind_model(model, row_from_item); });
            model = new UserSourceModel();
            string w1 = _("Font Sources");
            string w2 = _("Easily add or preview fonts without actually installing them.");
            string w3 = _("To add a new source simply drag a folder onto this area or click the add button in the toolbar.");
            var place_holder = new PlaceHolder(w1, w2, w3, "folder-symbolic");
            list.set_placeholder(place_holder);
            // ??? : Possible issue for translators?
            // We're appending one translated string to another here.
            controls.append(inline_help_widget("%s\n\n%s".printf(help_text, FONTCONFIG_DISCLAIMER)));
            var drop_target = new Gtk.DropTarget(typeof(Gdk.FileList), Gdk.DragAction.COPY);
            add_controller(drop_target);
            drop_target.drop.connect(on_drag_data_received);
            model.items_changed.connect(() => { refresh_required = true; });
        }

        void on_file_selections_ready (Object? obj, AsyncResult res) {
            return_if_fail(obj != null);
            try {
                var dialog = (Gtk.FileDialog) obj;
                ListModel files = dialog.select_multiple_folders.end(res);
                for (uint i = 0; i < files.get_n_items(); i++) {
                    var file = (File) files.get_item(i);
                    var source = new Source(file);
                    model.add_item(source);
                }
            } catch (Error e) {
                if (e.code == Gtk.DialogError.FAILED)
                    warning(e.message);
                else
                    debug("UserSources.on_file_selections_ready : %s", e.message);
            }
            return;
        }

        protected override void on_add_selected () {
            var dialog = FileSelector.get_selected_sources();
            dialog.select_multiple_folders.begin(get_parent_window(this),
                                                 null,
                                                 on_file_selections_ready);
            return;
        }

        protected override void on_remove_selected () {
            if (list.get_selected_row() == null)
                return;
            uint position = list.get_selected_row().get_index();
            model.remove_item(position);
            while (position > 0 && position >= model.get_n_items()) { position--; }
            list.select_row(list.get_row_at_index((int) position));
            return;
        }

        protected override void on_map () {
            model.reload();
            base.on_map();
            return;
        }

        protected override void on_unmap () {
            Idle.add(() => {
                get_default_application().reload();
                return GLib.Source.REMOVE;
            });
            return;
        }

        Gtk.Widget row_from_item (Object item) {
            Source source = (Source) item;
            var control = new Gtk.Switch();
            var row = new PreferenceRow(source.name, source.path, source.icon_name, control);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            source.bind_property("icon-name", row, "icon-name", flags);
            source.bind_property("name", row, "title", flags);
            source.bind_property("active", control, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            source.bind_property("available", control, "sensitive", flags);
            source.notify["available"].connect(() => {
                row.subtitle = source.get_status_message();
            });
            return row;
        }

        bool on_drag_data_received (Value value, double x, double y) {
            if (value.holds(typeof(Gdk.FileList))) {
                GLib.SList <File>* filelist = value.get_boxed();
                for (GLib.SList <File>* files = filelist; files != null; files = files->next) {
                    File* file = files->data;
                    var source = new Source(file);
                    model.add_item(source);
                }
            }
            return true;
        }

    }

}


