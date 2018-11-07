/* Compare.vala
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

/* TODO : Move to Gtk.ListBox */

namespace FontManager {

    public class CompareControls : BaseControls {

        public signal void color_set ();

        public Gtk.ColorButton fg_color_button { get; set; }
        public Gtk.ColorButton bg_color_button { get; set; }

        public CompareControls () {
            add_button.set_tooltip_text(_("Add selected font to comparison"));
            remove_button.set_tooltip_text(_("Remove selected font from comparison"));
            fg_color_button = new Gtk.ColorButton();
            bg_color_button = new Gtk.ColorButton();
            fg_color_button.set_tooltip_text(_("Select text color"));
            bg_color_button.set_tooltip_text(_("Select background color"));
            fg_color_button.set_title(_("Select text color"));
            bg_color_button.set_title(_("Select background color"));
            box.pack_end(bg_color_button, false, false, 0);
            box.pack_end(fg_color_button, false, false, 0);
            set_default_button_relief(box);
            fg_color_button.color_set.connect(() => { color_set(); });
            bg_color_button.color_set.connect(() => { color_set(); });
        }

        public override void show () {
            fg_color_button.show();
            bg_color_button.show();
            var fg = Gdk.RGBA();
            fg.parse("black");
            var bg = Gdk.RGBA();
            bg.parse("white");
            fg_color_button.set_rgba(fg);
            bg_color_button.set_rgba(bg);
            base.show();
            return;
        }

    }

    /* Most of the presentation and logic in our Compare view is based on
     * Gnome Specimen by Wouter Bolsterlee.
     *
     * https://launchpad.net/gnome-specimen
     */
    public class Compare : AdjustablePreview {

        public signal void color_set ();

        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public Json.Object? samples { get; set; default = null; }
        public Font? selected_font { get; set; default = null; }
        public CompareControls controls { get; private set; }

        public string? preview_text {
            get {
                return _preview_text;
            }
            set {
                _preview_text = value != null ? value : default_preview_text;
            }
        }

        bool have_default_colors = false;
        string _preview_text;
        string default_preview_text;
        Gtk.Box box;
        Gtk.TreeView tree;
        Gtk.ListStore store;
        Gtk.ScrolledWindow scroll;
        Gtk.TreeViewColumn column;
        Gtk.CellRendererText renderer;
        Gdk.RGBA default_fg_color;
        Gdk.RGBA default_bg_color;
        Pango.FontDescription default_desc;

        public Compare () {
            orientation = Gtk.Orientation.VERTICAL;
            preview_text = default_preview_text = get_localized_pangram();
            default_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            tree = new Gtk.TreeView();
            store = new Gtk.ListStore(2, typeof(Pango.FontDescription), typeof(string));
            scroll = new Gtk.ScrolledWindow(null, null);
            controls = new CompareControls();
            controls.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            renderer = new Gtk.CellRendererText();
            column = new Gtk.TreeViewColumn();
            column.pack_start(renderer, true);
            column.set_cell_data_func(renderer, cell_data_func);
            column.set_attributes(renderer, "font-desc", 0, "text", 1, null);
            tree.append_column(column);
            tree.set_model(store);
            tree.set_tooltip_column(1);
            pack_start(controls, false, false, 0);
            add_separator(this, Gtk.Orientation.HORIZONTAL);
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            scroll.add(tree);
            box.pack_start(scroll, true, true, 0);
            pack_end(box, true, true, 0);
            tree.set_headers_visible(false);
            bind_properties();
            connect_signals();
        }

        public override void show () {
            tree.show();
            scroll.show();
            box.show();
            controls.show();
            base.show();
            return;
        }

        void bind_properties () {
            bind_property("foreground_color", controls.fg_color_button, "rgba", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            bind_property("background_color", controls.bg_color_button, "rgba", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            return;
        }

        void connect_signals() {
            /* selection, model, path, currently_selected_path */
            tree.get_selection().set_select_function((s, m, p, csp) => {
                /* Disallow selection of preview rows */
                if (p.get_indices()[0] % 2 == 0) {
                    /* Name row */
                    return true;
                } else {
                    /* Preview row */
                    if (p.prev())
                        s.select_path(p);
                    return false;
                }
            });
            controls.add_selected.connect(() => {
                add_from_string(selected_font.description);
            });
            controls.remove_selected.connect(() => {
                on_remove();
            });
            controls.color_set.connect(() => { color_set(); });
            notify["preview-size"].connect(() => { tree.get_column(0).queue_resize(); });

            style_updated.connect(() => {
                update_default_colors();
            });

            return;
        }

        void update_default_colors () {
            Gtk.StyleContext ctx = get_style_context();
            bool have_fg = ctx.lookup_color("theme_text_color", out default_fg_color);
            bool have_bg = ctx.lookup_color("theme_base_color", out default_bg_color);
            have_default_colors = (have_fg && have_bg);
            return;
        }

        public void add_from_string (string description, GLib.List <string>? checklist = null) {
            Gtk.TreeIter iter;
            Gtk.TreeIter _iter;
            Pango.FontDescription _desc = Pango.FontDescription.from_string(description);
            if (checklist == null || checklist.find_custom(_desc.get_family(), strcmp) != null) {
                store.append(out iter);
                store.set(iter, 0, default_desc, 1, description, -1);
                store.append(out _iter);
                store.set(_iter, 0, _desc, 1, description, -1);
            }
            return;
        }

        void cell_data_func (Gtk.CellLayout layout,
                             Gtk.CellRenderer cell,
                             Gtk.TreeModel model,
                             Gtk.TreeIter treeiter) {
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            cell.set_property("attributes", attrs);
            cell.set_property("ypad", 4);
            Value val;
            model.get_value(treeiter, 1, out val);
            string description = (string) val;
            if (model.get_path(treeiter).get_indices()[0] % 2 == 0) {
                /* Name row */
                if (have_default_colors) {
                    cell.set_property("foreground-rgba", default_fg_color);
                    cell.set_property("background-rgba", default_bg_color);
                }
                cell.set_property("size-points", get_desc_size());
                cell.set_property("weight", 100);
            } else {
                /* Preview row */
                cell.set_property("foreground-rgba", foreground_color);
                cell.set_property("background-rgba", background_color);
                if (samples != null && samples.has_member(description))
                    cell.set_property("text", samples.get_string_member(description));
                else
                    cell.set_property("text", preview_text);
                cell.set_property("size-points", preview_size);
            }
            return;
        }

        public string [] list () {
            string [] results = {};
            /* (model, path, iter) */
            store.foreach((m, p, i) => {
                Value val;
                if (p.get_indices()[0] % 2 == 0)
                    /* Skip name rows */
                    return false;
                m.get_value(i, 1, out val);
                results += (string) val;
                val.unset();
                /* Keep going */
                return false;
                }
            );
            return results;
        }

        void on_remove () {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            tree.get_selection().get_selected(out model, out iter);
            /* NOTE:
             * There is a warning attached to this function (iter_is_valid)
             * about it being slow and only intended for debugging purposes.
             *
             * This particular tree should never grow to the point where this could become an issue.
             */
            if (store.iter_is_valid(iter)) {
                /* NOTE:
                 * Saving a string and using it to reset the iter became necessary
                 * since the iter was always being set to null after calling remove.
                 */
                string iter_as_string = store.get_string_from_iter(iter);
#if VALA_0_36
                store.remove(ref iter);
#else
                store.remove(iter);
#endif
                store.get_iter_from_string(out iter, iter_as_string);
#if VALA_0_36
                bool still_valid = store.remove(ref iter);
#else
                bool still_valid = store.remove(iter);
#endif
                /* Set the cursor to a remaining row instead of having the cursor disappear.
                 * This allows for easy deletion of multiple previews by hitting the remove
                 * button repeatedly.
                 */
                if (still_valid) {
                    /* The treeiter is still valid. This means that another row has "shifted" to
                     * the location the deleted row occupied before. Set the cursor to that row.
                     */
                     store.get_iter_from_string(out iter, iter_as_string);
                     Gtk.TreePath path = model.get_path(iter);
                     if (path != null && path.get_indices()[0] >= 0)
                         tree.set_cursor(path, column, false);
                } else {
                     /* The treeiter is no longer valid. In our case this means the bottom row in
                      * the treeview was deleted. Set the cursor to the new bottom row.
                      */
                    int n_children = model.iter_n_children(null) - 2;
                    if (n_children >= 0) {
                        Gtk.TreePath path = new Gtk.TreePath.from_string(n_children.to_string());
                        tree.get_selection().select_path(path);
                    }
                }
            }
            return;
        }

        double get_desc_size () {
            double desc_size = preview_size;
            if (desc_size <= 10)
                return desc_size;
            else if (desc_size <= 20)
                return desc_size / 1.75;
            else if (desc_size <= 30)
                return desc_size / 2;
            else if (desc_size <= 50)
                return desc_size / 2.25;
            else
                return desc_size / 2.5;
        }

    }

}

