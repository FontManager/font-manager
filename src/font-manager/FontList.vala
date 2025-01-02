/* FontList.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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

const string search_tip = _("""Case insensitive search of family names.

Start search using %s to filter based on filepath.
Start search using %s to filter based on characters.""");

namespace FontManager {

    public class FontListRow : ListItemRow {

        Binding? binding = null;

        Pango.AttrList? attrs = null;

        construct {
            attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            Pango.FontDescription font_desc = Pango.FontDescription.from_string("Sans");
            attrs.insert(new Pango.AttrFontDesc(font_desc));
            item_preview.set_attributes(attrs);
        }

        protected override void reset () {
            if (binding is Binding)
                binding.unref();
            binding = null;
            item_state.set("active", true, "visible", false, "sensitive", true, null);
            item_label.set("label", "", "attributes", null, null);
            item_preview.set("text", "", "visible", false, null);
            item_count.visible = true;
            item_count.set_label("");
            return;
        }

        protected override void on_item_set () {
            reset();
            if (item == null)
                return;
            bool root = item is Family;
            BindingFlags flags = BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL;
            binding = item.bind_property("active", item_state, "active", flags, null, null);
            item_state.set("sensitive", root, "visible", root, null);
            item_count.visible = drag_area.sensitive = drag_handle.visible = root;
            string f; string d; string? p = null;
            item.get("family", out f, "description", out d, "preview-text", out p, null);
            string label = root ? f : p != null ? p : d;
            if (root) {
                var count = (int) ((Family) item).n_variations;
                var count_label = ngettext("%i Variation ", "%i Variations", (ulong) count);
                item_count.set_label(count_label.printf(count));
                item_label.set_text(label);
            } else {
                Pango.FontDescription font_desc = Pango.FontDescription.from_string(d);
                attrs.change(new Pango.AttrFontDesc(font_desc));
                item_preview.set_text(label);
                item_preview.set_visible(true);
            }
            return;
        }

    }

    public class FontListBase : Gtk.Box {

        public signal void activated (uint position);
        public signal void selection_changed (Object? item);

        public Json.Array? available_fonts { get; set; default = null; }
        public Reject? disabled_families { get; set; default = null; }
        public FontListFilter? filter { get; set; default = null; }

        public BaseFontModel? model { get; protected set; default = null; }
        protected Gtk.SelectionModel? selection { get; protected set; default = null; }
        protected Gtk.ListBase? list { get; protected set; default = null; }
        protected unowned Gtk.SearchEntry? search_entry { get; protected set; default = null; }

        // Currently selected position
        public uint current_selection { get; protected set; default = 0; }
        // This array contains all currently selected positions
        public GenericArray <uint>? current_selections { get; protected set; default = null; }

        // Currently selected item. This is either the only item selected or the first selection
        // if multiple items are selected, this can be either a Family object or a Font object
        // depending on whether selecting children is allowed in the list
        public Object? selected_item { get; protected set; default = null; }
        // This array contains all currently selected Family objects
        public GenericArray <Object>? selected_items { get; protected set; default = null; }
        // This array contains all currently selected Font objects
        public GenericArray <Object>? selected_children { get; protected set; default = null; }

        uint search_timeout = 0;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            notify["list"].connect(() => {
                if (list is Gtk.ListView) {
                    ((Gtk.ListView) list).set_factory(get_factory());
                    ((Gtk.ListView) list).activate.connect((position) => { activated(position); });
                } else if (list is Gtk.GridView) {
                    ((Gtk.GridView) list).set_factory(get_factory());
                    ((Gtk.GridView) list).activate.connect((position) => { activated(position); });
                }
            });
            notify["selection"].connect(() => {
                selection.selection_changed.connect(on_selection_changed);
                if (list == null)
                    warning("list must be set before selection");
                return_if_fail(list != null);
                if (list is Gtk.ListView)
                    ((Gtk.ListView) list).set_model(selection);
                else if (list is Gtk.GridView)
                    ((Gtk.GridView) list).set_model(selection);
            });
            notify["model"].connect(() => {
                BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
                bind_property("available-fonts", model, "entries", flags, null, null);
                bind_property("filter", model, "filter", flags, null, null);
            });
            notify["search-entry"].connect(() => {
                search_entry.activate.connect(next_match);
                search_entry.next_match.connect(next_match);
                search_entry.previous_match.connect(previous_match);
                search_entry.search_changed.connect_after(queue_update);
                string hint = search_tip.printf(Path.DIR_SEPARATOR_S, Path.SEARCHPATH_SEPARATOR_S);
                search_entry.set_tooltip_text(hint);
            });
            notify["disabled-families"].connect_after(() => {
                if (disabled_families != null && model != null)
                    disabled_families.changed.connect(() => {
                        model.items_changed(current_selection, 0, 0);
                    });
            });
            notify["filter"].connect_after(() => { select_item(0); });
        }

        public void select_item (uint position) {
            list.activate_action("list.select-item", "(ubb)", position, false, false);
            list.activate_action("list.scroll-to-item", "u", position);
            return;
        }

        public virtual void update (uint position = 0)
        requires (model != null) {
            if (search_entry != null)
                model.search_term = search_entry.text.strip();
            model.update_items();
            select_item(position);
            return;
        }

        bool _queue_update () {
            search_timeout = 0;
            update();
            return GLib.Source.REMOVE;
        }

        // Add slight delay to avoid filtering while search is still changing
        public void queue_update () {
            if (search_timeout != 0)
                GLib.Source.remove(search_timeout);
            search_timeout = Timeout.add_full(GLib.Priority.HIGH_IDLE, 333, _queue_update);
            return;
        }

        protected void next_match (Gtk.SearchEntry entry) {
            select_item(current_selection + 1);
            return;
        }

        protected void previous_match (Gtk.SearchEntry entry) {
            select_item(current_selection - 1);
            return;
        }

        protected virtual void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            return_if_reached();
        }

        protected virtual void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            return_if_reached();
        }

        // NOTE:
        // @position doesn't necessarily point to the actual selection
        // within a TreeListModel, the actual selection lies somewhere
        // between @position + @n_items. The precise location within that
        // range appears to be affected by a variety of factors i.e.
        // previous selection, multiple selections, directional changes, etc.
        protected virtual void on_selection_changed (uint position, uint n_items) {
            current_selection = Gtk.INVALID_LIST_POSITION;
            current_selections = new GenericArray <uint> ();
            // The minimum value present in this bitset accurately points
            // to the first currently selected row in the ListView.
            Gtk.Bitset selections = selection.get_selection();
            current_selection = selections.get_minimum();
            uint val;
            Gtk.BitsetIter iter = Gtk.BitsetIter();
            if (iter.init_first(selections, out val)) {
                current_selections.add(val);
                while (iter.next(out val))
                    current_selections.add(val);
            }
            return;
        }

        Gtk.SignalListItemFactory get_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            return factory;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-font-list-controls.ui")]
    public class FontListControls : Gtk.Box {

        public signal void expander_activated (bool expanded);
        public signal void remove_clicked ();

        [GtkChild] public unowned Gtk.Button remove_button { get; }
        [GtkChild] public unowned Gtk.Expander expander { get; }
        [GtkChild] public unowned Gtk.SearchEntry search { get; }

        [GtkCallback]
        protected void on_remove_clicked () {
            remove_clicked();
            return;
        }

        [GtkCallback]
        protected virtual void on_expander_activated (Gtk.Expander expander) {
            expander_activated(expander.expanded);
            expander.set_tooltip_text(expander.expanded ? _("Collapse all") : _("Expand all"));
            return;
        }

    }

    public class BaseFontListView : FontListBase {

        protected Gtk.TreeListModel treemodel;

        protected FontListControls controls;

        construct {
            controls = new FontListControls();
            list = new Gtk.ListView(null, null) { hexpand = true, vexpand = true };
            var scroll = new Gtk.ScrolledWindow();
            scroll.set_child(list);
            model = new FontModel();
            treemodel = new Gtk.TreeListModel(model,
                                              false,
                                              false,
                                              ((FontModel) model).get_child_model);
            selection = new Gtk.MultiSelection(treemodel);
            append(scroll);
            prepend(controls);
            search_entry = controls.search;
            search_entry.set_key_capture_widget(this);
            controls.expander_activated.connect(on_expander_activated);
            ((Gtk.ListView) list).activate.connect(on_activate);
        }

        public void focus_search_entry () {
            search_entry.grab_focus();
            return;
        }

        protected virtual void on_activate (uint position) {}

        protected virtual void on_expander_activated (bool expanded) {
            treemodel.set_autoexpand(expanded);
            queue_update();
            return;
        }

        protected override void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var tree_expander = new Gtk.TreeExpander();
            var row = new FontListRow();
            tree_expander.set_child(row);
            list_item.set_child(tree_expander);
            return;
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.margin_start = 3;
            tree_expander.set_list_row(list_row);
            var row = (FontListRow) tree_expander.get_child();
            Object? _item = list_row.get_item();
            // Setting item triggers update to row widget
            row.item = _item;
            return;
        }

        protected override void on_selection_changed (uint position, uint n_items) {
            selected_items = new GenericArray <Object> ();
            selected_children = new GenericArray <Object> ();
            base.on_selection_changed(position, n_items);
            var list_row = (Gtk.TreeListRow) treemodel.get_item(current_selection);
            Object? item = list_row.get_item();
            selected_item = item;
            selection_changed(item);
            for (uint i = 0; i < current_selections.length; i++) {
                var row = (Gtk.TreeListRow) treemodel.get_item(current_selections[i]);
                item = row.get_item();
                if (item != null && item is Family)
                    selected_items.add(item);
                else if (item != null)
                    selected_children.add(item);
            }
            if (Environment.get_variable("G_MESSAGES_DEBUG") != null) {
                string? description = null;
                selected_item.get("description", out description, null);
                debug("%s::selection_changed : %s", list.name, description);
            }
            return;
        }

    }

    // TODO
    //      - Context menu
    //          - Send to collection?
    //          - Export?

    public class FontListView : BaseFontListView {

        public signal void collection_changed ();

        public UserActionModel? user_actions { get; set; default = null; }
        public UserSourceModel? user_sources { get; set; default = null; }

        uint state_change_timeout = 0;
        bool ignore_state_change = false;

        bool show_menu = true;
        GLib.Menu menu;
        GLib.Array <GLib.MenuItem> menu_items;
        Gtk.Label menu_title;
        Gtk.PopoverMenu context_menu;

        static construct {
            install_action("copy-location", null, (Gtk.WidgetActionActivateFunc) copy_location);
            install_action("show-in-folder", null, (Gtk.WidgetActionActivateFunc) show_in_folder);
            install_action("enable-selected", null, (Gtk.WidgetActionActivateFunc) enable_selected);
            install_action("disable-selected", null, (Gtk.WidgetActionActivateFunc) disable_selected);
        }

        construct {
            widget_set_name(list, "FontManagerFontListView");
            widget_set_margin(list, 6);
            add_css_class(STYLE_CLASS_VIEW);
            ((Gtk.ListView) list).set_enable_rubberband(true);
            selected_items = new GenericArray <Object> ();
            Gtk.Gesture right_click = new Gtk.GestureClick() {
                button = Gdk.BUTTON_SECONDARY
            };
            ((Gtk.GestureClick) right_click).pressed.connect(on_show_context_menu);
            list.add_controller(right_click);
            select_item(0);
            notify["filter"].connect_after(() => {
                Idle.add(() => { select_item(0); return GLib.Source.REMOVE; });
                update_remove_sensitivity();
            });
            notify["disabled-families"].connect_after(() => {
                if (disabled_families != null && model != null)
                    disabled_families.changed.connect_after(queue_item_state_update);
            });
            init_context_menu();
            controls.remove_clicked.connect(on_remove_clicked);
        }

        public void set_search_term (string needle) {
            ((Gtk.Editable) controls.search).set_text(needle);
            return;
        }

        public Font get_selected_font () {
            Font font = new Font();
            if (selected_item is Family)
                font.source_object = ((Family) selected_item).get_default_variant();
            else
                font = ((Font) selected_item);
            return font;
        }

        protected override void on_activate (uint position) {
            if (selected_items.length < 1)
                return;
            selected_items.foreach((i) => { var f = (Family) i; f.active = !f.active; });
            current_selections.foreach((i) => { treemodel.items_changed(i, 0, 0); });
            return;
        }

        protected void on_remove_clicked () requires (filter is Collection) {
            var collection = (Collection) filter;
            var selected_families = new StringSet();
            selected_items.foreach((i) => { selected_families.add(((Family) i).family); });
            collection.families.remove_all(selected_families);
            uint i = current_selection;
            while (i > 0 && i >= treemodel.get_n_items() - 1) i--;
            Idle.add(() => {
                update(i);
                update_remove_sensitivity();
                collection.queue_state_update();
                return GLib.Source.REMOVE;
            });
            collection_changed();
            return;
        }

        string get_path_to_selected_item ()
        requires (selected_item != null) {
            Font font = get_selected_font();
            return font.filepath;
        }

        void set_selected_items_active (bool active) {
            Idle.add(() => {
                foreach (var item in selected_items)
                    ((Family) item).active = active;
                return GLib.Source.REMOVE;
            });
            return;
        }

        void enable_selected (Gtk.Widget widget, string? action, Variant? parameter)
        requires (selected_items.length > 1) {
            set_selected_items_active(true);
            return;
        }

        void disable_selected (Gtk.Widget widget, string? action, Variant? parameter)
        requires (selected_items.length > 1) {
            set_selected_items_active(false);
            return;
        }

        void copy_location (Gtk.Widget widget, string? action, Variant? parameter)
        requires (selected_item != null) {
            Gdk.Display display = Gdk.Display.get_default();
            Gdk.Clipboard clipboard = display.get_clipboard();
            string filepath = get_path_to_selected_item();
            clipboard.set_text((selected_item is Family) ? Path.get_dirname(filepath) : filepath);
            return;
        }

        void show_in_folder (Gtk.Widget widget, string? action, Variant? parameter)
        requires (selected_item != null) {
            string directory = GLib.Path.get_dirname(get_path_to_selected_item());
            File file = File.new_for_path(directory);
            var launcher = new Gtk.FileLauncher(file);
            launcher.launch.begin(null, null);
            return;
        }

        const MenuEntry [] fontlist_menu_entries = {
            {"install", N_("Install")},
            {"copy-location", N_("Copy Location")},
            {"show-in-folder",N_("Show in Folder")},
            {"enable-selected", N_("Enable selected items")},
            {"disable-selected",N_("Disable selected items")},
        };

        enum FontListMenuItem {
            INSTALL,
            COPY,
            SHOW,
            ENABLE,
            DISABLE
        }

        void init_context_menu () {
            menu_items = new GLib.Array <GLib.MenuItem> ();
            var base_menu = new BaseContextMenu(list);
            context_menu = base_menu.popover;
            menu_title = base_menu.menu_title;
            menu = base_menu.menu;
            foreach (var entry in fontlist_menu_entries) {
                var item = new GLib.MenuItem(entry.display_name, entry.action_name);
                menu_items.append_val(item);
            }
            return;
        }

        bool is_sourced (Font font) {
            foreach (var source in user_sources.items) {
                string path = ((Source) source).path;
                if (font.filepath.contains(path))
                    return true;
            }
            return false;
        }

        bool selections_are_sourced () {
            return_val_if_fail(user_sources != null, false);
            if (selected_children.length >= 1) {
                foreach (var selection in selected_children) {
                    if (is_sourced((Font) selection))
                        continue;
                    return false;
                }
                return true;
            } else if (selected_item != null) {
                if (selected_item is Font) {
                    return is_sourced((Font) selected_item);
                } else {
                    Json.Array array = ((Family) selected_item).variations;
                    for (uint i = 0; i < array.get_length(); i++) {
                        var font = new Font();
                        font.source_object = array.get_object_element(i);
                        if (is_sourced(font))
                            continue;
                        return false;
                    }
                    return true;
                }
            }
            return false;
        }

        void update_context_menu () {
            menu.remove_all();
            show_menu = true;
            if (selected_items.length > 1) {
                int n_items = selected_items.length;
                // Translators : Even though singular form is not used yet, it is here
                // to make for a proper ngettext call. Still it is advisable to translate it.
                menu_title.set_label(ngettext("%i selected item",
                                              "%i selected items",
                                              (ulong) n_items).printf((int) n_items));
                menu.append_item(menu_items.data[FontListMenuItem.ENABLE]);
                menu.append_item(menu_items.data[FontListMenuItem.DISABLE]);
            } else if (selected_children.length > 1) {
                int n_items = selected_children.length;
                // Translators : Even though singular form is not used yet, it is here
                // to make for a proper ngettext call. Still it is advisable to translate it.
                menu_title.set_label(ngettext("%i selected item",
                                              "%i selected items",
                                              (ulong) n_items).printf((int) n_items));
                if (selections_are_sourced())
                    menu.append_item(menu_items.data[FontListMenuItem.INSTALL]);
                else
                    show_menu = false;
            } else {
                string? description = null;
                string? family = null;
                selected_item.get("description", out description, "family", out family, null);
                menu_title.set_label((selected_item is Family) ? family : description);
                if (selections_are_sourced())
                    menu.append_item(menu_items.data[FontListMenuItem.INSTALL]);
                menu.append_item(menu_items.data[FontListMenuItem.COPY]);
                menu.append_item(menu_items.data[FontListMenuItem.SHOW]);
                if (user_actions != null && user_actions.get_n_items() > 0) {
                    var action_menu = new GLib.Menu();
                    var submenu = new GLib.MenuItem.submenu(_("Actions"), action_menu);
                    menu.append_item(submenu);
                    int i = 0;
                    foreach (var entry in user_actions) {
                        var item = new GLib.MenuItem(entry.action_name, null);
                        item.set_attribute("custom", "s", i.to_string());
                        action_menu.append_item(item);
                        var widget = new Gtk.Button.with_label(entry.action_name);
                        var label = (Gtk.Label) widget.get_child();
                        label.set_xalign(0.0f);
                        widget.remove_css_class("button");
                        widget.add_css_class("flat");
                        widget.add_css_class("row");
                        context_menu.add_child(widget, i.to_string());
                        var target = get_selected_font();
                        widget.clicked.connect(() => {
                            entry.run(target);
                        });
                        i++;
                    }
                }
            }
            return;
        }

        void on_show_context_menu (int n_press, double x, double y) {
            if (!show_menu || selected_item == null && selected_children.length < 1)
                return;
            var rect = Gdk.Rectangle() {x = (int) x, y = (int) y, width = 2, height = 2};
            context_menu.set_pointing_to(rect);
            update_context_menu();
            context_menu.present();
            context_menu.popup();
            return;
        }

        Gdk.ContentProvider prepare_drag (Gtk.DragSource source, double x, double y) {
            var selections = new GenericArray <Object> ();
            var e_type = typeof(Gtk.TreeExpander);
            var expander = (Gtk.TreeExpander) source.widget.get_ancestor(e_type);
            var list_row = (Gtk.TreeListRow) expander.get_list_row();
            // Dragged row is not necessarily the currently selected row
            if (list_row.item is Family)
                selections.add(list_row.item);
            // If we have multiple rows selected we need to add them here
            if (selected_items.length > 1)
                foreach (var item in selected_items)
                    if (item != list_row.item)
                        selections.add(item);
            return new Gdk.ContentProvider.for_value(selections);
        }

        void drag_begin (Gtk.DragSource drag_source, Gdk.Drag drag) {
            var drag_icon = new Gtk.Overlay();
            var icon = new Gtk.Image.from_icon_name("font-x-generic");
            icon.set_pixel_size(64);
            drag_icon.set_child(icon);
            var drag_count = new Gtk.Label(null) {
                opacity = 0.9,
                halign = Gtk.Align.END,
                valign = Gtk.Align.START,
            };
            widget_set_name(drag_count, "FontManagerListDragCount");
            drag_icon.add_overlay(drag_count);
            drag_count.set_label(selected_items.length.to_string());
            var gtk_drag_icon = (Gtk.DragIcon) Gtk.DragIcon.get_for_drag(drag);
            gtk_drag_icon.set_child(drag_icon);
            return;
        }

        protected override void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            base.setup_list_row(factory, item);
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var row = (FontListRow) ((Gtk.TreeExpander) list_item.get_child()).get_child();
            var drag_source = new Gtk.DragSource();
            row.drag_area.add_controller(drag_source);
            drag_source.prepare.connect(prepare_drag);
            drag_source.drag_begin.connect(drag_begin);
            return;
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            base.bind_list_row(factory, item);
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            var row = (FontListRow) tree_expander.get_child();
            Object? _item = list_row.get_item();
            if (_item is Family && disabled_families != null)
                row.item_state.active = !(((Family) _item).family in disabled_families);
            row.item_state_changed.connect(on_item_state_changed);
            return;
        }

        bool save_item_state_change () {
            disabled_families.save();
            state_change_timeout = 0;
            // XXX: TODO : Fix this tangled mess...
            // It will probably require quite a bit of refactoring. :-(
            if (filter != null && filter is Collection) {
                ignore_state_change = true;
                uint n_items = treemodel.get_n_items();
                for (uint i = 0; i < n_items; i++) {
                    var item = model.get_item(i);
                    var obj = (Family) item;
                    obj.active = !(obj.family in disabled_families);
                }
                ignore_state_change = false;
                queue_update();
            }
            return GLib.Source.REMOVE;
        }

        // Slight delay in saving selections to file in case
        // multiple changes are taking place at the same time.
        void queue_item_state_update () {
            if (state_change_timeout != 0)
                GLib.Source.remove(state_change_timeout);
            state_change_timeout = Timeout.add(333, save_item_state_change);
            return;
        }

        void on_item_state_changed (Object? item) {
            if (ignore_state_change)
                return;
            var family = ((Family) item);
            if (family.active)
                disabled_families.remove(family.family);
            else
                disabled_families.add(family.family);
            return;
        }

        void update_remove_sensitivity () {
            bool remove_available = current_selection != uint.MAX &&
                                    filter is Collection &&
                                    ((Collection) filter).families.size > 0;
            set_control_sensitivity(controls.remove_button, remove_available);
            return;
        }

        protected override void on_selection_changed (uint position, uint n_items) {
            base.on_selection_changed(position, n_items);
            update_remove_sensitivity();
            return;
        }

    }

    public class RemoveListView : BaseFontListView {

        public signal void changed ();

        public StringSet selected_files { get; set; default = null; }

        construct {
            widget_set_name(list, "FontManagerRemoveListView");
            controls.remove_button.visible = false;
            controls.expander.visible = false;
            controls.search.halign = Gtk.Align.CENTER;
            treemodel.set_autoexpand(true);
            selected_files = new StringSet();
            selection = new Gtk.NoSelection(treemodel);
            filter = new UserFonts();
            filter.update.begin();
            controls.set_visible(filter.size > 20);
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            base.bind_list_row(factory, item);
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            var row = (FontListRow) tree_expander.get_child();
            Object? _item = list_row.get_item();
            row.drag_handle.visible = false;
            row.drag_area.sensitive = true;
            row.margin_start = 0;
            row.margin_end = 12;
            row.item_state.set("sensitive", true, "visible", !(_item is Family), null);
            row.item_state.toggled.connect((c) => {
                on_item_state_changed(list_row);
            });
            if (_item is Family) {
                row.item_label.add_css_class("heading");
                row.item_label.add_css_class("dim-label");
            } else {
                row.item_label.remove_css_class("heading");
                row.item_label.remove_css_class("dim-label");
            }
            tree_expander.set_hide_expander(true);
            return;
        }

        void on_item_state_changed (Gtk.TreeListRow? row) {
            Object? item = row.get_item();
            if (!(item is Font))
                return;
            Font font = (Font) item;
            if (font.active)
                selected_files.add(font.filepath);
            else
                selected_files.remove(font.filepath);
            changed();
            return;
        }

    }

}




