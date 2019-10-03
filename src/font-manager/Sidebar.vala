/* Sidebar.vala
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-sidebar.ui")]
    public class Sidebar : Gtk.Stack {

        public string mode {
            get {
                return get_visible_child_name();
            }
            set {
                set_visible_child_name(value);
            }
        }

        public StandardSidebar? standard {
            get {
                return (StandardSidebar) get_child_by_name("Standard");
            }
        }

        public OrthographyList? orthographies {
            get {
                return (OrthographyList) get_child_by_name("Orthographies");
            }
        }

        public CategoryModel? category_model {
            get {
                return standard.category_tree.model;
            }
            set {
                standard.category_tree.model = value;
            }
        }

        public CollectionModel? collection_model {
            get {
                return standard.collection_tree.model;
            }
            set {
                standard.collection_tree.model = value;
            }
        }

        public override void constructed () {
            add_view(new FontManager.StandardSidebar(), "Standard");
            add_view(new FontManager.OrthographyList(), "Orthographies");
            notify["visible-child-name"].connect(() => {
                if (get_visible_child_name() == "Standard")
                    set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
                else
                    set_transition_type(Gtk.StackTransitionType.OVER_RIGHT);
            });
            base.constructed();
            return;
        }

        void add_view (Gtk.Widget sidebar_view, string name) {
            add_named(sidebar_view, name);
            sidebar_view.show();
            return;
        }

    }

    public enum StandardSidebarMode {
        CATEGORY,
        COLLECTION,
        N_MODES
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-standard-sidebar.ui")]
    public class StandardSidebar : Gtk.Box {

        public signal void collection_selected (Collection? group);
        public signal void category_selected (Category filter, int category);
        public signal void mode_selected (StandardSidebarMode mode);

        public Collection? selected_collection { get; protected set; default = null; }
        public Category? selected_category { get; protected set; default = null; }

        public StandardSidebarMode mode {
            get {
                return (StandardSidebarMode) int.parse(sidebar_stack.get_visible_child_name());
            }
            set {
                sidebar_stack.set_visible_child_name(((int) value).to_string());
            }
        }

        public CategoryTree category_tree { get; private set; }
        public CollectionTree collection_tree { get; private set; }

        [GtkChild] Gtk.Stack sidebar_stack;
        [GtkChild] Gtk.Box categories;
        [GtkChild] Gtk.Box collections;
        [GtkChild] Gtk.ScrolledWindow collection_scroll;

        public override void constructed () {
            category_tree = new CategoryTree();
            categories.add(category_tree);
            category_tree.show();
            collection_tree = new CollectionTree();
            collections.pack_start(collection_tree.controls, false, true, 0);
            collection_scroll.add(collection_tree);
            collection_tree.show();

            category_tree.selection_changed.connect((f, i) => {
                category_selected(f, i);
                selected_category = f;

            });
            collection_tree.selection_changed.connect((g) => {
                collection_selected(g);
                selected_collection = g;
            });

            /* XXX : string? pspec? */
            sidebar_stack.notify["visible-child-name"].connect((pspec) => {
                mode_selected(mode);
            });

            mode = StandardSidebarMode.CATEGORY;
            base.constructed();
            return;
        }

    }

}

