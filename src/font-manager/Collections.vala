/* Collections.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    public class CollectionListModel : FontListFilterModel {

        public Reject? disabled_families { get; set; default = null; }
        public StringSet? available_families { get; set; default = null; }

        public signal void changed ();

        public CollectionListModel () {
            available_families = list_available_font_families();
            changed.connect(() => { save(); });
        }

        public void update_items () {
            available_families = list_available_font_families();
            foreach (var item in items)
                item.changed();
            return;
        }

        public static string get_cache_file () {
            string dirpath = get_package_config_directory();
            string filepath = Path.build_filename(dirpath, "Collections.json");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        public static ListModel? get_child_model (Object item) {
            var collection = ((Collection) item);
            var child = new CollectionListModel();
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            collection.bind_property("children", child, "items", flags);
            return child;
        }

        public StringSet get_full_contents () {
            var full_contents = new StringSet ();
            foreach (var entry in items.data)
                full_contents.add_all(((Collection) entry).get_full_contents());
            return full_contents;
        }

        public override void add_item (FontListFilter item) {
            base.add_item(item);
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bind_property("available-families", ((Collection) item), "available-families", flags);
            bind_property("disabled-families", ((Collection) item), "disabled-families", flags);
            return;
        }

        void add_from_json_node (Json.Node node) {
            Object collection = Json.gobject_deserialize(typeof(Collection), node);
            add_item((Collection) collection);
            ((Collection) collection).changed.connect(() => { changed(); });
            return;
        }

        public void load () {
            Json.Node? root = load_json_file(get_cache_file());
            if (root == null)
                return;
            Json.NodeType node_type = root.get_node_type();
            if (node_type == Json.NodeType.ARRAY) {
                Json.Array array = root.get_array();
                array.foreach_element((a, i, n) => { add_from_json_node(n); });
            } else if (node_type == Json.NodeType.OBJECT) {
                // For compatibility with previous version
                Json.Object obj = root.get_object();
                assert(obj.has_member("entries"));
                Json.Object entries = obj.get_object_member("entries");
                entries.foreach_member((o, s, n) => { add_from_json_node(n); });
            } else {
                assert_not_reached();
            }
            return;
        }

        public bool save () {
            var node = new Json.Node(Json.NodeType.ARRAY);
            var array = new Json.Array();
            foreach (var collection in items)
                array.add_element(Json.gobject_serialize(collection));
            node.set_array(array);
            return write_json_file(node, get_cache_file(), true);
        }

    }

    public class CollectionListRow : TreeListItemRow {

        public signal void changed ();

        ulong change_handler = 0;
        ulong activate_handler = 0;
        Binding? name_binding = null;
        Binding? state_binding = null;

        construct {
            margin_start = 0;
            item_state.visible = true;
            item_state.active = false;
            item_count.visible = true;
        }

        public override void reset () {
            if (change_handler != 0)
                item.disconnect(change_handler);
            change_handler = 0;
            if (activate_handler != 0)
                item.disconnect(activate_handler);
            activate_handler = 0;
            if (name_binding != null)
                name_binding.unbind();
            name_binding = null;
            if (state_binding != null)
                state_binding.unbind();
            state_binding = null;
            return;
        }

        protected override void on_item_set () {
            if (item == null)
                return;
            var collection = (Collection) item;
            item_icon.visible = collection.icon != null;
            if (item_icon.visible)
                item_icon.set_from_icon_name(collection.icon);
            item_count.set_label(collection.size.to_string());
            change_handler = collection.changed.connect(() => { changed(); });
            activate_handler = item_state.toggled.connect(() => {
                collection.active = item_state.active;
                collection.on_activate();
            });
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            name_binding = collection.bind_property("name", item_label, "label", flags);
            state_binding = collection.bind_property("active", item_state, "active", flags);
            return;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-collection-rename-popover.ui")]
    class CollectionRenamePopover : Gtk.Popover {

        public signal void renamed (string new_name);

        [GtkChild] public unowned Gtk.Entry name_entry { get; }
        [GtkChild] public unowned Gtk.Button rename_button { get; }

        public override void constructed () {
            name_entry.grab_focus();
            set_default_widget(rename_button);
            rename_button.clicked.connect(() => {
                renamed(name_entry.get_text().strip());
                Idle.add(() => { popdown(); return GLib.Source.REMOVE; });
            });
            base.constructed();
            return;
        }

    }

    public class CollectionListView : FilterListView {

        public signal void changed ();

        public Reject? disabled_families { get; set; default = null; }

        uint update_timeout = 0;

        Gtk.Label menu_title;
        Gtk.PopoverMenu context_menu;
        Gdk.Rectangle clicked_area;

        CollectionRenamePopover? rename_popover = null;

        ~ CollectionListView () {
            ((CollectionListModel) model).save();
        }

        static construct {
            var file_roller = new ArchiveManager();
            if (file_roller.available)
                install_action("compress", null, (Gtk.WidgetActionActivateFunc) compress);
            install_action("copy_to", null, (Gtk.WidgetActionActivateFunc) copy_to);
            install_action("rename", null, (Gtk.WidgetActionActivateFunc) rename_selected_collection);
            add_binding_action(Gdk.Key.F2, /* Gdk.ModifierType.NO_MODIFIER_MASK */ 0, "rename", null);
        }

        construct {
            widget_set_name(listview, "FontManagerCollectionListView");
            var collection_model = new CollectionListModel();
            collection_model.load();
            treemodel = new Gtk.TreeListModel(collection_model,
                                              false,
                                              true,
                                              CollectionListModel.get_child_model);
            selection = new Gtk.SingleSelection(treemodel);
            add_drop_target(listview);
            init_context_menu();
            selection_changed.connect(update_context_menu);
            collection_model.changed.connect(() => { changed(); });
            clicked_area = Gdk.Rectangle();
            Gtk.Gesture click = new Gtk.GestureClick() {
                button = Gdk.BUTTON_PRIMARY
            };
            ((Gtk.GestureClick) click).pressed.connect(on_click);
            listview.add_controller(click);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("disabled-families", model, "disabled-families", flags);
        }

        bool update () {
            // Force complete update
            listview.set_model(null);
            listview.set_model(selection);
            update_timeout = 0;
            return GLib.Source.REMOVE;
        }

        public void queue_update () {
            if (update_timeout != 0)
                GLib.Source.remove(update_timeout);
            update_timeout = Timeout.add(333, update);
            return;
        }

        void on_click (int n_press, double x, double y) {
            clicked_area.x = (int) x;
            clicked_area.y = (int) y;
            clicked_area.width = 2;
            clicked_area.height = 2;
            context_menu.set_pointing_to(clicked_area);
            return;
        }

        protected override void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var tree_expander = new Gtk.TreeExpander();
            tree_expander.set_indent_for_icon(false);
            var row = new CollectionListRow();
            row.expander = tree_expander;
            row.selection = selection;
            tree_expander.set_child(row);
            list_item.set_child(tree_expander);
            add_drag_source(row);
            add_drop_target(row);
            return;
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.set_list_row(list_row);
            var row = (CollectionListRow) tree_expander.get_child();
            Object? object = list_row.get_item();
            var collection = (Collection) object;
            collection.depth = (int) list_row.get_depth();
            // Setting item triggers update to row widget
            row.reset();
            row.item = object;
            // Nesting is allowed so we need the entire list refreshed if a
            // single row changes otherwise parent nodes would not update
            row.changed.connect(queue_update);
            return;
        }

        const MenuEntry [] collection_menu_entries = {
            {"copy_to", N_("Copy to…")},
            {"compress", N_("Compress…")},
            {"rename", N_("Rename…")}
        };

        void init_context_menu () {
            var base_menu = new BaseContextMenu(listview);
            context_menu = base_menu.popover;
            menu_title = base_menu.menu_title;
            var menu = base_menu.menu;
            foreach (var entry in collection_menu_entries) {
                var item = new GLib.MenuItem(entry.display_name, entry.action_name);
                menu.append_item(item);
            }
            return;
        }

        void update_context_menu () {
            menu_title.set_label(selected_item.name);
            return;
        }

        protected override void on_show_context_menu (int n_press, double x, double y) {
            if (selected_item == null)
                return;
            context_menu.popup();
            return;
        }

        void on_folder_selection_ready (Object? obj, AsyncResult res) {
            return_if_fail(obj != null);
            try {
                var dialog = (Gtk.FileDialog) obj;
                File target_dir = dialog.select_folder.end(res);
                string destination = Path.build_filename(target_dir.get_path(), selected_item.name);
                return_if_fail(DirUtils.create_with_parents(destination, 0755) == 0);
                File tmp = File.new_for_path(destination);
                copy_files.begin(((Collection) selected_item).get_filelist(),
                                 tmp,
                                 true,
                                 (obj, res) => {
                                    copy_files.end(res);
                                 });
            } catch (Error e) {
                warning(e.message);
            }
            return;
        }

        void compress (Gtk.Widget widget, string? action, Variant? parameter)
        requires (selected_item != null) {
            var file_roller = new ArchiveManager();
            return_if_fail(file_roller.available);
            string temp_dir;
            try {
                temp_dir = DirUtils.make_tmp(TMP_TMPL);
                // XXX: FIXME!
                // get_default_application().temp_files.add(temp_dir);
            } catch (Error e) {
                critical(e.message);
                return_if_reached();
            }
            string tmp_path = Path.build_filename(temp_dir, selected_item.name);
            assert(DirUtils.create_with_parents(tmp_path, 0755) == 0);
            File tmp = File.new_for_path(tmp_path);
            copy_files.begin(((Collection) selected_item).get_filelist(), tmp, false, (obj, res) => {
                copy_files.end(res);
                string? [] filelist = { tmp.get_uri(), null };
                unowned string home = Environment.get_home_dir();
                string destination = File.new_for_path(home).get_uri();
                file_roller.compress(filelist, destination);
            });
            return;
        }

        void copy_to (Gtk.Widget widget, string? action, Variant? parameter)
        requires (selected_item != null) {
            var dialog = FileSelector.get_target_directory();
            dialog.select_folder.begin(get_parent_window(this),
                                       null,
                                       on_folder_selection_ready);
            return;
        }

        public void add_new_collection () {
            collapse_all();
            clicked_area.x = listview.get_width() / 2;
            clicked_area.y = listview.get_height() / 2;
            ((CollectionListModel) model).add_item(new Collection(null, null));
            listview.scroll_to(model.get_n_items() - 1, Gtk.ListScrollFlags.SELECT, null);
            Idle.add(() => {
                rename_selected_collection(listview, null, null);
                return GLib.Source.REMOVE;
            });
            return;
        }

        public void remove_selected_collection () {
            var list_row = (Gtk.TreeListRow) treemodel.get_item(selected_position);
            FontListFilterModel target_model = model;
            Gtk.TreeListRow? parent_row = list_row.get_parent();
            if (parent_row != null)
                target_model = ((FontListFilterModel) parent_row.get_children());
            else
                parent_row = list_row;
            target_model.remove_item(selected_item);
            parent_row.set_expanded((target_model.get_n_items() != 0));
            ((CollectionListModel) model).save();
            // Necessary to update parent row count label
            queue_update();
            return;
        }

        void rename_selected_collection (Gtk.Widget widget, string? action, Variant? parameter)
        requires (selected_item != null) {
            if (rename_popover == null) {
                rename_popover = new CollectionRenamePopover();
                rename_popover.set_parent(listview);
                rename_popover.renamed.connect((new_name) => {
                    if (new_name == "" || new_name == selected_item.name)
                        return;
                    selected_item.name = new_name;
                    selected_item.changed();
                    Idle.add(() => {
                        ((CollectionListModel) model).save();
                        return GLib.Source.REMOVE;
                    });
                });
            }
            rename_popover.name_entry.set_text(selected_item.name);
            rename_popover.set_pointing_to(clicked_area);
            rename_popover.popup();
            rename_popover.name_entry.grab_focus();
            return;
        }

        // BEGIN - COLLECTION DRAG AND DROP SUPPORT

        void add_drop_target (Gtk.Widget widget) {
            Gdk.DragAction actions = Gdk.DragAction.COPY | Gdk.DragAction.MOVE;
            var target = new Gtk.DropTarget(Type.INVALID, actions);
            target.set_gtypes({ typeof(FontListFilter), typeof(GenericArray) });
            widget.add_controller(target);
            target.accept.connect(on_accept_drop);
            target.drop.connect(on_drop);
            return;
        }

        void add_drag_source (CollectionListRow row) {
            var drag_source = new Gtk.DragSource();
            row.add_controller(drag_source);
            drag_source.prepare.connect(on_prepare_drag);
            drag_source.drag_begin.connect(on_drag_begin);
            drag_source.drag_end.connect(on_drag_end);
            drag_source.set_actions(Gdk.DragAction.MOVE);
            return;
        }

        Gdk.ContentProvider on_prepare_drag (Gtk.DragSource source, double x, double y) {
            var row = ((CollectionListRow) source.widget);
            Value selection = Value(typeof(FontListFilter));
            selection.set_object((FontListFilter) row.item);
            return new Gdk.ContentProvider.for_value(selection);
        }

        void on_drag_begin (Gtk.DragSource source, Gdk.Drag drag) {
            var row = ((CollectionListRow) source.widget);
            var drag_icon = new Gtk.Label(row.item_label.label);
            drag_icon.add_css_class("FontManagerListRowDrag");
            var gtk_drag_icon = (Gtk.DragIcon) Gtk.DragIcon.get_for_drag(drag);
            gtk_drag_icon.set_child(drag_icon);
            return;
        }

        Gtk.TreeListRow? get_list_row_for_widget (Gtk.Widget widget) {
            var e_type = typeof(Gtk.TreeExpander);
            var expander = (Gtk.TreeExpander) widget.get_ancestor(e_type);
            return (Gtk.TreeListRow) expander.get_list_row();
        }

        void on_drag_end (Gtk.DragSource source, Gdk.Drag drag, bool delete_data) {
            // Only handle move operations
            if (!delete_data)
                return;
            Gtk.TreeListRow? list_row = get_list_row_for_widget(source.widget);
            return_if_fail(list_row != null);
            FontListFilterModel target_model = model;
            Gtk.TreeListRow? parent_row = list_row.get_parent();
            Collection? dropped_collection = null;
            try {
                var content = drag.content;
                Value val = Value(typeof(FontListFilter));
                content.get_value(ref val);
                dropped_collection = (Collection) val.get_object();
            } catch (Error e) {
                warning(e.message);
                dropped_collection = ((Collection) list_row.item);
            }
            if (parent_row != null)
                target_model = ((FontListFilterModel) parent_row.get_children());
            else
                parent_row = list_row;
            target_model.remove_item(dropped_collection);
            parent_row.set_expanded((target_model.get_n_items() != 0));
            ((CollectionListModel) model).save();
            // Necessary to update parent row count label
            queue_update();
            return;
        }

        bool on_accept_drop (Gtk.DropTarget target, Gdk.Drop drop) {
            var formats = drop.drag.content.formats;
            if (formats.contain_gtype(typeof(GenericArray)))
                return (target.widget is CollectionListRow);
            if (!(formats.contain_gtype(typeof(FontListFilter))))
                return false;
            Collection? dropped_collection = null;
            try {
                var content = drop.drag.content;
                Value? val = Value(typeof(Object));
                content.get_value(ref val);
                Object object = val.get_object();
                dropped_collection = (Collection) object;
            } catch (Error e) {
                warning(e.message);
                return false;
            }
            if (target.widget is CollectionListRow) {
                Gtk.TreeListRow? list_row = get_list_row_for_widget(target.widget);
                return_val_if_fail(list_row != null, false);
                Gtk.TreeListRow? parent_row = list_row.get_parent();
                while (parent_row != null) {
                    Collection? parent = ((Collection) parent_row.item);
                    // Say no to recursive collection practices
                    if (dropped_collection == parent)
                        return false;
                    parent_row = parent_row.get_parent();
                }
                Collection target_collection = (Collection) list_row.item;
                // Reject duplicate drops
                if (target_collection.contains(dropped_collection))
                    return false;
            }
            return (target.widget is CollectionListRow ||
                    target.widget is Gtk.ListView &&
                    target.widget.name == listview.name &&
                    dropped_collection.depth > 0);
        }

        bool on_external_drop (Gtk.DropTarget target, Value val, double x, double y) {
            var objects = (GenericArray <Object>) val;
            Gtk.TreeListRow? list_row = get_list_row_for_widget(target.widget);
            return_val_if_fail(list_row != null, false);
            Collection? collection = ((Collection) list_row.item);
            foreach (var object in objects) {
                if (object is Family)
                    collection.families.add(((Family) object).family);
            }
            ((CollectionListModel) model).save();
            queue_update();
            changed();
            return true;
        }

        bool on_drop (Gtk.DropTarget target, Value val, double x, double y) {
            if (val.holds(typeof(GenericArray)))
                return on_external_drop(target, val, x, y);
            return_val_if_fail(val.holds(typeof(FontListFilter)), false);
            var widget = target.widget;
            var filter = (Collection) val.get_object();
            filter.depth = 0;
            FontListFilterModel? target_model = model;
            if (widget is CollectionListRow) {
                Gtk.TreeListRow? list_row = get_list_row_for_widget(target.widget);
                return_val_if_fail(list_row != null, false);
                Collection? collection = ((Collection) list_row.item);
                return_val_if_fail(collection != null, false);
                if (collection.contains(filter))
                    return false;
                target_model = (FontListFilterModel) list_row.get_children();
                filter.depth = (int) list_row.depth + 1;
            }
            if (target_model == null)
                return false;
            target_model.add_item(filter);
            return true;
        }

        // END - COLLECTION DRAG AND DROP SUPPORT

    }

}

