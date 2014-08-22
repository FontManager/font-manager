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

    public class MainSideBar : Gtk.Stack {

        public signal void collection_selected (Collection group);
        public signal void category_selected (Category filter, int category);
        public signal void mode_selected (MainSideBarMode mode);

        public Collection? selected_collection { get; protected set; default = null; }
        public Category? selected_category { get; protected set; default = null; }

        public MainSideBarMode mode {
            get {
                return _mode;
            }
            set {
                _mode = value;
                selector.mode = value;
            }
        }

        public CategoryTree category_tree { get; private set; }
        public CollectionTree collection_tree { get; private set; }
        public UserSourceTree user_source_tree { get; private set; }

        ModeSelector selector;
        MainSideBarMode _mode;
        Gtk.Revealer revealer1;

        public MainSideBar () {
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            selector = new ModeSelector();
            var notebook = new Gtk.Notebook();
            category_tree = new CategoryTree();
            collection_tree = new CollectionTree();
            user_source_tree = new UserSourceTree();

            var collection_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            revealer1 = new Gtk.Revealer();
            revealer1.hexpand = true;
            revealer1.vexpand = false;
            var _box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            _box.pack_start(collection_tree.controls, false, true, 0);
            add_separator(_box, Gtk.Orientation.HORIZONTAL);
            revealer1.add(_box);
            collection_box.pack_start(revealer1, false, true, 0);
            collection_box.pack_end(collection_tree, true, true, 0);

            /* XXX : Fixme : This doesn't belong here. Move to main stack */
            var source_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            source_box.pack_start(user_source_tree.controls, false, true, 0);
            add_separator(source_box, Gtk.Orientation.HORIZONTAL);
            source_box.pack_end(user_source_tree, true, true, 0);

            notebook.append_page(category_tree, new Gtk.Label(_("Categories")));
            notebook.append_page(collection_box, new Gtk.Label(_("Collections")));
            selector.notebook = notebook;
            mode = MainSideBarMode.CATEGORY;
            var blend = new Gtk.EventBox();
            selector.border_width = 4;
            blend.add(selector);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);

            main_box.pack_end(blend, false, true, 0);
            var separator = add_separator(main_box, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            separator.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            separator.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            main_box.pack_start(notebook, true, true, 0);
            collection_box.show_all();
            category_tree.show();
            notebook.show();
            selector.show();
            blend.show();
            main_box.show();
            user_source_tree.show();
            source_box.show();
            add_named(main_box, "Default");
            add_named(source_box, "Sources");
            set_visible_child_name("Default");
            set_transition_type(Gtk.StackTransitionType.CROSSFADE);
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
                }
            );
            collection_tree.selection_changed.connect((g) => {
                collection_selected(g);
                selected_collection = g;
                }
            );

            selector.selection_changed.connect((i) => {
                mode = (MainSideBarMode) i;
                mode_selected(mode);
                }
            );
            return;
        }

    }

}
