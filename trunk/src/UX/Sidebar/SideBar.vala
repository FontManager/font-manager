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

    public enum SideBarView {
        STANDARD,
        CHARACTER_MAP,
        WEB,
        N_VIEWS
    }

    public class SideBar : Gtk.Overlay {

        public SideBarView mode {
            get {
                return (SideBarView) notebook.get_current_page();
            }
            set {
                notebook.set_current_page((int) value);
            }
        }

        public MainSideBar? standard {
            get {
                return (MainSideBar) notebook.get_nth_page((int) SideBarView.STANDARD);
            }
        }

        public CharacterMapSideBar? character_map {
            get {
                return (CharacterMapSideBar) notebook.get_nth_page((int) SideBarView.CHARACTER_MAP);
            }
        }

        public Gtk.TreeStore? category_model {
            get {
                return standard.category_tree.model;
            }
        }

        public Gtk.TreeStore? collection_model {
            get {
                return standard.collection_tree.model;
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
                ensure_ui_update();
            }
        }

        private bool _loading = false;
        protected Gtk.Notebook notebook;
        private Gtk.Spinner spinner;

        public SideBar () {
            notebook = new Gtk.Notebook();
            notebook.show_tabs = false;
            notebook.show_border = false;
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.hexpand = box.vexpand = true;
            box.pack_start(notebook, true, true, 0);
            spinner = new Gtk.Spinner();
            spinner.halign = Gtk.Align.CENTER;
            spinner.valign = Gtk.Align.CENTER;
            spinner.set_size_request(36, 36);
            add(box);
            add_overlay(spinner);
            notebook.show();
            box.show();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
        }

        public int add_view (Gtk.Widget sidebar_view, SideBarView view) {
            int result = notebook.insert_page(sidebar_view, null, (int) view);
            sidebar_view.show();
            return result;
        }

    }

}

