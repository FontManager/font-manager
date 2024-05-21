/* Categories.vala
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
        LANGUAGE,
        N_CATEGORIES
    }

    public class CategoryListModel : FontListFilterModel {

        public void update_items () {
            uint n_items = get_n_items();
            items = null;
            items = new GenericArray <Category> ();
            items_changed(0, n_items, 0);
            try {
                Database db = new Database();
                items = get_default_categories(db);
                items_changed(0, 0, get_n_items());
                db.close();
            } catch (Error e) {
                critical(e.message);
            }
            return;
        }

        public static ListModel? get_child_model (Object item) {
            var category = ((Category) item);
            if (category.children.length < 1)
                return null;
            var child = new CategoryListModel();
            child.items = category.children;
            return child;
        }

    }

    public class CategoryListRow : TreeListItemRow {

        ulong handler_id = 0;

        protected override void reset () {
            item_label.set_text("");
            item_count.visible = true;
            item_count.set_label("");
            if (handler_id != 0)
                item.disconnect(handler_id);
            return;
        }

        protected override void on_item_set () {
            reset();
            if (item == null)
                return;
            var category = ((Category) item);
            handler_id = category.changed.connect(on_item_set);
            int index = category.index;
            bool root_node = category.depth < 1;
            bool root_count = root_node &&
                              (index < CategoryIndex.PANOSE ||
                               index > CategoryIndex.FILETYPE &&
                               index < CategoryIndex.LANGUAGE);
            item_label.set_text(category.name);
            item_icon.visible = root_count || root_node && index == CategoryIndex.LANGUAGE;
            item_count.visible = !root_node || root_count;
            if (index == CategoryIndex.LANGUAGE)
                item_label.ellipsize = Pango.EllipsizeMode.NONE;
            if (root_node &&
                (index >= CategoryIndex.PANOSE &&
                 index <= CategoryIndex.FILETYPE))
                item_label.margin_start = 3;
            else if (!root_node)
                item_label.margin_start = 0;
            item_icon.set_from_icon_name(category.icon);
            item_count.set_label(category.size.to_string());
            set_tooltip_text(category.comment != null ? category.comment : category.name);
            return;
        }

    }

    public class CategoryListView : FilterListView {

        public Reject? disabled_families { get; set; default = null; }
        public Disabled? disabled { get; set; default = null; }
        public StringSet? sorted { get; set; default = null; }
        public Unsorted? unsorted { get; set; default = null; }

        construct {
            widget_set_name(listview, "FontManagerCategoryListView");
            treemodel = new Gtk.TreeListModel(new CategoryListModel(),
                                              false,
                                              false,
                                              CategoryListModel.get_child_model);
            selection = new Gtk.SingleSelection(treemodel);
            notify["disabled"].connect_after(() => { update_disabled(); });
            notify["sorted"].connect_after(() => { update_unsorted(); });
            notify["disabled-families"].connect_after(() => {
                if (disabled_families != null)
                    disabled_families.changed.connect(() => { update_disabled(); });
                update_disabled();
            });
        }

        public void select_item (uint position) {
            listview.activate_action("list.select-item", "(ubb)", position, false, false);
            listview.activate_action("list.scroll-to-item", "u", position);
            return;
        }

        protected override void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var tree_expander = new Gtk.TreeExpander();
            tree_expander.set_indent_for_icon(false);
            var row = new CategoryListRow();
            row.expander = tree_expander;
            row.selection = selection;
            tree_expander.set_child(row);
            list_item.set_child(tree_expander);
            return;
        }

        void update_disabled () {
            if (disabled == null || disabled_families == null)
                return;
            disabled.update.begin((obj, res) => {
                disabled.update.end(res);
                model.items_changed(0, 0, 0);
                if (selected_item is Disabled) {
                    selection_changed(null);
                    selection_changed(selected_item);
                }
            });
            return;
        }

        void update_unsorted () {
            if (unsorted == null)
                return;
            unsorted.update.begin((obj, res) => {
                unsorted.update.end(res);
                model.items_changed(0, 0, 0);
                if (selected_item is Unsorted) {
                    selection_changed(null);
                    selection_changed(selected_item);
                }
            });
            return;
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.margin_start = 2;
            tree_expander.set_list_row(list_row);
            var row = (CategoryListRow) tree_expander.get_child();
            Object? _item = list_row.get_item();
            // Setting item triggers update to row widgets
            row.item = _item;
            return_if_fail(_item != null);
            var category = ((Category) _item);
            if (category.index < CategoryIndex.PANOSE)
                category.update.begin();
            else if (category is Disabled) {
                disabled = (Disabled) category;
                BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
                bind_property("disabled-families", disabled, "disabled-families", flags);
            }
            else if (category is Unsorted) {
                unsorted = (Unsorted) category;
                BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
                bind_property("sorted", unsorted, "sorted", flags);
                update_unsorted();
            }
            list_row.notify["expanded"].connect_after((pspec) => {
                category.update.begin();
            });
            return;
        }

    }

    //  WARNING : Long lines ahead...

    public const string SELECT_FROM_FONTS = "SELECT DISTINCT family, description FROM Fonts";
    public const string SELECT_FROM_METADATA_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Metadata USING (filepath, findex) WHERE";
    public const string SELECT_FROM_PANOSE_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Panose USING (filepath, findex) WHERE";

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
        filters.add(new LanguageFilter());
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
                    // Ignore random widths and weights
                    else if (keyword == "width" || (keyword == "weight" && !((Weight) val).defined()))
                        continue;
                    else
                        type = _("Regular");
                filter.children.add(new Category(type, type, "emblem-documents-symbolic", "%s WHERE %s=\"%i\";".printf(SELECT_FROM_FONTS, keyword, val), data.index));
            }
            db.end_query();
        } catch (DatabaseError e) {
            warning(e.message);
        }
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
            db.end_query();
        } catch (DatabaseError e) {
            warning(e.message);
        }
        filter.children.foreach((child) => { child.depth = 1; });
        return filter;
    }

}


