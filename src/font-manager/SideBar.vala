/* SideBar.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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

    public class SideBar : Gtk.Overlay {

        public string mode {
            get {
                return stack.get_visible_child_name();
            }
            set {
                stack.set_visible_child_name(value);
            }
        }

        public StandardSideBar? standard {
            get {
                return (StandardSideBar) stack.get_child_by_name("Default");
            }
        }

        public CharacterMapSideBar? character_map {
            get {
                return (CharacterMapSideBar) stack.get_child_by_name("Character Map");
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

        public bool loading {
            get {
                return _loading;
            }
            set {
                if (value) {
                    spinner.start();
                    spinner.show();
                } else {
                    spinner.hide();
                    spinner.stop();
                }
            }
        }

        protected Gtk.Stack stack;
        bool _loading = false;
        Gtk.Spinner spinner;
        Gtk.Box box;

        public SideBar () {
            stack = new Gtk.Stack();
            stack.set_transition_duration(420);
            stack.set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.expand = true;
            box.pack_start(stack, true, true, 0);
            spinner = new Gtk.Spinner();
            spinner.halign = Gtk.Align.CENTER;
            spinner.valign = Gtk.Align.CENTER;
            spinner.set_size_request(48, 48);
            add(box);
            add_overlay(spinner);
            get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            spinner.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            stack.notify["visible-child-name"].connect(() => {
                if (stack.get_visible_child_name() == "Default")
                    stack.set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
                else
                    stack.set_transition_type(Gtk.StackTransitionType.OVER_RIGHT);
            });
        }

        public override void show () {
            stack.show();
            box.show();
            base.show();
            return;
        }

        public void add_view (Gtk.Widget sidebar_view, string name) {
            stack.add_named(sidebar_view, name);
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
        Gtk.Revealer revealer1;
        Gtk.Box collection_box;
        Gtk.Box _box;
        Gtk.EventBox blend;
        Gtk.Box main_box;

        public StandardSideBar () {
            main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            stack = new Gtk.Stack();
            stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
            switcher = new Gtk.StackSwitcher();
            switcher.set_stack(stack);
            switcher.set_border_width(6);
            switcher.halign = Gtk.Align.CENTER;
            switcher.valign = Gtk.Align.CENTER;
            category_tree = new CategoryTree();
            collection_tree = new CollectionTree();
            collection_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            revealer1 = new Gtk.Revealer();
            revealer1.expand = false;
            _box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            _box.pack_start(collection_tree.controls, false, true, 0);
            revealer1.add(_box);
            collection_box.pack_start(revealer1, false, true, 0);
            collection_box.pack_end(collection_tree, true, true, 0);
            stack.add_titled(category_tree, "0", _("Categories"));
            stack.add_titled(collection_box, "1", _("Collections"));
            mode = StandardSideBarMode.CATEGORY;
            blend = new Gtk.EventBox();
            blend.add(switcher);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            main_box.pack_end(blend, false, true, 0);
            add_separator(main_box, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            main_box.pack_start(stack, true, true, 0);
            add(main_box);
            connect_signals();
        }

        public override void show () {
            _box.show();
            revealer1.show();
            collection_tree.show();
            collection_box.show();
            category_tree.show();
            stack.show();
            switcher.show();
            blend.show();
            main_box.show();
            base.show();
            return;
        }

        public void reveal_collection_controls (bool reveal) {
            revealer1.set_reveal_child(reveal);
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

