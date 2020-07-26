/* Categories.vala
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

    public enum CategoryIndex {
        ALL,
        SYSTEM,
        USER,
        N_CORE,
        PANOSE,
        WIDTH,
        WEIGHT,
        SLANT,
        SPACING,
        LICENSE,
        VENDOR,
        FILETYPE,
        N_GENERATED,
        UNSORTED,
        DISABLED,
        LANGUAGE,
        N_DEFAULT_CATEGORIES
    }

    public class CategoryModel : Gtk.TreeStore {

        public signal void update_begin ();
        public signal void update_complete ();

        GLib.List <Category>? categories = null;

        construct {
            set_column_types({typeof(Object), typeof(string), typeof(string), typeof(string) });
        }

        void init_categories () {
            categories = null;
            try {
                Database db = get_database(DatabaseType.BASE);
                categories = get_default_categories(db);
            } catch (DatabaseError e) {
                critical(e.message);
            }
            return;
        }

        void append_category (Category filter) {
            if (filter.index < CategoryIndex.N_CORE) {
                filter.update.begin((obj, res) => {
                    filter.update.end(res);
                    filter.requires_update = false;
                });

            }
            Gtk.TreeIter iter;
            this.append(out iter, null);
            /* Comments are used for tooltips. */
            string comment = Markup.escape_text(filter.comment);
            this.set(iter, 0, filter, 1, filter.icon, 2, filter.name, 3, comment, -1);
            comment = null;
            foreach(var child in filter.children) {
                string child_comment = Markup.escape_text(child.comment);
                Gtk.TreeIter _iter;
                this.append(out _iter, iter);
                this.set(_iter, 0, child, 1, child.icon, 2, child.name, 3, child_comment, -1);
                child_comment = null;
            }
            return;
        }

        public void update () {
            update_begin();
            clear();
            if (categories == null)
                init_categories();
            foreach (var filter in categories) {
                filter.requires_update = true;
                append_category((Category) filter);
            }
            update_complete();
            return;
        }

    }

    public enum CategoryColumn {
        OBJECT,
        ICON,
        NAME,
        COMMENT,
        N_COLUMNS
    }

    public class CategoryTree : Gtk.ScrolledWindow {

        public signal void selection_changed (Category filter, int category);

        public bool update_in_progress { get; set; default = false; }

        public CategoryModel model {
            get {
                return _model;
            }
            set {
                update_in_progress = true;
                _model = value;
                tree.set_model(_model);
                select_first_row();
                _model.update_begin.connect(() => {
                    updating.show();
                });
                _model.update_complete.connect(() => {
                    updating.hide();
                    update_in_progress = false;
                });
            }
        }

        public string selected_iter { get; protected set; default = "0"; }
        public Category? selected_filter { get; protected set; default = null; }
        public LanguageFilter? language_filter { get; set; default = null; }
        public BaseTreeView tree { get; protected set; }
        public Gtk.CellRendererText renderer { get; protected set; }
        public CellRendererCount count_renderer { get; protected set; }
        public Gtk.CellRendererPixbuf pixbuf_renderer { get; protected set; }

        Gtk.Overlay overlay;

        CategoryModel _model;
        PlaceHolder updating;

        public CategoryTree () {
            expand = true;
            overlay = new Gtk.Overlay();
            updating = new PlaceHolder(null, "emblem-synchronizing-symbolic");
            string update_txt = _("Update in progress");
            updating.message = "<b><big>%s</big></b>".printf(update_txt);
            updating.show();
            tree = new BaseTreeView();
            model = new CategoryModel();
            tree.name = "CategoryTree";
            tree.level_indentation = 12;
            renderer = new Gtk.CellRendererText();
            count_renderer = new CellRendererCount();
            pixbuf_renderer = new Gtk.CellRendererPixbuf();
            renderer.set_property("ellipsize", Pango.EllipsizeMode.END);
            renderer.set_property("ellipsize-set", true);
            tree.insert_column_with_data_func(0, "", pixbuf_renderer, pixbuf_cell_data_func);
            tree.insert_column_with_attributes(1, "", renderer, "text", CategoryColumn.NAME, null);
            tree.insert_column_with_data_func(2, "", count_renderer, count_cell_data_func);
            for (int i = 0; i < 3; i++)
                tree.get_column(i).expand = (i == 1);
            tree.set_headers_visible(false);
            tree.show_expanders = false;
            tree.set_tooltip_column(CategoryColumn.COMMENT);
            tree.test_expand_row.connect((t,i,p) => { t.collapse_all(); return false; });
            tree.get_selection().changed.connect(on_selection_changed);
            overlay.add_overlay(updating);
            overlay.add(tree);
            add(overlay);
            tree.show();
            updating.show();
            overlay.show();
        }

        public void select_first_row () {
            tree.get_selection().select_path(new Gtk.TreePath.first());
            return;
        }

        void count_cell_data_func (Gtk.TreeViewColumn layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            /* Don't show count for folders */
            cell.set_property("visible", false);
            if (model.iter_has_child(treeiter))
                return;
            Value val;
            model.get_value(treeiter, CategoryColumn.OBJECT, out val);
            var obj = (Category) val.get_object();
            /* Or dynamic categories */
            if (obj.index < CategoryIndex.N_GENERATED) {
                cell.set_property("count", obj.size);
                cell.set_property("visible", true);
            }
            val.unset();
            return;
        }

        void pixbuf_cell_data_func (Gtk.TreeViewColumn layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, 0, out val);
            var obj = val.get_object();
            if (tree.is_row_expanded(model.get_path(treeiter)))
                cell.set_property("icon-name", "folder-open");
            else
                cell.set_property("icon-name", ((Category) obj).icon);
            val.unset();
            return;
        }

        void update_language_filter_tooltip () {
            Gtk.TreeIter lang_iter;
            var store = (Gtk.TreeStore) model;
            model.iter_nth_child(out lang_iter, null, model.iter_n_children(null) - 1);
            if (language_filter.selected.size == 0) {
                store.set(lang_iter, CategoryColumn.COMMENT, DEFAULT_LANGUAGE_FILTER_COMMENT, -1);
                return;
            }
            StringBuilder builder = new StringBuilder("\n");
            foreach (var lang in language_filter.selected) {
                string language = lang;
                foreach (var orth in Orthographies) {
                    if (orth.name == lang) {
                        language = orth.native;
                        break;
                    }
                }
                builder.append("    %s    \n".printf(language));
            }
            store.set(lang_iter, CategoryColumn.COMMENT, builder.str, -1);
            return;
        }

        void on_selection_changed (Gtk.TreeSelection selection) {
            Gtk.TreeIter iter;
            Gtk.TreeModel model;
            GLib.Value val;
            if (!selection.get_selected(out model, out iter))
                return;
            model.get_value(iter, 0, out val);
            var path = model.get_path(iter);
            selected_filter = ((Category) val);
            val.unset();
            Idle.add(() => {
                bool is_language_filter = (selected_filter.index == CategoryIndex.LANGUAGE);
                if (language_filter != null) {
                    language_filter.settings_button.set_visible(is_language_filter);
                    return false;
                }
                if (is_language_filter) {
                    language_filter = selected_filter as LanguageFilter;
                    overlay.add_overlay(language_filter.settings_button);
                    language_filter.selections_changed.connect(() => {
                        update_language_filter_tooltip();
                    });
                    if (settings != null) {
                        foreach (var entry in settings.get_strv("language-filter-list"))
                            language_filter.add(entry);
                    }
                    language_filter.settings_button.set_visible(is_language_filter);
                }
                return false;
            });

            selection_changed(selected_filter, path.get_indices()[0]);
            if (path.get_depth() < 2) {
                tree.collapse_all();
                tree.expand_to_path(path);
            }
            selected_iter = model.get_string_from_iter(iter);
            /* NOTE :
             * Category updates are delayed till actual selection
             * Depending on size it may take a moment for the category to load
             */
            if (selected_filter.requires_update) {
                Idle.add(() => {
                    if (!selected_filter.requires_update)
                        tree.queue_draw();
                    return selected_filter.requires_update;
                });
                if (selected_filter.index < CategoryIndex.N_GENERATED)
                    selected_filter.update.begin((obj, res) => {
                        selected_filter.update.end(res);
                        selected_filter.requires_update = false;
                    });
                else if (selected_filter.index == CategoryIndex.DISABLED)
                    if (reject != null) {
                        var filter = ((Disabled) selected_filter);
                        filter.update.begin(reject, (obj, res) => {
                            filter.update.end(res);
                            selected_filter.requires_update = false;
                        });

                    }
            }
            return;
        }

    }

    /*  WARNING : Long lines ahead... */

    GLib.List <Category> get_default_categories (Database db) {
        var filters = new GLib.HashTable <string, Category> (str_hash, str_equal);
        filters["All"] = new Category(_("All"), _("All Fonts"), "format-text-bold", "%s;".printf(SELECT_FROM_FONTS));
        filters["All"].index = CategoryIndex.ALL;
        filters["System"] = new Category(_("System"), _("Fonts available to all users"), "computer", "%s owner!=0 AND filepath LIKE '/usr%';".printf(SELECT_FROM_METADATA_WHERE));
        filters["System"].index = CategoryIndex.SYSTEM;
        filters["User"] = new UserFonts();
        filters["User"].index = CategoryIndex.USER;
        filters["Panose"] = construct_panose_filter();
        filters["Panose"].index = CategoryIndex.PANOSE;
        filters["Width"] = construct_attribute_filter(db, _("Width"), _("Grouped by font width"), "width");
        filters["Width"].index = CategoryIndex.WIDTH;
        filters["Weight"] = construct_attribute_filter(db, _("Weight"), _("Grouped by font weight"), "weight");
        filters["Weight"].index = CategoryIndex.WEIGHT;
        filters["Slant"] = construct_attribute_filter(db, _("Slant"), _("Grouped by font angle"), "slant");
        filters["Slant"].index = CategoryIndex.SLANT;
        filters["Spacing"] = construct_attribute_filter(db, _("Spacing"), _("Grouped by font spacing"), "spacing");
        filters["Spacing"].index = CategoryIndex.SPACING;
        filters["License"] = construct_info_filter(db, _("License"), _("Grouped by license type"), "license-type");
        filters["License"].index = CategoryIndex.LICENSE;
        filters["Vendor"] = construct_info_filter(db, _("Vendor"), _("Grouped by vendor"), "vendor");
        filters["Vendor"].index = CategoryIndex.VENDOR;
        filters["Filetype"] = construct_info_filter(db, _("Filetype"), _("Grouped by filetype"), "filetype");
        filters["Filetype"].index = CategoryIndex.FILETYPE;
        filters["Unsorted"] = new Unsorted();
        filters["Unsorted"].index = CategoryIndex.UNSORTED;
        filters["Disabled"] = new Disabled();
        filters["Disabled"].index = CategoryIndex.DISABLED;
        filters["Language"] = new LanguageFilter();
        filters["Language"].index = CategoryIndex.LANGUAGE;
        var sorted_filters = new GLib.List <Category> ();
        foreach (Category category in filters.get_values())
            sorted_filters.prepend(category);
        sorted_filters.sort_with_data((CompareDataFunc) filter_sort);
        return sorted_filters;
    }

    Category construct_panose_filter () {
        var panose = new Category(_("Family Kind"), _("Only fonts which include Panose information will be grouped here."), "folder", "%s P0 IS NOT NULL;".printf(SELECT_FROM_PANOSE_WHERE));
        string [] kind = { _("Any"), _("No Fit"), _("Text and Display"), _("Script"), _("Decorative"), _("Pictorial") };
        for (int i = 0; i < kind.length; i++)
            panose.children.prepend(new Category(kind[i], kind[i], "emblem-documents", "%s P0 = '%i';".printf(SELECT_FROM_PANOSE_WHERE, i)));
        panose.children.reverse();
        return panose;
    }

    Category construct_attribute_filter (Database db, string name, string comment, string keyword) {
        var filter = new Category(name, comment, "folder", "%s;".printf(SELECT_FROM_FONTS));
        try {
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
                filter.children.prepend(new Category(type, type, "emblem-documents", "%s WHERE %s=\"%i\";".printf(SELECT_FROM_FONTS, keyword, val)));
            }
            filter.children.reverse();
        } catch (DatabaseError e) { }
        return filter;
    }

    Category construct_info_filter (Database db, string name, string comment, string _keyword) {
        string keyword = _keyword.replace("\"", "\\\"").replace("'", "\'");
        var filter = new Category(name, comment, "folder", "%s [%s] IS NOT NULL;".printf(SELECT_FROM_METADATA_WHERE, keyword));
        try {
            db.execute_query("SELECT DISTINCT [%s] FROM Metadata ORDER BY [%s];".printf(keyword, keyword));
            foreach (unowned Sqlite.Statement row in db) {
                string type = row.column_text(0);
                filter.children.prepend(new Category(type, type, "emblem-documents", "%s [%s]=\"%s\";".printf(SELECT_FROM_METADATA_WHERE, keyword, type)));
            }
            filter.children.reverse();
        } catch (DatabaseError e) { }
        return filter;
    }

}
