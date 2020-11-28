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
        LANGUAGE
    }

    public class CategoryModel : Gtk.TreeStore {

        public signal void update_begin ();
        public signal void update_complete ();

        public GenericArray <Category>? categories { get; set; default = null; }

        public CategoryModel () {
            set_column_types({typeof(Object), typeof(string), typeof(string), typeof(string) });
            categories = new GenericArray <Category> ();
            notify["categories"].connect(() => {
                clear();
                if (categories != null)
                    categories.foreach((filter) => {
                        filter.requires_update = true;
                        append_category((Category) filter);
                    });
            });
        }

        void append_category (Category filter) {
            if (filter.index < CategoryIndex.PANOSE) {
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
            filter.children.foreach((child) => {
                string child_comment = Markup.escape_text(child.comment);
                Gtk.TreeIter _iter;
                this.append(out _iter, iter);
                this.set(_iter, 0, child, 1, child.icon, 2, child.name, 3, child_comment, -1);
                child_comment = null;
            });
            return;
        }

        public void update () {
            update_begin();
            clear();
            categories = null;
            try {
                Database db = get_database(DatabaseType.BASE);
                categories = get_default_categories(db);
            } catch (DatabaseError e) {
                critical(e.message);
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
        public signal void update_complete ();

        public bool update_in_progress { get; set; default = true; }

        public CategoryModel model { get; set; }

        public string selected_iter { get; protected set; default = "0"; }
        public Category? selected_filter { get; protected set; default = null; }
        public LanguageFilter? language_filter { get; set; default = null; }
        public LanguageFilterSettings language_filter_settings { get; private set; }
        public BaseTreeView tree { get; protected set; }
        public Gtk.CellRendererText renderer { get; protected set; }
        public CellRendererCount count_renderer { get; protected set; }
        public Gtk.CellRendererPixbuf pixbuf_renderer { get; protected set; }

        Gtk.Overlay overlay;

        bool refresh_required = false;
        PlaceHolder updating;

        public CategoryTree () {
            expand = true;
            overlay = new Gtk.Overlay();
            updating = new PlaceHolder(null, null, _("Update in progress"), "emblem-synchronizing-symbolic");
            updating.show();
            tree = new BaseTreeView() {
                name = "CategoryTree",
                level_indentation = 12,
                headers_visible = false,
                show_expanders = false,
                tooltip_column = CategoryColumn.COMMENT
            };
            model = new CategoryModel();
            tree.set_model(model);
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
            tree.test_expand_row.connect((t,i,p) => { t.collapse_all(); return false; });
            tree.get_selection().changed.connect(on_selection_changed);
            language_filter_settings = new LanguageFilterSettings();
            notify["model"].connect(() => {
                tree.set_model(model);
                tree.queue_draw();
                model.update_begin.connect(() => {
                    update_in_progress = true;
                    updating.show();
                });
                model.update_complete.connect(() => {
                    updating.hide();
                    update_in_progress = false;
                    update_complete();
                });
            });
            db.update_started.connect(() => { refresh_required = true; });
            db.status_changed.connect(() => {
                if (refresh_required && db.ready(DatabaseType.METADATA)) {
                    refresh_required = false;
                    update();
                }
            });
            db.update_complete.connect(() => {
                if (refresh_required) {
                    refresh_required = false;
                    update();
                }
            });
            overlay.add_overlay(updating);
            overlay.add(tree);
            add(overlay);
            tree.show();
            updating.show();
            overlay.show();
        }

        public static string get_cache_file () {
            string dirpath = get_package_cache_directory();
            string filepath = Path.build_filename(dirpath, "Categories.cache");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        public void save () {
            Json.Array cache = new Json.Array();
            model.categories.foreach((child) => {
                cache.add_element(Json.gobject_serialize(child));
            });
            Json.Node node = new Json.Node(Json.NodeType.ARRAY);
            node.set_array(cache);
            write_json_file(node, get_cache_file(), false);
            return;
        }

        public bool load () {
            string cache_file = get_cache_file();
            if (!exists(cache_file))
                return false;
            Json.Node? root = load_json_file(cache_file);
            if (root != null) {
                Json.Array array = root.get_array();
                model.update_begin();
                var categories = new GenericArray <Category> ();
                array.foreach_element((arr, index, node) => {
                    var category = (Category) Json.gobject_deserialize(typeof(Category), node);
                    categories.insert((int) index, category);
                });
                model.categories = categories;
                model.update_complete();
                notify_property("model");
            }
            return true;
        }

        public void select_first_row () {
            if (model == null)
                return;
            Gtk.TreePath path = new Gtk.TreePath.first();
            Gtk.TreeSelection selection = tree.get_selection();
            selection.unselect_all();
            selection.select_path(path);
            if (selection.path_is_selected(path))
                tree.scroll_to_cell(path, null, true, 0.5f, 0.5f);
            return;
        }

        public void update () {
            /* Re-select category after an update to prevent blank list */
            if (selected_filter != null) {
                int index = selected_filter.index;
                var path = new Gtk.TreePath.from_indices(index, -1);
                var selection = tree.get_selection();
                selection.unselect_all();
                model.update();
                selection.select_path(path);
            } else {
                model.update();
                select_first_row();
            }
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
            if (obj.index < CategoryIndex.UNSORTED) {
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
            language_filter.selected.sort((CompareFunc) natural_sort);
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
                    language_filter_settings.get_button().set_visible(is_language_filter);
                    return GLib.Source.REMOVE;
                }
                if (is_language_filter) {
                    language_filter = selected_filter as LanguageFilter;
                    overlay.add_overlay(language_filter_settings.get_button());
                    language_filter.selections_changed.connect(() => {
                        update_language_filter_tooltip();
                    });
                    language_filter.bind_property("selected", language_filter_settings, "selected", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
                    language_filter.bind_property("coverage", language_filter_settings, "coverage", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
                    language_filter_settings.selections_changed.connect(() => {
                        language_filter.update.begin((obj, res) => {
                            language_filter.update.end(res);
                            language_filter.selections_changed();
                        });
                    });
                    if (settings != null) {
                        foreach (var entry in settings.get_strv("language-filter-list"))
                            language_filter.add(entry);
                    }
                    language_filter_settings.get_button().set_visible(is_language_filter);
                }
                return GLib.Source.REMOVE;
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
                if (selected_filter.index < CategoryIndex.UNSORTED)
                    selected_filter.update.begin((obj, res) => {
                        selected_filter.update.end(res);
                        selected_filter.requires_update = false;
                    });
            }
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
        { CategoryIndex.VENDOR, N_("Vendor"), N_("Grouped by vendor"), "vendor" },
        { CategoryIndex.FILETYPE, N_("Filetype"), N_("Grouped by filetype"), "filetype" }
    };

    /*  WARNING : Long lines ahead... */

    GenericArray <Category> get_default_categories (Database db) {
        var filters = new GenericArray <Category> ();
        filters.add(new Category(_("All"), _("All Fonts"), "format-text-bold", "%s;".printf(SELECT_FROM_FONTS), CategoryIndex.ALL));
        filters.add(new Category(_("System"), _("Fonts available to all users"), "computer", "%s owner!=0 AND filepath LIKE '/usr%';".printf(SELECT_FROM_METADATA_WHERE), CategoryIndex.SYSTEM));
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
        var panose = new Category(_("Family Kind"), _("Only fonts which include Panose information will be grouped here."), "folder", null, CategoryIndex.PANOSE);
        string [] kind = { _("Any"), _("No Fit"), _("Text and Display"), _("Script"), _("Decorative"), _("Pictorial") };
        for (int i = 0; i < kind.length; i++)
            panose.children.add(new Category(kind[i], kind[i], "emblem-documents", "%s P0 = '%i';".printf(SELECT_FROM_PANOSE_WHERE, i), i));
        return panose;
    }

    Category construct_attribute_filter (Database db, FilterData data) {
        var name = dgettext(null, data.name);
        var comment = dgettext(null, data.comment);
        var filter = new Category(name, comment, "folder", null, data.index);
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
                filter.children.add(new Category(type, type, "emblem-documents", "%s WHERE %s=\"%i\";".printf(SELECT_FROM_FONTS, keyword, val), data.index));
            }
        } catch (DatabaseError e) { }
        return filter;
    }

    Category construct_info_filter (Database db, FilterData data) {
        string keyword = data.column.replace("\"", "\\\"").replace("'", "''");
        var name = dgettext(null, data.name);
        var comment = dgettext(null, data.comment);
        var filter = new Category(name, comment, "folder", null, data.index);
        try {
            db.execute_query("SELECT DISTINCT [%s] FROM Metadata ORDER BY [%s];".printf(keyword, keyword));
            foreach (unowned Sqlite.Statement row in db) {
                string type = row.column_text(0);
                filter.children.add(new Category(type, type, "emblem-documents", "%s [%s]=\"%s\";".printf(SELECT_FROM_METADATA_WHERE, keyword, type), data.index));
            }
        } catch (DatabaseError e) { }
        return filter;
    }

}
