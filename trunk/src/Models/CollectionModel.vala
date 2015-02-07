/* CollectionModel.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    public class CollectionModel : Gtk.TreeStore {

        public Collections collections {
            get {
                return groups;
            }
            set {
                groups = value;
                this.update();
            }
        }

        private Collections groups;

        construct {
            set_column_types({typeof(Object), typeof(string), typeof(string)});
        }

        public void update_group_index () {
            if (groups == null || groups.entries.values == null)
                return;
            foreach (var group in groups.entries.values)
                group.clear_children();
            /* (model, path, iter) */
            this.foreach((m, p, i) => {
                /* Update index */
                Value child;
                m.get_value(i, CollectionColumn.OBJECT, out child);
                var depth = p.get_depth();
                var indices = p.get_indices();
                /* This means we got an empty row, ignore this call */
                if (((Collection) child) == null) {
                    child.unset();
                    return false;
                }
                ((Collection) child).index = indices[depth-1];
                /* Bail if this is a root node */
                if (depth <= 1) {
                    /* In case this wasn't a root node before, make it a root node */
                    if (!(groups.entries.has_key(((Collection) child).name)))
                        groups.entries[((Collection) child).name] = ((Collection) child);
                    return false;
                }
                /* Have a child node, need to add it to its parent */
                Value parent;
                Gtk.TreeIter piter;
                m.iter_parent(out piter, i);
                m.get_value(piter, CollectionColumn.OBJECT, out parent);
                ((Collection) parent).children.add(((Collection) child));
                /* In case this used to be a root node */
                if (groups.entries.has_key(((Collection) child).name))
                    groups.entries.unset(((Collection) child).name);
                parent.unset();
                child.unset();
                return false;
            });
        }

        private Gee.ArrayList <Collection> sort_groups (Gee.Collection <Collection> groups) {
            var sorted = new Gee.ArrayList <Collection> ();
            sorted.add_all(groups);
            sorted.sort((CompareDataFunc) sort_on_index);
            return sorted;
        }

        /* XXX */
        public void update () {
            clear();
            if (groups == null || groups.entries.values == null)
                return;
            var sorted = sort_groups(groups.entries.values);
            foreach (var group in sorted) {
                Gtk.TreeIter iter;
                this.append(out iter, null);
                this.set(iter, 0, group, 2, group.comment, -1);
                insert_children(group.children, iter);
            }
            return;
        }

        public void init () {
            update();
            return;
        }

        private void insert_children (Gee.ArrayList <Filter> groups, Gtk.TreeIter parent) {
            var sorted = sort_groups(groups);
            foreach(var child in sorted) {
                Gtk.TreeIter _iter;
                this.append(out _iter, parent);
                this.set(_iter, 0, child, 1, child.comment, -1);
                insert_children(child.children, _iter);
            }
        }

    }

}
