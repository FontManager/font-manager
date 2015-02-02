/* Browse.vala
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
 */

namespace FontManager {

    public class Browse : AdjustablePreview {

        public Gtk.TreeStore? model {
            get {
                return _model;
            }
            set {
                _model = value;
                treeview.set_model(_model);
            }
        }

        public FontConfig.Reject reject {
            get {
                return _reject;
            }
            set {
                _reject = value;
            }
        }

        public bool loading {
            get {
                return _loading;
            }
            set {
                _loading = value;
                if (_loading)
                    progress.show();
                else
                    progress.hide();
            }
        }

        public Gtk.ProgressBar progress { get; private set;}
        public Gtk.TreeView treeview { get; private set;}

        private bool _loading = false;
        private Gtk.Box main_box;
        private Gtk.Overlay overlay;
        private Gtk.TreeStore? _model;
        private Gtk.ScrolledWindow scroll;
        private FontConfig.Reject _reject;
        private CellRendererTitle renderer;

        public Browse () {
            base.init();
            orientation = Gtk.Orientation.VERTICAL;
            treeview = new Gtk.TreeView();
            treeview.headers_visible = false;
            treeview.show_expanders = false;
            progress = new Gtk.ProgressBar();
            progress.halign = Gtk.Align.CENTER;
            progress.valign = Gtk.Align.CENTER;
            overlay = new Gtk.Overlay();
            overlay.add_overlay(progress);
            overlay.get_style_context().add_class(Gtk.STYLE_CLASS_ENTRY);
            main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            overlay.add(main_box);
            add(overlay);
            scroll = new Gtk.ScrolledWindow(null, null);
            scroll.add(treeview);
            scroll.expand = true;
            main_box.pack_start(scroll, true, true, 0);
            renderer = new CellRendererTitle();
            renderer.xpad = 48;
            renderer.junction_side = Gtk.JunctionSides.LEFT;
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
            main_box.pack_end(fontscale, false, true, 0);
            treeview.set_enable_search(true);
            treeview.set_search_column(FontModelColumn.DESCRIPTION);
            treeview.insert_column_with_data_func(0, "", renderer, cell_data_func);
            treeview.get_selection().set_mode(Gtk.SelectionMode.NONE);
            expand_all();
        }

        public override void show () {
            treeview.show();
            fontscale.show();
            treeview.show();
            scroll.show();
            main_box.show();
            overlay.show();
            base.show();
            return;
        }

        public void expand_all () {
            treeview.expand_all();
            /* Workaround first row height bug? */
            treeview.get_column(0).queue_resize();
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            treeview.get_column(0).queue_resize();
            return;
        }

        private void cell_data_func (Gtk.TreeViewColumn layout,
                                       Gtk.CellRenderer cell,
                                       Gtk.TreeModel model,
                                       Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            var obj = val.get_object();
            string font_desc;
            bool active;
        #if GTK_316
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            cell.set_property("attributes", attrs);
        #endif
            if (obj is FontConfig.Family) {
                font_desc = ((FontConfig.Family) obj).description;
                active = !(((FontConfig.Family) obj).name in reject);
            } else {
                font_desc = ((FontConfig.Font) obj).description;
                active = !(((FontConfig.Font) obj).family in reject);
            }
            cell.set_property("text", font_desc);
            var default_desc = treeview.get_style_context().get_font(Gtk.StateFlags.NORMAL);
            default_desc.set_size((int) ((get_desc_size()) * Pango.SCALE));
            cell.set_property("font-desc" , default_desc);
            cell.set_property("sensitive" , active);
            cell.set_property("strikethrough", !active);
            if (model.iter_has_child(treeiter)) {
                cell.set_property("title" , font_desc);
                cell.set_property("fallthrough" , false);
            } else {
                Pango.FontDescription desc = Pango.FontDescription.from_string(font_desc);
                desc.set_size((int) (preview_size * Pango.SCALE));
                cell.set_property("font-desc" , desc);
                cell.set_property("ypad" , 5);
                cell.set_property("fallthrough" , true);
            }
            val.unset();
            return;
        }

    }

}

