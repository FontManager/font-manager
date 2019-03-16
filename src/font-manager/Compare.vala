/* Compare.vala
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

/* TODO : Move to Gtk.ListBox */

namespace FontManager {

    /* Most of the presentation and logic in our Compare view is based on
     * Gnome Specimen by Wouter Bolsterlee.
     *
     * https://launchpad.net/gnome-specimen
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-compare-view.ui")]
    public class Compare : Gtk.Box {

        public signal void color_set ();

        public double preview_size { get; set; }
        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public Gtk.Adjustment adjustment { get; set; }
        public Json.Object? samples { get; set; default = null; }
        public Font? selected_font { get; set; default = null; }

        [GtkChild] public PreviewEntry entry { get; }
        [GtkChild] public FontScale fontscale { get; }
        [GtkChild] public Gtk.ColorButton bg_color_button { get; }
        [GtkChild] public Gtk.ColorButton fg_color_button { get; }

        public string? preview_text {
            get {
                return _preview_text;
            }
            set {
                _preview_text = value != null ? value : default_preview_text;
            }
        }

        [GtkChild] Gtk.Box controls;
        [GtkChild] Gtk.Button add_button;
        [GtkChild] Gtk.Button remove_button;
        [GtkChild] Gtk.TreeView treeview;

        bool have_default_colors = false;
        string _preview_text;
        string default_preview_text;
        Gtk.ListStore store;
        Gtk.TreeViewColumn column;
        Gtk.CellRendererText renderer;
        Gdk.RGBA default_fg_color;
        Gdk.RGBA default_bg_color;
        Pango.FontDescription default_desc;

        public override void constructed () {
            preview_text = default_preview_text = get_localized_pangram();
            default_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            store = new Gtk.ListStore(2, typeof(Pango.FontDescription), typeof(string));
            entry.set_placeholder_text(preview_text);
            renderer = new Gtk.CellRendererText();
            column = new Gtk.TreeViewColumn();
            column.pack_start(renderer, true);
            column.set_cell_data_func(renderer, cell_data_func);
            column.set_attributes(renderer, "font-desc", 0, "text", 1, null);
            treeview.append_column(column);
            treeview.set_model(store);
            set_default_button_relief(controls);
            bind_properties();
            connect_signals();
            base.constructed();
            return;
        }

        void bind_properties () {
            bind_property("foreground_color", fg_color_button, "rgba", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            bind_property("background_color", bg_color_button, "rgba", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            bind_property("preview-size", fontscale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            fontscale.bind_property("adjustment", this, "adjustment", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            return;
        }

        void connect_signals() {
            /* selection, model, path, currently_selected_path */
            treeview.get_selection().set_select_function((s, m, p, csp) => {
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
            add_button.clicked.connect(() => {
                add_from_string(selected_font.description);
            });
            remove_button.clicked.connect(() => {
                on_remove();
            });
            bg_color_button.color_set.connect(() => { color_set(); });
            fg_color_button.color_set.connect(() => { color_set(); });
            notify["preview-size"].connect(() => { treeview.get_column(0).queue_resize(); });

            style_updated.connect(() => {
                update_default_colors();
            });

            entry.changed.connect(() => { treeview.queue_draw(); });
            notify["preview-text"].connect(() => {
                entry.set_placeholder_text(preview_text);
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
                cell.set_property("weight", 400);
            } else {
                /* Preview row */
                cell.set_property("foreground-rgba", foreground_color);
                cell.set_property("background-rgba", background_color);
                if (entry.text_length > 0)
                    cell.set_property("text", entry.text);
                else if (samples != null && samples.has_member(description))
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
            treeview.get_selection().get_selected(out model, out iter);
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
                store.remove(ref iter);
                store.get_iter_from_string(out iter, iter_as_string);
                bool still_valid = store.remove(ref iter);
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
                         treeview.set_cursor(path, column, false);
                } else {
                     /* The treeiter is no longer valid. In our case this means the bottom row in
                      * the treeview was deleted. Set the cursor to the new bottom row.
                      */
                    int n_children = model.iter_n_children(null) - 2;
                    if (n_children >= 0) {
                        Gtk.TreePath path = new Gtk.TreePath.from_string(n_children.to_string());
                        treeview.get_selection().select_path(path);
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
