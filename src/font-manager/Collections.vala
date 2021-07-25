/* Collections.vala
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

    const string DEFAULT_COLLECTION_NAME = _("Enter Collection Name");

    public class Collections : Cacheable {

        public GLib.HashTable <string, Collection> entries { get; set; }

        public static string get_cache_file () {
            string dirpath = get_package_config_directory();
            string filepath = Path.build_filename(dirpath, "Collections.json");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        public Collections () {
            entries = new GLib.HashTable <string, Collection> (str_hash, str_equal);
        }

        public void update () {
            Reject? reject = get_default_application().reject;
            return_if_fail(reject != null);
            foreach (Collection collection in entries.get_values())
                collection.set_active_from_fonts(reject);
            return;
        }

        public void rename_collection (Collection collection, string new_name) {
            string old_name = collection.name;
            collection.name = new_name;
            if (this.entries.contains(old_name)) {
                this.entries.set(collection.name, collection);
                this.entries.remove(old_name);
            }
            return;
        }

        public StringSet get_full_contents () {
            var full_contents = new StringSet ();
            foreach (var entry in entries.get_values())
                full_contents.add_all(entry.get_full_contents());
            return full_contents;
        }

        public override bool deserialize_property (string prop_name,
                                                        out Value val,
                                                        ParamSpec pspec,
                                                        Json.Node node) {
            if (pspec.value_type == typeof(GLib.HashTable)) {
                var collections = new GLib.HashTable <string, Collection> (str_hash, str_equal);
                node.get_object().foreach_member((obj, name, node) => {
                    Object collection = Json.gobject_deserialize(typeof(Collection), node);
                    collections[name] = collection as Collection;
                });
                val = collections;
                return true;
            } else
                return base.deserialize_property(prop_name, out val, pspec, node);
        }

        public override Json.Node serialize_property (string prop_name,
                                                            Value val,
                                                            ParamSpec pspec) {
            if (pspec.value_type == typeof(GLib.HashTable)) {
                var node = new Json.Node(Json.NodeType.OBJECT);
                var obj = new Json.Object();
                foreach (var collection in entries.get_values())
                    obj.set_member(collection.name.escape(""), Json.gobject_serialize(collection));
                node.set_object(obj);
                return node;
            } else
                return base.serialize_property(prop_name, val, pspec);
        }

        public bool save () {
            if (!write_json_file(Json.gobject_serialize(this), get_cache_file(), true)) {
                warning("Failed to save collection cache file.");
                return false;
            }
            return true;
        }

        public static Collections load () {
            Collections? collections = null;
            string cache = Collections.get_cache_file();
            Json.Node? root = load_json_file(cache);
            if (root != null)
                collections = (Collections) Json.gobject_deserialize(typeof(Collections), root);
            return collections != null ? collections : new Collections();
        }

    }

    public class CollectionModel : Gtk.TreeStore {

        public Collections collections {
            get {
                return _collections;
            }
            set {
                _collections = value;
                this.update();
            }
        }

        Collections _collections;

        construct {
            set_column_types({typeof(Object), typeof(string), typeof(string)});
            collections = Collections.load();
        }

        public void update () {
            clear();
            if (_collections == null || _collections.entries.get_values() == null)
                return;
            GLib.List <weak Collection> sorted = _collections.entries.get_values();
            sorted.sort_with_data((CompareDataFunc) filter_sort);
            foreach (Collection collection in sorted) {
                Gtk.TreeIter iter;
                this.append(out iter, null);
                this.set(iter, 0, collection, 2, collection.comment, -1);
                insert_children(collection.children, iter);
            }
            return;
        }

        public void update_group_index () {
            if (_collections == null || _collections.entries.get_values() == null)
                return;
            foreach (Collection collection in _collections.entries.get_values())
                collection.clear_children();
            /* (model, path, iter) */
            this.foreach((m, p, i) => {
                /* Update index */
                Value child;
                m.get_value(i, CollectionColumn.OBJECT, out child);
                var collection = child as Collection;
                /* This means we got an empty row, ignore this call */
                if (collection == null) {
                    child.unset();
                    return false;
                }
                int depth = p.get_depth();
                int []? indices = p.get_indices();
                /* XXX : VALA BUG? : avoid possible dereference of null pointer */
                assert(indices != null);
                collection.index = indices[depth-1];
                /* Bail if this is a root node */
                if (depth <= 1) {
                    /* In case this wasn't a root node before, make it a root node */
                    if (!(_collections.entries.contains(collection.name)))
                        _collections.entries[collection.name] = collection;
                    child.unset();
                    return false;
                }
                /* Have a child node, need to add it to its parent */
                Value parent;
                Gtk.TreeIter piter;
                m.iter_parent(out piter, i);
                m.get_value(piter, CollectionColumn.OBJECT, out parent);
                ((Collection) parent).children.add(collection);
                /* In case this used to be a root node */
                if (_collections.entries.contains(collection.name))
                    _collections.entries.remove(collection.name);
                parent.unset();
                child.unset();
                return false;
            });
        }

        void insert_children (GenericArray <Collection> children, Gtk.TreeIter parent) {
            children.sort_with_data((CompareDataFunc) filter_sort);
            children.foreach((child) => {
                Gtk.TreeIter _iter;
                this.append(out _iter, parent);
                this.set(_iter, 0, child, 1, child.comment, -1);
                insert_children(child.children, _iter);
            });
        }

    }

    public enum CollectionColumn {
        OBJECT,
        NAME,
        COMMENT,
        N_COLUMNS
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-collection-rename-popover.ui")]
    internal class CollectionRenamePopover : Gtk.Popover {

        public signal void renamed (string new_name);

        [GtkChild] public unowned Gtk.Entry name_entry { get; }
        [GtkChild] public unowned Gtk.Button rename_button { get; }

        public override void constructed () {
            rename_button.clicked.connect(() => {
                renamed(name_entry.get_text().strip());
                Idle.add(() => { popdown(); return GLib.Source.REMOVE; });
            });
            key_press_event.connect((ev) => {
                if (ev.keyval == Gdk.Key.KP_Enter || ev.keyval == Gdk.Key.Return) {
                    renamed(name_entry.get_text().strip());
                    Idle.add(() => { popdown(); return GLib.Source.REMOVE; });
                    return Gdk.EVENT_STOP;
                }
                return Gdk.EVENT_PROPAGATE;
            });
            base.constructed();
            return;
        }

    }

    public class CollectionTree : BaseTreeView {

        public signal void changed ();
        public signal void selection_changed (Collection? group);

        public string selected_iter { get; protected set; default = "-1"; }
        public Collection? selected_filter { get; protected set; default = null; }

        public new CollectionModel? model {
            get {
                return ((CollectionModel) base.get_model());
            }
            set {
                base.set_model(value);
                select_first_row();
                value.row_deleted.connect((t, p) => { update_and_cache_collections(); });
                value.row_inserted.connect((t, p, i) => { update_and_cache_collections(); });
                value.rows_reordered.connect((t, p, i) => { update_and_cache_collections(); });
                value.row_changed.connect((t, p, i) => { update_and_cache_collections(); });
                update_and_cache_collections();
            }
        }

        Gtk.Menu context_menu;
        Gtk.MenuItem menu_header;
        Gtk.TreeIter _selected_iter_;
        Gtk.CellRendererText renderer;

        CollectionRenamePopover? rename_popover = null;

        construct {
            name = "FontManagerCollectionTree";
            expand = true;
            level_indentation = 12;
            headers_visible = false;
            reorderable = true;
            show_expanders = false;
            renderer = new Gtk.CellRendererText();
            var count_renderer = new CellRendererCount();
            var toggle = new Gtk.CellRendererToggle();
            toggle.toggled.connect(on_collection_toggled);
            renderer.set_property("ellipsize", Pango.EllipsizeMode.END);
            renderer.set_property("ellipsize-set", true);
            renderer.editable = true;
            insert_column_with_data_func(0, "", toggle, toggle_cell_data_func);
            insert_column_with_data_func(1, "", renderer, text_cell_data_func);
            insert_column_with_data_func(2, "", count_renderer, count_cell_data_func);
            for (int i = 0; i < CollectionColumn.N_COLUMNS; i++)
                get_column(i).expand = (i == CollectionColumn.NAME);
            set_tooltip_column(CollectionColumn.COMMENT);
            context_menu = get_context_menu();
            connect_signals();
            model = new CollectionModel();
        }

        void connect_signals () {
            get_selection().changed.connect(on_selection_changed);
            renderer.edited.connect(on_edited);
            Reject? reject = get_default_application().reject;
            return_if_fail(reject != null);
            reject.changed.connect(() => {
                model.collections.update();
                get_column(0).queue_resize();
            });
            return;
        }

        public void select_first_row () {
            if (model == null)
                return;
            Gtk.TreePath path = new Gtk.TreePath.first();
            Gtk.TreeSelection selection = get_selection();
            selection.unselect_all();
            selection.select_path(path);
            if (selection.path_is_selected(path))
                scroll_to_cell(path, null, true, 0.5f, 0.5f);
            return;
        }

        public void on_add_collection (StringSet? families = null) {
            string default_collection_name = DEFAULT_COLLECTION_NAME;
            int i = 1;
            while (model.collections.entries.contains(default_collection_name)) {
                default_collection_name = "%s %i".printf(DEFAULT_COLLECTION_NAME, i);
                i++;
            }
            var group = new Collection(default_collection_name, null);
            if (families != null) {
                group.families.add_all(families);
                Reject? reject = get_default_application().reject;
                group.set_active_from_fonts(reject);
            }
            model.collections.entries[default_collection_name] = group;
            Gtk.TreeIter iter;
            model.append(out iter, null);
            model.set(iter, 0, group, 1, group.comment, -1);
            grab_focus();
            set_cursor(model.get_path(iter), get_column(CollectionColumn.NAME), true);
            return;
        }

        public void on_remove_collection ()
        requires (selected_filter != null) {
            if (!model.iter_is_valid(_selected_iter_))
                return;
            var collections = model.collections.entries;
            if (collections.contains(selected_filter.name))
                collections.remove(selected_filter.name);
            ((Gtk.TreeStore) model).remove(ref _selected_iter_);
            changed();
            return;
        }

        public void remove_fonts (StringSet fonts)
        requires (selected_filter != null) {
            selected_filter.families.remove_all(fonts);
            Idle.add(() => {
                model.collections.save();
                return GLib.Source.REMOVE;
            });
            Reject? reject = get_default_application().reject;
            selected_filter.set_active_from_fonts(reject);
            changed();
            return;
        }

        protected override bool show_context_menu (Gdk.EventButton e) {
            context_menu.popup_at_pointer(e);
            return true;
        }

        void copy_to ()
        requires (selected_filter != null) {
            string? target_dir = FileSelector.get_target_directory();
            if (target_dir == null)
                return;
            string destination = Path.build_filename(target_dir, selected_filter.name);
            return_if_fail(DirUtils.create_with_parents(destination, 0755) == 0);
            File tmp = File.new_for_path(destination);
            copy_files.begin(selected_filter.get_filelist(),
                             tmp,
                             true,
                             (obj, res) => {
                                copy_files.end(res);
                             }
            );
            return;
        }

        void compress ()
        requires (selected_filter != null) {
            var file_roller = new ArchiveManager();
            return_if_fail(file_roller.available);
            string temp_dir;
            try {
                temp_dir = DirUtils.make_tmp(TMP_TMPL);
                get_default_application().temp_files.add(temp_dir);
            } catch (Error e) {
                critical(e.message);
                return_if_reached();
            }
            string tmp_path = Path.build_filename(temp_dir, selected_filter.name);
            assert(DirUtils.create_with_parents(tmp_path, 0755) == 0);
            File tmp = File.new_for_path(tmp_path);
            copy_files.begin(selected_filter.get_filelist(), tmp, false, (obj, res) => {
                string? [] filelist = { tmp.get_uri(), null };
                unowned string home = Environment.get_home_dir();
                string destination = File.new_for_path(home).get_uri();
                file_roller.compress(filelist, destination);
            });
            return;
        }

        Gdk.Rectangle get_selected_area () {
            Gdk.Rectangle area;
            Gtk.TreePath path = new Gtk.TreePath.from_string(selected_iter);
            get_cell_area(path, get_column(CollectionColumn.NAME), out area);
            return area;
        }

        void rename ()
        requires (selected_filter != null) {
            if (rename_popover == null) {
                rename_popover = new CollectionRenamePopover();
                rename_popover.set_relative_to(this);
                rename_popover.renamed.connect((new_name) => {
                    if (new_name == "" || new_name == selected_filter.name)
                        return;
                    model.collections.rename_collection(selected_filter, new_name);
                    queue_draw();
                    menu_header.label = new_name;
                    Idle.add(() => {
                        model.collections.save();
                        return GLib.Source.REMOVE;
                    });
                });
            }
            rename_popover.name_entry.set_text(selected_filter.name);
            rename_popover.name_entry.grab_focus();
            rename_popover.set_pointing_to(get_selected_area());
            rename_popover.popup();
            return;
        }

        /* TODO :
         * Implement and group all context menus used in the application so that
         * they're easy to modify/extend in one place.
         */
        Gtk.Menu get_context_menu () {
            /* action_name, display_name, detailed_action_name, accelerator, method */
            MenuEntry [] context_menu_entries = {
                MenuEntry("copy_to", _("Copy to…"), "app.copy_to", null, new MenuCallbackWrapper(copy_to)),
                MenuEntry("compress", _("Compress…"), "app.compress", null, new MenuCallbackWrapper(compress)),
                MenuEntry("rename", _("Rename…"), "app.rename", null, new MenuCallbackWrapper(rename)),
            };
            var popup_menu = new Gtk.Menu();
            menu_header = new Gtk.MenuItem.with_label("");
            menu_header.sensitive = false;
            menu_header.get_style_context().add_class("SensitiveChildLabel");
            menu_header.opacity = 0.8;
            menu_header.show();
            popup_menu.append(menu_header);
            var label = ((Gtk.Bin) menu_header).get_child();
            label.set("hexpand", true, "justify", Gtk.Justification.FILL, "margin", 2, null);
            var separator = new Gtk.SeparatorMenuItem();
            separator.show();
            popup_menu.append(separator);
            foreach (MenuEntry entry in context_menu_entries) {
                var item = new Gtk.MenuItem.with_label(entry.display_name);
                item.activate.connect(() => { entry.method.run(); });
                item.show();
                popup_menu.append(item);
                if (entry.action_name == "compress") {
                    var file_roller = new ArchiveManager();
                    item.set_visible(file_roller.available);
                }
            }
            /* Wayland complains if not set */
            popup_menu.realize.connect(() => {
                Gdk.Window child = popup_menu.get_window();
                child.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU);
                child.set_transient_for(this.get_window());
            });
            return popup_menu;
        }

        void on_edited (Gtk.CellRendererText renderer, string path, string new_text)
        requires (selected_filter != null) {
            string new_name = new_text.strip();
            if (new_name == selected_filter.name || new_name == "" || model.collections.entries.contains(new_name)) {
                return;
            } else if (new_name == DEFAULT_COLLECTION_NAME) {
                grab_focus();
                set_cursor(new Gtk.TreePath.from_string(path), get_column(CollectionColumn.NAME), true);
                return;
            }
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, CollectionColumn.OBJECT, out val);
            var group = (Collection) val.get_object();
            model.collections.rename_collection(group, new_name);
            menu_header.label = new_name;
            val.unset();
            Idle.add(() => {
                model.collections.save();
                return GLib.Source.REMOVE;
            });
            return;
        }

        void on_collection_toggled (string path) {
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, CollectionColumn.OBJECT, out val);
            var group = (Collection) val.get_object();
            group.active = !(group.active);
            Reject? reject = get_default_application().reject;
            group.update(reject);
            group.set_active_from_fonts(reject);
            val.unset();
            changed();
            Idle.add(() => {
                model.collections.save();
                return GLib.Source.REMOVE;
            });
            return;
        }

        void on_selection_changed (Gtk.TreeSelection selection) {
            Gtk.TreeIter iter;
            Gtk.TreeModel model;
            GLib.Value val;
            selected_filter = null;
            selected_iter = "-1";
            if (!selection.get_selected(out model, out iter)) {
                selection_changed(null);
                return;
            }
            Gtk.TreePath path = model.get_path(iter);
            if (path.get_depth() < 2) {
                collapse_all();
                get_column(0).queue_resize();
            }
            expand_to_path(path);
            model.get_value(iter, 0, out val);
            selected_filter = ((Collection) val);
            menu_header.label = ((Collection) val).name;
            _selected_iter_ = iter;
            selected_iter = model.get_string_from_iter(iter);
            val.unset();
            selection_changed(selected_filter);
            return;
        }

        void text_cell_data_func (Gtk.TreeViewColumn layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, CollectionColumn.OBJECT, out val);
            var obj = (Collection) val.get_object();
            cell.set_property("text", obj.name);
            val.unset();
            return;
        }

        void toggle_cell_data_func (Gtk.TreeViewColumn layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, CollectionColumn.OBJECT, out val);
            var obj = (Collection) val.get_object();
            cell.set_property("active", obj.active);
            val.unset();
            return;
        }

        void count_cell_data_func (Gtk.TreeViewColumn layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, CollectionColumn.OBJECT, out val);
            var obj = (Collection) val.get_object();
            cell.set_property("count", obj.size);
            val.unset();
            return;
        }

        void update_and_cache_collections () {
            model.update_group_index();
            Idle.add(() => {
                model.collections.save();
                return GLib.Source.REMOVE;
            });
            return;
        }

    }

}
