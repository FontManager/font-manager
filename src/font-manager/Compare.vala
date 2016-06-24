/* Compare.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    public class CompareControls : BaseControls {

        public signal void foreground_set (Gdk.RGBA fg_color);
        public signal void background_set (Gdk.RGBA bg_color);

        public Gtk.ColorButton fg_color_button { get; set; }
        public Gtk.ColorButton bg_color_button { get; set; }

        public CompareControls () {
            add_button.set_tooltip_text(_("Add selected font to comparison"));
            remove_button.set_tooltip_text(_("Remove selected font from comparison"));
            var context = get_style_context();
            context.add_class(Gtk.STYLE_CLASS_TOOLBAR);
            context.save();
            fg_color_button = new Gtk.ColorButton.with_rgba(context.get_color(Gtk.StateFlags.NORMAL));
            bg_color_button = new Gtk.ColorButton.with_rgba(context.get_background_color(Gtk.StateFlags.NORMAL));
            context.restore();
            fg_color_button.set_tooltip_text(_("Select text color"));
            bg_color_button.set_tooltip_text(_("Select background color"));
            box.pack_end(bg_color_button, false, false, 0);
            box.pack_end(fg_color_button, false, false, 0);
            set_default_button_relief(box);
            connect_signals();
        }

        public override void show () {
            fg_color_button.show();
            bg_color_button.show();
            base.show();
            return;
        }

        new void connect_signals () {
            fg_color_button.color_set.connect((w) => {
                Idle.add(() => {
                    fg_color_button.queue_draw();
                    foreground_set(w.get_rgba());
                    return false;
                });
            });
            bg_color_button.color_set.connect((w) => {
                Idle.add(() => {
                    bg_color_button.queue_draw();
                    background_set(w.get_rgba());
                    return false;
                });
            });
            return;
        }

    }

    /* Most of the presentation and logic in our Compare view is based on
     * Gnome Specimen by Wouter Bolsterlee.
     *
     * https://launchpad.net/gnome-specimen
     */
    public class Compare : AdjustablePreview {

        public signal void list_modified();
        public signal void color_set();

        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public string font_desc { get; set; default = DEFAULT_FONT; }
        public CompareControls controls { get; private set; }

        public string? preview_text {
            get {
                return _preview_text;
            }
            set {
                _preview_text = value != null ? value : default_preview_text;
            }
        }

        string _preview_text;
        string default_preview_text;
        Gtk.Box box;
        BaseTreeView tree;
        Gtk.ListStore store;
        Gtk.ScrolledWindow scroll;
        Gtk.TreeViewColumn column;
        Gtk.CellRendererText renderer;
        Gdk.RGBA default_fg_color;
        Gdk.RGBA default_bg_color;

        public Compare () {
            orientation = Gtk.Orientation.VERTICAL;
            preview_text = default_preview_text = get_localized_pangram();
            tree = new BaseTreeView();
            tree.name = "FontManagerCompareView";
            store = new Gtk.ListStore(2, typeof(Pango.FontDescription), typeof(string));
            scroll = new Gtk.ScrolledWindow(null, null);
            controls = new CompareControls();
            controls.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            update_default_colors();
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
                if (p.get_indices()[0] % 2 == 0)
                    /* Name row */
                    return true;
                else
                    /* Preview row */
                    Idle.add(() => {
                        if (p.prev())
                            tree.get_selection().select_path(p);
                        return false;
                    });
                    return false;
            });
            controls.add_selected.connect(() => {
                debug("Add selected font to a comparison : %s", font_desc);
                add_from_string(font_desc);
                list_modified();
            });
            controls.remove_selected.connect(() => {
                debug("Remove selected font from comparison : %s", font_desc);
                on_remove();
            });
            controls.foreground_set.connect((rgba) => {
                foreground_color = rgba;
                color_set();
            });
            controls.background_set.connect((rgba) => {
                background_color = rgba;
                color_set();
            });
            style_updated.connect(() => {
                update_default_colors();
            });

            return;
        }

        void update_default_colors () {
            var ctx = get_style_context();
            ctx.save();
            default_fg_color = ctx.get_color(Gtk.StateFlags.NORMAL);
            default_bg_color = ctx.get_background_color(Gtk.StateFlags.NORMAL);
            ctx.restore();
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            if (column != null)
                column.queue_resize();
            return;
        }

        public void add_from_string (string pango_font_description) {
            Gtk.TreeIter iter;
            Gtk.TreeIter _iter;
            Pango.FontDescription desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            Pango.FontDescription _desc = Pango.FontDescription.from_string(pango_font_description);
            store.append(out iter);
            store.set(iter, 0, desc, 1, _desc.to_string(), -1);
            store.append(out _iter);
            store.set(_iter, 0, _desc, 1, _desc.to_string(), -1);
            list_modified();
            return;
        }

        void cell_data_func (Gtk.CellLayout layout,
                             Gtk.CellRenderer cell,
                             Gtk.TreeModel model,
                             Gtk.TreeIter treeiter) {
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            cell.set_property("attributes", attrs);
            if (model.get_path(treeiter).get_indices()[0] % 2 == 0) {
                /* Name row */
                cell.set_property("foreground-rgba", default_fg_color);
                cell.set_property("background-rgba", default_bg_color);
                cell.set_property("size-points", get_desc_size());
                cell.set_property("ypad", 4);
                cell.set_property("scale", 1.0);
            } else {
                /* Preview row */
                cell.set_property("foreground-rgba", foreground_color);
                cell.set_property("background-rgba", background_color);
                cell.set_property("text", preview_text);
                cell.set_property("size-points", preview_size);
                cell.set_property("ypad", 4);
                cell.set_property("scale", 1.1);
            }
            return;
        }

        public string [] list () {
            Gee.HashSet <string> results = new Gee.HashSet <string> ();
            /* (model, path, iter) */
            store.foreach((m, p, i) => {
                Value val;
                if (p.get_indices()[0] % 2 == 0)
                    /* Skip name rows */
                    return false;
                m.get_value(i, 1, out val);
                results.add((string) val);
                val.unset();
                /* Keep going */
                return false;
                }
            );
            return results.to_array();
        }

        void on_remove () {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            tree.get_selection().get_selected(out model, out iter);
            /* Note: There is a warning attached to this function (iter_is_valid) about it being
             * slow and only intended for debugging purposes.
             *
             * This particular tree should never grow to the point where this could become an issue.
             */
            if (store.iter_is_valid(iter)) {
                /* Note: Saving a string and using it to reset the iter became necessary since
                 * the iter was always being set to null after calling remove.
                 */
                string iter_as_string = store.get_string_from_iter(iter);
                store.remove(iter);
                store.get_iter_from_string(out iter, iter_as_string);
                bool still_valid = store.remove(iter);
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
            list_modified();
            return;
        }

    }

}

