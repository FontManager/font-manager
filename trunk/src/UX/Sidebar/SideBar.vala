/* SideBar.vala
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

    public class SideBar : Gtk.Overlay {

        public string mode {
            get {
                return stack.get_visible_child_name();
            }
            set {
                stack.set_visible_child_name(value);
            }
        }

        public MainSideBar? standard {
            get {
            #if GTK_312
                return (MainSideBar) stack.get_child_by_name("Default");
            #else
                return (MainSideBar) stack.get_children().nth_data(0);
            #endif
            }
        }

        public CharacterMapSideBar? character_map {
            get {
            #if GTK_312
                return (CharacterMapSideBar) stack.get_child_by_name("Character Map");
            #else
                return (CharacterMapSideBar) stack.get_children().nth_data(1);
            #endif
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
        private bool _loading = false;
        private Gtk.Spinner spinner;
        private Gtk.Box box;

        public SideBar () {
            stack = new Gtk.Stack();
            stack.set_transition_duration(420);
        #if GTK_312
            stack.set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
        #else
            stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        #endif
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.hexpand = box.vexpand = true;
            box.pack_start(stack, true, true, 0);
            spinner = new Gtk.Spinner();
            spinner.halign = Gtk.Align.CENTER;
            spinner.valign = Gtk.Align.CENTER;
            spinner.set_size_request(48, 48);
            add(box);
            add_overlay(spinner);
            get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            spinner.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            stack.notify["visible-child-name"].connect(() => {
            #if GTK_312
                if (stack.get_visible_child_name() == "Default")
                    stack.set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
                else
                    stack.set_transition_type(Gtk.StackTransitionType.OVER_RIGHT);
            #endif
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

}

