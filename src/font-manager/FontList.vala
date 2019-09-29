/* FontList.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    /**
     * {@inheritDoc}
     */
    public class FontListControls : BaseControls {

        /**
         * FontListControls::expand_all:
         *
         * Emitted when the expand_button is clicked
         */
        public signal void expand_all (bool expand);

        public bool expanded { get; private set; }
        public Gtk.Button expand_button { get; private set; }
        public Gtk.SearchEntry entry { get; private set; }

        Gtk.Image arrow;

        public FontListControls () {
            Object(name: "FontListControls", margin: 1);
            remove_button.set_tooltip_text(_("Remove selected font from collection"));
            add_button.destroy();
            expand_button = new Gtk.Button();
            arrow = new Gtk.Image.from_icon_name("go-next-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            expand_button.add(arrow);
            expand_button.set_tooltip_text(_("Expand all"));
            entry = new Gtk.SearchEntry();
            entry.set_size_request(0, 0);
            entry.margin_end = MINIMUM_MARGIN_SIZE;
            entry.placeholder_text = _("Search Families…");
            entry.set_tooltip_text(_("Case insensitive search of family names.\n\nStart search using %s to filter based on filepath."). printf(Path.DIR_SEPARATOR_S));
            box.pack_end(entry, false, false, 0);
            box.pack_start(expand_button, false, false, 0);
            box.reorder_child(expand_button, 0);
            set_button_relief_style(box);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            get_style_context().add_class(name);
            set_size_request(0, 0);
            expand_button.clicked.connect((w) => {
                expanded = !expanded;
                expand_all(expanded);
                expand_button.set_tooltip_text(expanded ? _("Collapse all") : _("Expand all"));
                if (expanded)
                    arrow.set_from_icon_name("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                else
                    arrow.set_from_icon_name("go-next-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            });
            entry.show();
            arrow.show();
            expand_button.show();
            add_button.hide();
        }

        /**
         * set_remove_sensitivity:
         * @sensitive:  %TRUE if remove function should be available.
         *              %FALSE if remove function is unavailable.
         */
        public void set_remove_sensitivity (bool sensitive) {
            remove_button.set_sensitive(sensitive);
            remove_button.set_has_tooltip(sensitive);
            remove_button.opacity = sensitive ? 1.0 : 0.1;
            return;
        }

    }

    enum FontListColumn {
        TOGGLE,
        TEXT,
        PREVIEW,
        COUNT,
        N_COLUMNS
    }

    public abstract class BaseFontList : BaseTreeView {

        public Json.Object? samples { get; set; default = null; }

        protected Gtk.CellRendererToggle toggle;

        string default_sample;
        string local_sample;

        construct {
            name = "BaseFontList";
            headers_visible = false;
            expand = true;
            toggle = new Gtk.CellRendererToggle();
            var text = new Gtk.CellRendererText();
            var count = new CellRendererStyleCount();
            var preview = new Gtk.CellRendererText();
            preview.ellipsize = Pango.EllipsizeMode.END;
            insert_column_with_data_func(FontListColumn.TOGGLE, "", toggle, toggle_cell_data_func);
            insert_column_with_data_func(FontListColumn.TEXT, "", text, text_cell_data_func);
            insert_column_with_data_func(FontListColumn.PREVIEW, "", preview, preview_cell_data_func);
            insert_column_with_data_func(FontListColumn.COUNT, "", count, count_cell_data_func);
            for (int i = 0; i < FontListColumn.N_COLUMNS; i++)
                get_column(i).expand = (i == FontListColumn.PREVIEW);
            connect_signals();
            default_sample = Pango.Language.from_string("xx").get_sample_string();
            local_sample = get_localized_pangram();
        }

        protected virtual void on_selection_changed (Gtk.TreeSelection selection) {
            return;
        }

        protected virtual void on_toggled (string path) {
            return;
        }

        protected virtual void toggle_cell_data_func (Gtk.TreeViewColumn layout,
                                                      Gtk.CellRenderer cell,
                                                      Gtk.TreeModel model,
                                                      Gtk.TreeIter treeiter)
        {
            return;
        }

        void connect_signals () {
            get_selection().changed.connect(on_selection_changed);
            toggle.toggled.connect(on_toggled);
            row_activated.connect((path, col) => { on_toggled(path.to_string()); });
            return;
        }

        public void select_first_row () {
            Gtk.TreePath path = new Gtk.TreePath.first();
            Gtk.TreeSelection selection = get_selection();
            selection.unselect_all();
            selection.select_path(path);
            if (selection.path_is_selected(path))
                scroll_to_cell(path, null, true, 0.5f, 0.5f);
            return;
        }

        public void select_next_row (bool forward = true) {
            Gtk.TreeSelection selection = get_selection();
            GLib.List <Gtk.TreePath> paths = selection.get_selected_rows(null);
            Gtk.TreePath path = paths.nth_data(0);
            if (path != null) {
                bool path_changed = false;
                if (forward)
                    path.next();
                else
                    path_changed = path.prev();
                if (forward || path_changed) {
                    selection.unselect_all();
                    selection.select_path(path);
                }
            }
            if (!selection.path_is_selected(path))
                select_first_row();
            else if (path != null)
                scroll_to_cell(path, null, true, 0.0f, 0.0f);
            return;
        }

        void set_sensitivity(Gtk.CellRenderer cell, Gtk.TreeIter treeiter, string? family) {
            bool inactive = (reject != null && family != null ? family in reject : false);
            cell.set_property("strikethrough" , inactive);
            if (inactive && get_selection().iter_is_selected(treeiter))
                cell.set_property("sensitive" , true);
            else
                cell.set_property("sensitive" , !inactive);
            return;
        }

        protected virtual void preview_cell_data_func (Gtk.TreeViewColumn layout,
                                                       Gtk.CellRenderer cell,
                                                       Gtk.TreeModel model,
                                                       Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            Object obj = val.get_object();
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            cell.set_property("attributes", attrs);
            if (obj is Family) {
                cell.set_property("text", ((Family) obj).description);
                cell.set_property("visible", false);
            } else {
                string description = ((Font) obj).description;
                if (samples != null && samples.has_member(description)) {
                    string? sample = samples.get_string_member(description);
                    if (sample != null && sample != default_sample && sample != local_sample)
                        cell.set_property("text", sample);
                    else
                        cell.set_property("text", description);
                } else
                    cell.set_property("text", description);
                cell.set_property("font", description);
                cell.set_property("visible", true);
                set_sensitivity(cell, treeiter, ((Font) obj).family);
            }
            val.unset();
            return;
        }

        /* NOTE :
         * Iterating through children is necessary to get an accurate count.
         * Family objects have n_variations which could be used, but would be
         * inaccurate whenever a category which limits variations is selected.
         */
        protected virtual void count_cell_data_func (Gtk.TreeViewColumn layout,
                                                     Gtk.CellRenderer cell,
                                                     Gtk.TreeModel model,
                                                     Gtk.TreeIter treeiter) {
            if (model.iter_has_child(treeiter)) {
                int count = 0;
                Gtk.TreeIter child;
                bool have_child = model.iter_children(out child, treeiter);
                while (have_child) {
                    count++;
                    have_child = model.iter_next(ref child);
                }
                cell.set_property("count", count);
                cell.set_property("visible", true);
            } else {
                cell.set_property("count", 0);
                cell.set_property("visible", false);
            }
            return;
        }

        protected virtual void text_cell_data_func (Gtk.TreeViewColumn layout,
                                                    Gtk.CellRenderer cell,
                                                    Gtk.TreeModel model,
                                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            Object obj = val.get_object();
            string family = get_family_from_object(obj);
            if (obj is Family) {
                cell.set_property("text", family);
                set_sensitivity(cell, treeiter, family);
                cell.set_padding(0, 0);
            } else {
                cell.set_property("text", ((Font) obj).style);
                set_sensitivity(cell, treeiter, family);
                cell.set_padding(8, 0);
            }
            val.unset();
            return;
        }

    }

    public class FontList : BaseFontList {

        public new Gtk.TreeModel? model {
            get {
                return base.get_model();
            }
            set {
                base.set_model(value);
                select_first_row();
            }
        }

        public string selected_iter { get; protected set; default = "0"; }
        public string? selected_family { get; private set; default = null; }
        public Font? selected_font { get; private set; default = null; }

        Gtk.Menu context_menu;
        Gtk.MenuItem? filename = null;
        Gtk.MenuItem? installable = null;

        public FontList () {
            name = "FontList";
            set_rubber_banding(true);
            get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);
            context_menu = get_context_menu();
            selected_font = new Font();
        }

        public StringHashset get_selected_families () {
            var selected = new StringHashset();
            List <Gtk.TreePath> _selected = get_selection().get_selected_rows(null);
            foreach (Gtk.TreePath path in _selected) {
                Value val;
                Gtk.TreeIter iter;
                model.get_iter(out iter, path);
                model.get_value(iter, FontModelColumn.OBJECT, out val);
                string family = get_family_from_object(val.get_object());
                selected.add(family);
                val.unset();
            }
            return selected;
        }

        /* TODO :
         * Set custom icon which includes selection count
         */
        public override void drag_begin (Gdk.DragContext context) {
            Gtk.drag_set_icon_name(context, "font-x-generic", 0, 0);
            return;
        }

        bool selection_is_sourced () requires (selected_font != null) {
            if (sources != null)
                foreach (string dir in sources)
                    if (selected_font.filepath.contains(dir))
                        return true;
            return false;
        }

        protected override void on_selection_changed (Gtk.TreeSelection selection) {
            List <Gtk.TreePath> selected = selection.get_selected_rows(null);
            if (selected == null || selected.length() < 1)
                return;
            Gtk.TreePath path = selected.nth_data(0);
            Gtk.TreeIter iter;
            model.get_iter(out iter, path);
            Value val;
            model.get_value(iter, FontModelColumn.OBJECT, out val);
            Object object = val.get_object();
            if (object is Family) {
                selected_font.source_object = ((Family) object).get_default_variant();
                notify_property("selected-font");
            } else {
                selected_font = null;
                selected_font = ((Font) object);
            }
            selected_family = selected_font.family;
            selected_iter = model.get_string_from_iter(iter);
            val.unset();
            Idle.add(() => {
                if (installable != null)
                    installable.set_visible(selection_is_sourced());
                return false;
            });
            if (filename != null)
                filename.label = Path.get_basename(selected_font.filepath);
            return;
        }

        StringHashset get_files_for_family (Family family) {
            var results = new StringHashset();
            foreach (var node in family.variations.get_elements()) {
                var object = node.get_object();
                results.add(object.get_string_member("filepath"));
            }
            return results;
        }

        protected override void on_toggled (string path) {
            if (reject == null)
                return;
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, FontModelColumn.OBJECT, out val);
            var family_object = val.get_object() as Family;
            string family = get_family_from_object(family_object);
            if (family in reject)
                reject.remove(family);
            else {
                foreach (var filepath in get_files_for_family(family_object))
                    add_application_font(filepath);
                reject.add(family);
            }
            reject.save();
            val.unset();
            queue_draw();
            return;
        }

        protected override void toggle_cell_data_func (Gtk.TreeViewColumn layout,
                                                       Gtk.CellRenderer cell,
                                                       Gtk.TreeModel model,
                                                       Gtk.TreeIter treeiter) {
            if (reject != null && model.iter_has_child(treeiter)) {
                Value val;
                model.get_value(treeiter, FontModelColumn.NAME, out val);
                cell.set_property("visible", true);
                cell.set_property("active", !(reject.contains((string) val)));
                val.unset();
            } else {
                cell.set_property("visible", false);
            }
            return;
        }

        protected override bool show_context_menu (Gdk.EventButton e) {
            context_menu.popup_at_pointer(null);
            return true;
        }

        /* TODO :
         * Implement and group all context menus used in the application so that
         * they're easy to modify/extend in one place.
         */
        Gtk.Menu get_context_menu () {
            /* action_name, display_name, detailed_action_name, accelerator, method */
            MenuEntry [] context_menu_entries = {
                MenuEntry("install", _("Install"), "app.install", null, new MenuCallbackWrapper(install)),
                MenuEntry("copy_location", _("Copy Location"), "app.copy_location", null, new MenuCallbackWrapper(copy_location)),
                MenuEntry("show_in_folder", _("Show in Folder"), "app.show_in_folder", null, new MenuCallbackWrapper(show_in_folder)),
            };
            var popup_menu = new Gtk.Menu();
            filename = new Gtk.MenuItem.with_label("");
            filename.sensitive = false;
            filename.show();
            popup_menu.append(filename);
            var label = ((Gtk.Bin) filename).get_child();
            label.set("hexpand", true, "justify", Gtk.Justification.FILL, "margin", 2, null);
            var separator = new Gtk.SeparatorMenuItem();
            separator.show();
            popup_menu.append(separator);
            foreach (MenuEntry entry in context_menu_entries) {
                var item = new Gtk.MenuItem.with_label(entry.display_name);
                item.activate.connect(() => { entry.method.run(); });
                item.show();
                popup_menu.append(item);
                if (entry.action_name == "install")
                    installable = item;
            }
            /* Wayland complains if not set */
            popup_menu.realize.connect(() => {
                Gdk.Window child = popup_menu.get_window();
                child.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU);
            });
            return popup_menu;
        }

        public void install () {
            var filelist = new StringHashset();
            filelist.add(selected_font.filepath);
            var installer = new Library.Installer();
            installer.process.begin(filelist, (obj, res) => {
                installer.process.end(res);
                Timeout.add_seconds(3, () => {
                    ((FontManager.Application) GLib.Application.get_default()).refresh();
                    return false;
                });
            });
            return;
        }

        public void show_in_folder () {
            string directory = GLib.Path.get_dirname(selected_font.filepath);
            string uri = "file://%s".printf(directory);
            try {
                Gtk.show_uri_on_window(main_window, uri, Gdk.CURRENT_TIME);
            } catch (Error e) {
                warning(e.message);
            }
            return;
        }

        public void copy_location () {
            Gdk.Display display = Gdk.Display.get_default();
            Gtk.Clipboard clipboard = Gtk.Clipboard.get_default(display);
            clipboard.set_text(selected_font.filepath, -1);
            return;
        }

    }

    public class UserFontList : BaseFontList {

        StringHashset selected_families;
        StringHashset selected_fonts;

        public UserFontList () {
            name = "UserFontList";
            get_selection().set_mode(Gtk.SelectionMode.SINGLE);
            selected_families = new StringHashset ();
            selected_fonts = new StringHashset ();
        }

        public StringHashset get_selections () {
            var selections = new StringHashset();
            try {
                Database db = get_database(DatabaseType.BASE);
                string user_font_dir = get_user_font_directory();
                string sql = "SELECT DISTINCT filepath FROM Fonts WHERE description = \"%s\" AND filepath LIKE \"%%s%\"";
                foreach (var description in selected_fonts) {
                    db.execute_query(sql.printf(description, user_font_dir));
                    foreach (unowned Sqlite.Statement row in db)
                        selections.add(row.column_text(0));
                }
            } catch (Error e) {
                critical(e.message);
            }
            return selections;
        }

        void family_toggled (Family family, bool enabled) {
            var font = new Font();
            GLib.List <unowned Json.Node> variations = family.variations.get_elements();
            foreach (var node in variations) {
                font.source_object = node.get_object();
                if (enabled)
                    selected_fonts.add(font.description);
                else
                    selected_fonts.remove(font.description);
            }
            return;
        }

        protected override void on_toggled (string path) {
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, FontModelColumn.OBJECT, out val);
            Object obj = val.get_object();
            if (obj is Family) {
                var family = obj as Family;
                if (selected_families.contains(family.family)) {
                    selected_families.remove(family.family);
                    family_toggled(family, false);
                } else {
                    selected_families.add(family.family);
                    family_toggled(family, true);
                }
            } else {
                var font = obj as Font;
                if (selected_fonts.contains(font.description))
                    selected_fonts.remove(font.description);
                else
                    selected_fonts.add(font.description);
            }
            val.unset();
            queue_draw();
            return;
        }

        protected override void toggle_cell_data_func (Gtk.TreeViewColumn layout,
                                                       Gtk.CellRenderer cell,
                                                       Gtk.TreeModel model,
                                                       Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            var obj = val.get_object();
            cell.set_property("visible", true);
            cell.set_property("sensitive", true);
            cell.set_property("inconsistent", false);
            bool active = false;
            if (obj is Family)
                active = selected_families.contains(((Family) obj).family);
            else
                active = selected_fonts.contains(((Font) obj).description);
            cell.set_property("active", active);
            val.unset();
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-list-pane.ui")]
    public class FontListPane : Gtk.Box {

        public FontListControls controls { get; protected set; }
        public FontListFilter? filter { get; set; default = null; }

        public BaseFontList fontlist {
            get {
                return ((BaseFontList) scrolled_window.get_child());
            }
            set {
                Gtk.Widget? current_child = scrolled_window.get_child();
                if (current_child != null)
                    scrolled_window.remove(current_child);
                scrolled_window.add(value);
                value.show();
            }
        }

        public Gtk.TreeModel? model {
            get {
                return real_model;
            }
            set {
                real_set_model(value);
            }
        }

        public bool show_controls {
            get {
                return revealer.get_reveal_child();
            }
            set {
                revealer.set_reveal_child(value);
            }
        }

        uint? search_timeout;
        uint16 text_length = 0;
        Gtk.TreeModel? real_model = null;
        Gtk.TreeModelFilter? search_filter = null;
        [GtkChild] Gtk.Revealer revealer;
        [GtkChild] Gtk.ScrolledWindow scrolled_window;

        public override void constructed () {
            controls = new FontListControls();
            controls.set_remove_sensitivity(false);
            revealer.add(controls);
            connect_signals();
            controls.show();
            base.constructed();
            return;
        }

        public bool refilter () {
            /* NOTE :
             * Creating a new Gtk.TreeModelFilter is cheaper than calling
             * refilter on an existing one with a large child model.
             */
            var saved_model = real_model;
            real_set_model(null);
            real_set_model(saved_model);
            fontlist.select_first_row();
            if (controls.expanded)
                fontlist.expand_all();
            search_timeout = null;
            return false;
        }

        void real_set_model (Gtk.TreeModel? model) {
            real_model = model;
            if (model != null) {
                search_filter = new Gtk.TreeModelFilter(model, null);
                search_filter.set_visible_func((m, i) => { return visible_func(m, i); });
                fontlist.model = search_filter;
            } else {
                search_filter = null;
                fontlist.model = null;
            }
            return;
        }

        /* Add slight delay to avoid filtering while search is still changing */
        public void queue_refilter () {
            if (search_timeout != null)
                GLib.Source.remove(search_timeout);
            search_timeout = Timeout.add(333, refilter);
            return;
        }

        void connect_signals () {
            notify["filter"].connect(() => { refilter(); });
            controls.entry.search_changed.connect(() => {
                queue_refilter();
                text_length = controls.entry.get_text_length();
            });
            controls.expand_all.connect((e) => {
                if (e)
                    fontlist.expand_all();
                else
                    fontlist.collapse_all();
            });
            controls.entry.next_match.connect(() => {
                fontlist.select_next_row();
            });
            controls.entry.previous_match.connect(() => {
                fontlist.select_next_row(false);
            });
            controls.entry.activate.connect(() => {
                fontlist.select_next_row();
            });
            return;
        }

        bool visible_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
            bool search_match = true;
            if (text_length > 0) {
                Value val;
                model.get_value(iter, FontModelColumn.OBJECT, out val);
                Object object = val.get_object();
                string needle = controls.entry.get_text().casefold();
                if (needle.has_prefix(Path.DIR_SEPARATOR_S)) {
                    string filepath = get_filepath_from_object(object).casefold();
                    search_match = filepath.contains(needle);
                } else {
                    string family = get_family_from_object(object).casefold();
                    search_match = family.contains(needle);
                }
            }
            if (filter != null)
                return search_match && filter.visible_func(model, iter);
            return search_match;
        }

    }

    internal string get_family_from_object (Object object)
    requires (object is Family || object is Font) {
        return (object is Family) ? ((Family) object).family : ((Font) object).family;
    }

    internal string get_filepath_from_object (Object object)
    requires (object is Family || object is Font) {
        return (object is Family) ?
               ((Family) object).get_default_variant().get_string_member("filepath") :
               ((Font) object).filepath;
    }

}

