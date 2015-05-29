/* MainSideBar.vala
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

    public enum MainSideBarMode {
        CATEGORY,
        COLLECTION,
        N_MODES
    }

    public class MainSideBar : Gtk.Box {

        public signal void collection_selected (Collection group);
        public signal void category_selected (Category filter, int category);
        public signal void mode_selected ();

        public Collection? selected_collection { get; protected set; default = null; }
        public Category? selected_category { get; protected set; default = null; }

        public MainSideBarMode mode {
            get {
                return (MainSideBarMode) int.parse(stack.get_visible_child_name());
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

        public MainSideBar () {
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            stack = new Gtk.Stack();
            stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
            switcher = new Gtk.StackSwitcher();
            switcher.set_stack(stack);
            switcher.set_border_width(5);
            switcher.halign = Gtk.Align.CENTER;
            switcher.valign = Gtk.Align.CENTER;
            category_tree = new CategoryTree();
            collection_tree = new CollectionTree();
            var collection_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            revealer1 = new Gtk.Revealer();
            revealer1.hexpand = true;
            revealer1.vexpand = false;
            var _box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            _box.pack_start(collection_tree.controls, false, true, 0);
            revealer1.add(_box);
            collection_box.pack_start(revealer1, false, true, 0);
            collection_box.pack_end(collection_tree, true, true, 0);
            stack.add_titled(category_tree, "0", _("Categories"));
            stack.add_titled(collection_box, "1", _("Collections"));
            mode = MainSideBarMode.CATEGORY;
            var blend = new Gtk.EventBox();
            blend.add(switcher);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            main_box.pack_end(blend, false, true, 0);
            add_separator(main_box, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            main_box.pack_start(stack, true, true, 0);
            collection_box.show_all();
            category_tree.show();
            stack.show();
            switcher.show();
            blend.show();
            main_box.show();
            add(main_box);
            connect_signals();
        }

        public void reveal_collection_controls (bool reveal) {
            revealer1.set_reveal_child(reveal);
            return;
        }

        internal void connect_signals () {
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
