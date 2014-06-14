/* CategoryModel.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    public class CategoryModel : Gtk.TreeStore {

        public unowned Database database {
            get {
                return db;
            }
            set {
                db = value;
                categories = get_default_categories(db);
                update();
            }
        }

        internal Gee.ArrayList <Category> categories;
        internal unowned Database db;

        construct {
            set_column_types({typeof(Object), typeof(string), typeof(string), typeof(string), typeof(int), typeof(bool)});
        }

        public void update () {
            clear();
            foreach (var filter in categories) {
                filter.update(db);
                Gtk.TreeIter iter;
                this.append(out iter, null);
                if (filter.index < 3)
                    this.set(iter, 0, filter, 1, filter.icon, 2, filter.name, 3, filter.comment, 4, filter.families.size, -1);
                else
                    this.set(iter, 0, filter, 1, filter.icon, 2, filter.name, 3, filter.comment, 4, filter.families.size, 5, true, -1);
                foreach(var child in filter.children) {
                    Gtk.TreeIter _iter;
                    this.append(out _iter, iter);
                    this.set(_iter, 0, child, 1, child.icon, 2, child.name, 3, child.comment, 4, child.families.size, -1);
                }
            }
            return;
        }

    }

    Gee.ArrayList <Category> get_default_categories (Database db) {
        var filters = new Gee.HashMap <string, Category> ();
        filters["All"] = new Category(_("All"), _("All Fonts"), "format-text-bold", null);
        filters["All"].index = 0;
        filters["System"] = new Category(_("System"), _("Fonts available to all users"), "computer", "owner!=0");
        filters["System"].index = 1;
        filters["User"] = new Category(_("User"), _("Fonts avalable only to you"), "avatar-default", "owner=0");
        filters["User"].index = 2;
        filters["Panose"] = construct_panose_filter();
        filters["Panose"].index = 3;
        filters["Spacing"] = construct_filter(db, _("Spacing"), _("Grouped by font spacing"), "spacing");
        filters["Spacing"].index = 4;
        filters["Slant"] = construct_filter(db, _("Slant"), _("Grouped by font angle"), "slant");
        filters["Slant"].index = 5;
        filters["Weight"] = construct_filter(db, _("Weight"), _("Grouped by font weight"), "weight");
        filters["Weight"].index = 6;
        filters["Width"] = construct_filter(db, _("Width"), _("Grouped by font width"), "width");
        filters["Width"].index = 7;
        filters["Filetype"] = construct_filter(db, _("Filetype"), _("Grouped by filetype"), "filetype");
        filters["Filetype"].index = 8;
        filters["License"] = construct_filter(db, _("License"), _("Grouped by license type"), "license_type");
        filters["License"].index = 9;
        filters["Vendor"] = construct_filter(db, _("Vendor"), _("Grouped by vendor"), "vendor");
        filters["Vendor"].index = 10;
        filters["Unsorted"] = new Unsorted();
        filters["Unsorted"].index = 11;
        var sorted_filters = new Gee.ArrayList <Category> ();
        sorted_filters.add_all(filters.values);
        sorted_filters.sort((CompareDataFunc) sort_on_index);
        return sorted_filters;
    }

    Category construct_panose_filter () {
        var panose = new Category(_("Family Kind"), _("Only fonts which include Panose information will be grouped here."), "folder", "panose IS NOT NULL");
        panose.children.add(new Category(_("Any"), _("Any"), "emblem-documents", "panose LIKE \"0:%\""));
        panose.children.add(new Category(_("No Fit"), _("No Fit"), "emblem-documents", "panose LIKE \"1:%\""));
        panose.children.add(new Category(_("Text and Display"), _("Text and Display"), "emblem-documents", "panose LIKE \"2:%\""));
        panose.children.add(new Category(_("Script"), _("Script"), "emblem-documents", "panose LIKE \"3:%\""));
        panose.children.add(new Category(_("Decorative"), _("Decorative"), "emblem-documents", "panose LIKE \"4:%\""));
        panose.children.add(new Category(_("Pictorial"), _("Pictorial"), "emblem-documents", "panose LIKE \"5:%\""));
        return panose;
    }

    Category construct_filter (Database db, string name, string comment, string keyword) {
        var filter = new Category(name, comment, "folder", null);
        try {
            add_children_from_db_results(db, filter.children, keyword);
        } catch (DatabaseError e) {
            warning("Failed to create child categories for %s", name);
            error("Database error : %s", e.message);
        }
        return filter;
    }

    void add_children_from_db_results (Database db, Gee.ArrayList <Category> filters, string keyword) throws DatabaseError {
        db.execute_query("SELECT DISTINCT %s FROM Fonts ORDER BY %s;".printf(keyword, keyword));
        foreach (var row in db) {
            if (row.column_type(0) == Sqlite.TEXT) {
                var type = row.column_text(0);
                filters.add(new Category(type, type, "emblem-documents", "%s='%s'".printf(keyword, type)));
            } else {
                string type;
                var val = row.column_int(0);
                if (keyword == "slant")
                    type = ((FontConfig.Slant) val).to_string();
                else if (keyword == "weight")
                    type = ((FontConfig.Weight) val).to_string();
                else if (keyword == "width")
                    type = ((FontConfig.Width) val).to_string();
                else
                    type = ((FontConfig.Spacing) val).to_string();
                if (type == null)
                    if (keyword == "slant" || keyword == "width")
                        type = _("Normal");
                    else
                        type = _("Regular");
                filters.add(new Category(type, type, "emblem-documents", "%s='%i'".printf(keyword, val)));
            }
        }
    }

}

