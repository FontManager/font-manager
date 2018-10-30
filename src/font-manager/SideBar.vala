/* SideBar.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

    public class SideBar : Gtk.Stack {

        public string mode {
            get {
                return get_visible_child_name();
            }
            set {
                set_visible_child_name(value);
            }
        }

        public StandardSideBar? standard {
            get {
                return (StandardSideBar) get_child_by_name("Standard");
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

        public SideBar () {
            set_transition_duration(420);
            set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
            add_view(new FontManager.StandardSideBar(), "Standard");
            add_view(new FontManager.OrthographyList(), "Orthographies");
            notify["visible-child-name"].connect(() => {
                if (get_visible_child_name() == "Standard")
                    set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
                else
                    set_transition_type(Gtk.StackTransitionType.OVER_RIGHT);
            });
        }

        void add_view (Gtk.Widget sidebar_view, string name) {
            add_named(sidebar_view, name);
            sidebar_view.show();
            return;
        }

    }

    public enum StandardSideBarMode {
        CATEGORY,
        COLLECTION,
        N_MODES
    }

    public class StandardSideBar : Gtk.Box {

        public signal void collection_selected (Collection group);
        public signal void category_selected (Category filter, int category);
        public signal void mode_selected ();

        public Collection? selected_collection { get; protected set; default = null; }
        public Category? selected_category { get; protected set; default = null; }

        public StandardSideBarMode mode {
            get {
                return (StandardSideBarMode) int.parse(stack.get_visible_child_name());
            }
            set {
                stack.set_visible_child_name(((int) value).to_string());
            }
        }

        public CategoryTree category_tree { get; private set; }
        public CollectionTree collection_tree { get; private set; }

        Gtk.Stack stack;
        Gtk.StackSwitcher switcher;
        Gtk.Box collection_box;
        Gtk.EventBox blend;
        Gtk.ScrolledWindow collection_scroll;
        Gtk.Box main_box;
        Gtk.Widget [] widgets;

        public StandardSideBar () {
            main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            stack = new Gtk.Stack();
            stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
            switcher = new Gtk.StackSwitcher();
            switcher.set_stack(stack);
            switcher.set_border_width(DEFAULT_MARGIN_SIZE / 4);
            switcher.halign = switcher.valign = Gtk.Align.CENTER;
            category_tree = new CategoryTree();
            collection_tree = new CollectionTree();
            collection_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            collection_box.pack_start(collection_tree.controls, false, true, 0);
            add_separator(collection_box);
            collection_scroll = new Gtk.ScrolledWindow(null, null);
            collection_scroll.add(collection_tree);
            collection_box.pack_end(collection_scroll, true, true, 0);
            stack.add_titled(category_tree, "0", _("Categories"));
            stack.add_titled(collection_box, "1", _("Collections"));
            blend = new Gtk.EventBox();
            blend.add(switcher);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            main_box.pack_end(blend, false, true, 0);
            add_separator(main_box, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            main_box.pack_start(stack, true, true, 0);
            add(main_box);
            connect_signals();
            mode = StandardSideBarMode.CATEGORY;
            widgets = { category_tree, collection_tree, collection_box, stack,
                        switcher, blend, main_box, collection_scroll};
        }

        public override void show () {
            foreach (var widget in widgets)
                widget.show();
            base.show();
            return;
        }

        void connect_signals () {
            category_tree.selection_changed.connect((f, i) => {
                category_selected(f, i);
                selected_category = f;

            });
            collection_tree.selection_changed.connect((g) => {
                collection_selected(g);
                selected_collection = g;
            });

            /* XXX : string? pspec? */
            stack.notify["visible-child-name"].connect((pspec) => {
                mode_selected();
            });
            return;
        }

    }

}

