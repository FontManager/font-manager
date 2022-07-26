/* Categories.vala
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

    public const string SELECT_FROM_FONTS = "SELECT DISTINCT family, description FROM Fonts";
    public const string SELECT_FROM_METADATA_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Metadata USING (filepath, findex) WHERE";
    public const string SELECT_FROM_PANOSE_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Panose USING (filepath, findex) WHERE";

    public enum CategoryIndex {
        ALL,
        SYSTEM,
        USER,
        PANOSE,
        WIDTH,
        WEIGHT,
        SLANT,
        SPACING,
        LICENSE,
        VENDOR,
        FILETYPE,
        UNSORTED,
        DISABLED,
        N_CATEGORIES
    }

    public class BaseCategoryListModel : Object, ListModel {

        public StringSet? available_families { get; set; default = null; }
        public GenericArray <Category>? items { get; set; default = null; }

        public Type get_item_type () {
            return typeof(Category);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position) {
            return_val_if_fail(items[position] != null, null);
            return items[position];
        }

    }

    public class ChildCategoryListModel : BaseCategoryListModel {}

    public class CategoryListModel : BaseCategoryListModel {

        public CategoryListModel () {
            notify["available-families"]. connect_after((pspecc) => {
                update_items.begin();
            });
        }

        public new async void update_items () {
            uint n_items = get_n_items();
            items = null;
            items = new GenericArray <Category> ();
            items_changed(0, n_items, 0);
            try {
                Database db = get_database(DatabaseType.BASE);
                items = get_default_categories(db);
                items_changed(0, 0, get_n_items());
                // Preload main categories
                for (uint i = 0; i < CategoryIndex.PANOSE; i++)
                    yield items[i].update(available_families);
            } catch (DatabaseError e) {
                critical(e.message);
            }
            return;
        }

        public ListModel? get_child_model (Object item) {
            var category = ((Category) item);
            if (category.children.length < 1)
                return null;
            var child = new BaseCategoryListModel();
            child.items = category.children;
            return child;
        }

    }

    public class CategoryListBoxRow : ItemListBoxRow {

        ulong handler_id = 0;

        construct {
            notify["item"].connect((pspec) => { on_item_set(); });
            item_state.visible = false;
            item_preview.visible = false;
        }

        void reset_row () {
            item_name.set_label("");
            item_count.visible = true;
            item_count.set_label("");
            if (handler_id != 0)
                item.disconnect(handler_id);
            return;
        }

        public void on_item_set () {
            reset_row();
            if (item == null)
                return;
            var category = ((Category) item);
            handler_id = category.changed.connect(on_item_set);
            bool root_node = category.depth < 1;
            int index = category.index;
            bool show_root_count = (index < CategoryIndex.PANOSE || index > CategoryIndex.FILETYPE);
            item_name.set_label(category.name);
            item_count.visible = !root_node || show_root_count;
            item_icon.visible = !root_node || show_root_count;
            if (item_icon.visible)
                item_icon.set_from_icon_name(category.icon);
            if (item_icon.visible && !root_node)
                item_icon.margin_start = 12;
            if (item_count.visible)
                item_count.set_label(category.size.to_string());
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-category-list-view.ui")]
    public class CategoryListView : Gtk.Box {

        public signal void selection_changed (Object? item);

        public Object? selected_item { get; set; default = null; }

        // FIXME : Need to handle updates to Unsorted and Disabled categories
        public Reject? reject { get; set; default = null; }
        public StringSet? sorted { get; set; default = null; }
        public StringSet? available_families { get; set; default = null; }

        public BaseCategoryListModel model {
            get {
                return ((BaseCategoryListModel) treemodel.model);
            }
        }

        Gtk.TreeListModel treemodel;
        Gtk.SingleSelection selection;
        [GtkChild] unowned Gtk.ListView listview;

        construct {
            var _model = new CategoryListModel();
            treemodel = new Gtk.TreeListModel(_model,
                                              false,
                                              false,
                                              _model.get_child_model);
            selection = new Gtk.SingleSelection(treemodel);
            listview.set_factory(get_factory());
            listview.set_model(selection);
            selection.selection_changed.connect(on_selection_changed);
            BindingFlags flags = BindingFlags.SYNC_CREATE;
            bind_property("available-families", model, "available-families", flags, null, null);
            if (Environment.get_variable("G_MESSAGES_DEBUG") != null) {
                selection_changed.connect(() => {
                    string? category_name = null;
                    selected_item.get("name", out category_name, null);
                    debug("selection_changed : %s", category_name);
                });
            }
        }

        Gtk.SignalListItemFactory get_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            return factory;
        }

        void setup_list_row (Gtk.ListItem list_item) {
            var tree_expander = new Gtk.TreeExpander();
            tree_expander.set_indent_for_icon(false);
            tree_expander.set_child(new CategoryListBoxRow());
            list_item.set_child(tree_expander);
            return;
        }

        void bind_list_row (Gtk.ListItem list_item) {
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.margin_start = 2;
            tree_expander.set_list_row(null);
            var row = (CategoryListBoxRow) tree_expander.get_child();
            widget_set_margin(row, 3);
            Object? item = list_row.get_item();
            // Setting item triggers update to row widgets
            row.item = item;
            return_if_fail(item != null);
            var category = ((Category) item);
            tree_expander.set_list_row(category.depth < 1 ? list_row : null);
            list_row.notify["expanded"].connect((pspec) => {
                category.update.begin(available_families);
            });
            return;
        }

        void collapse_all () {
            uint n_items = treemodel.get_n_items();
            for (uint i = 0; i < n_items; i++) {
                var list_row = (Gtk.TreeListRow) treemodel.get_item(i);
                if (list_row != null && list_row.expanded)
                    list_row.set_expanded(false);
            }
            return;
        }

        // NOTE:
        // @position doesn't necessarily point to the actual selection
        // within the ListView, the actual selection lies somewhere
        // between @position + @n_items. The precise location within that
        // range appears to be affected by a variety of factors i.e.
        // previous selection, multiple selections, directional changes, etc.
        void on_selection_changed (uint position, uint n_items) {
            // The minimum value present in this bitset accurately points
            // to the first currently selected row in the ListView.
            Gtk.Bitset selections = selection.get_selection();
            uint i = selections.get_minimum();
            var list_row = (Gtk.TreeListRow) treemodel.get_item(i);
            Object? item = list_row.get_item();
            var category = ((Category) item);
            int index = category.index;
            bool index_in_range = (index > CategoryIndex.USER && index < CategoryIndex.UNSORTED);
            if (index_in_range && category.depth < 1) {
                collapse_all();
                if (list_row.is_expandable())
                    list_row.set_expanded(true);
            } else if (category.depth < 1)
                collapse_all();
            selected_item = item;
            selection_changed(item);
            return;
        }

    }

    internal struct FilterData {
        public int index;
        public string name;
        public string comment;
        public string column;
    }

    internal const FilterData [] attributes = {
        { CategoryIndex.WIDTH, N_("Width"), N_("Grouped by font width"), "width" },
        { CategoryIndex.WEIGHT, N_("Weight"), N_("Grouped by font weight"), "weight" },
        { CategoryIndex.SLANT, N_("Slant"), N_("Grouped by font angle"), "slant" },
        { CategoryIndex.SPACING, N_("Spacing"), N_("Grouped by font spacing"), "spacing" }
    };

    internal const FilterData [] metadata = {
        { CategoryIndex.LICENSE, N_("License"), N_("Grouped by license type"), "license-type" },
        /* Translators : For context see https://docs.microsoft.com/en-us/typography/opentype/spec/os2#achvendid */
        { CategoryIndex.VENDOR, N_("Vendor"), N_("Grouped by vendor"), "vendor" },
        { CategoryIndex.FILETYPE, N_("Filetype"), N_("Grouped by filetype"), "filetype" }
    };

    /*  WARNING : Long lines ahead... */

    GenericArray <Category> get_default_categories (Database db) {
        var filters = new GenericArray <Category> ();
        filters.add(new Category(_("All"), _("All Fonts"), "format-text-bold-symbolic", "%s;".printf(SELECT_FROM_FONTS), CategoryIndex.ALL));
        filters.add(new Category(_("System"), _("Fonts available to all users"), "computer-symbolic", "%s owner!=0 AND filepath LIKE '/usr%';".printf(SELECT_FROM_METADATA_WHERE), CategoryIndex.SYSTEM));
        filters.add(new UserFonts());
        filters.add(construct_panose_filter());
        foreach (var entry in attributes)
            filters.add(construct_attribute_filter(db, entry));
        foreach (var entry in metadata)
            filters.add(construct_info_filter(db, entry));
        filters.add(new Unsorted());
        filters.add(new Disabled());
        return filters;
    }

    Category construct_panose_filter () {
        var panose = new Category(_("Family Kind"), _("Only fonts which include Panose information will be grouped here."), "folder-symbolic", null, CategoryIndex.PANOSE);
        string [] kind = { _("Any"), _("No Fit"), _("Text and Display"), _("Script"), _("Decorative"), _("Pictorial") };
        for (int i = 0; i < kind.length; i++)
            panose.children.add(new Category(kind[i], kind[i], "emblem-documents-symbolic", "%s P0 = '%i';".printf(SELECT_FROM_PANOSE_WHERE, i), i));
        panose.children.foreach((child) => { child.depth = 1; });
        return panose;
    }

    Category construct_attribute_filter (Database db, FilterData data) {
        var name = dgettext(null, data.name);
        var comment = dgettext(null, data.comment);
        var filter = new Category(name, comment, "folder-symbolic", null, data.index);
        try {
            var keyword = data.column;
            db.execute_query("SELECT DISTINCT %s FROM Fonts ORDER BY %s;".printf(keyword, keyword));
            foreach (unowned Sqlite.Statement row in db) {
                int val = row.column_int(0);
                string? type = null;
                if (keyword == "slant")
                    type = ((Slant) val).to_string();
                else if (keyword == "spacing")
                    type = ((Spacing) val).to_string();
                else if (keyword == "weight")
                    type = ((Weight) val).to_string();
                else if (keyword == "width")
                    type = ((Width) val).to_string();
                if (type == null)
                    if (keyword == "slant" || (keyword == "width" && ((Width) val).defined()))
                        type = _("Normal");
                    /* Ignore random widths and weights */
                    else if (keyword == "width" || (keyword == "weight" && !((Weight) val).defined()))
                        continue;
                    else
                        type = _("Regular");
                filter.children.add(new Category(type, type, "emblem-documents-symbolic", "%s WHERE %s=\"%i\";".printf(SELECT_FROM_FONTS, keyword, val), data.index));
            }
        } catch (DatabaseError e) { }
        filter.children.foreach((child) => { child.depth = 1; });
        return filter;
    }

    Category construct_info_filter (Database db, FilterData data) {
        string keyword = data.column.replace("\"", "\\\"").replace("'", "''");
        var name = dgettext(null, data.name);
        var comment = dgettext(null, data.comment);
        var filter = new Category(name, comment, "folder-symbolic", null, data.index);
        try {
            db.execute_query("SELECT DISTINCT [%s] FROM Metadata ORDER BY [%s];".printf(keyword, keyword));
            foreach (unowned Sqlite.Statement row in db) {
                string _type = row.column_text(0);
                string type = dgettext(null, _type);
                filter.children.add(new Category(type, type, "emblem-documents", "%s [%s]=\"%s\";".printf(SELECT_FROM_METADATA_WHERE, keyword, _type), data.index));
            }
        } catch (DatabaseError e) { }
        filter.children.foreach((child) => { child.depth = 1; });
        return filter;
    }

}
