/* BrowseTreeView.vala
 *
 * Copyright (C) 2024 Jerry Casiano
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

    public class CellRendererHeader : Gtk.CellRendererText {

        public string style_class { get; set; default = "CharacterMapCount"; }
        public bool render_background { get; set; default = true; }

        construct {
            set_alignment(0.0f, 0.5f);
            set_padding(24, 4);
        }

        public override void snapshot (Gtk.Snapshot snapshot,
                                       Gtk.Widget widget,
                                       Gdk.Rectangle background_area,
                                       Gdk.Rectangle cell_area,
                                       Gtk.CellRendererState flags)
        {
            if (render_background) {
                Gdk.Rectangle a = get_aligned_area(widget, flags, cell_area);
                Gtk.StyleContext ctx = widget.get_style_context();
                Gtk.StateFlags state = ctx.get_state();
                Gtk.Border m = ctx.get_margin();
                a.x += ((state & Gtk.StateFlags.DIR_LTR) != 0) ? m.left : m.right;
                a.y += m.top;
                a.width -= m.left + m.right;
                a.height -= m.top + m.bottom;
                ctx.save();
                ctx.add_class(style_class);
                snapshot.push_opacity(0.9);
                snapshot.render_background(ctx, a.x, a.y, a.width, a.height);
                snapshot.render_frame(ctx, a.x, a.y, a.width, a.height);
                snapshot.pop();
                ctx.restore();
            }
            base.snapshot(snapshot, widget, background_area, cell_area, flags);
            return;
        }

    }

    // XXX: Unfortunately using this deprecated widget is necessary due to serious
    // performance and scrolling issues still present in the current ListView widget.
    //
    // - https://gitlab.gnome.org/GNOME/gtk/-/issues/4717
    // - https://gitlab.gnome.org/GNOME/gtk/-/issues/4751
    //
    // Gtk.Inscription provides significant improvement in layout speed but is still
    // not quite enough to make Gtk.ListView usable for this purpose, initialization
    // and resizing is incredibly slow even with just a few hundred fonts.
    public class BrowseListView : Gtk.TreeView {

        public double preview_size { get; set; default = 16; }
        public string? preview_text { get; set; default = null; }
        public BaseFontModel? font_model { get; protected set; default = null; }

        bool update_required = false;

        Gtk.TreeStore? store = null;

        construct {
            widget_set_name(this, "BrowseListView");
            model = null;
            widget_set_expand(this, true);
            widget_set_margin(this, 12);
            set_enable_tree_lines(true);

            var cell_renderer = new CellRendererHeader();
            insert_column_with_data_func(0, "", cell_renderer, cell_data_func);
            get_column(0).set_expand(true);
            get_selection().set_mode(Gtk.SelectionMode.NONE);
            set_headers_visible(false);
            set_show_expanders(false);
            set_level_indentation(24);
            map.connect(() => {
                if (model == null && store == null)
                    queue_update();
                else if (model == null && store != null)
                    model = store;
                expand_all();
            });
            // XXX : ??? : Unclear why but keeping this model around breaks waterfall
            // rendering in our preview pane. Rendering is done in an Idle callback
            // for each line and rendering all at once seems to somewhat help but also
            // creates lag within the interface when large amounts of fonts are installed
            unmap.connect(() => { model = null; });
            notify["preview-size"].connect(() => { get_column(0).queue_resize(); });
            notify["preview-text"].connect(() => { get_column(0).queue_resize(); });
            notify["font-model"].connect(() => {
                queue_update();
                font_model.items_updated.connect(() => { queue_update(); });
            });
        }

        void queue_update () {
            update_required = true;
            if (font_model != null && this.is_visible())
                update_model();
            return;
        }

        void update_model () {
            store = new Gtk.TreeStore(1, typeof(Json.Object));
            uint item_count = font_model.get_n_items();
            if (item_count < 1)
                return;
            for (int i = 0; i < item_count; i++) {
                var item = font_model.get_item(i);
                assert(item != null);
                Gtk.TreeIter iter;
                store.append(out iter, null);
                store.set(iter, 0, ((Family) item).source_object, -1);
                var child_model = ((FontModel) font_model).get_child_model(item);
                uint child_count = child_model.get_n_items();
                if (child_count < 1)
                    continue;
                for (int c = 0; c < child_count; c++) {
                    var child = child_model.get_item(c);
                    assert(child != null);
                    Gtk.TreeIter child_iter;
                    store.append(out child_iter, iter);
                    store.set(child_iter, 0, ((Font) child).source_object, -1);
                }
            }
            model = store;
            expand_all();
            update_required = false;
            return;
        }

        void cell_data_func (Gtk.TreeViewColumn layout,
                             Gtk.CellRenderer cell,
                             Gtk.TreeModel model,
                             Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, 0, out val);
            var obj = (Json.Object) val.get_boxed();
            if (obj.has_member("style")) {
                string desc = obj.get_string_member("description");
                string? sample = null;
                if (obj.has_member("preview-text"))
                    sample = obj.get_string_member("preview-text");
                Pango.FontDescription font = Pango.FontDescription.from_string(desc);
                font.set_absolute_size(preview_size * Pango.SCALE);
                string? text = preview_text != null && preview_text.strip() != "" ? preview_text :
                               have_valid_preview_text(sample) ? sample : desc;
                cell.set_property("text", text);
                cell.set_property("font-desc", font);
                ((CellRendererHeader) cell).render_background = false;
            } else {
                Pango.FontDescription font = Pango.FontDescription.from_string("");
                font.set_absolute_size(get_parent_font_size() * Pango.SCALE);
                font.set_weight(Pango.Weight.MEDIUM);
                cell.set_property("font-desc", font);
                cell.set_property("text", obj.get_string_member("family"));
                ((CellRendererHeader) cell).render_background = true;
            }
            val.unset();
            return;
        }

        double get_parent_font_size () {
            double desc_size = preview_size;
            if (desc_size <= 10)
                return desc_size + 2;
            else if (desc_size <= 20)
                return desc_size / 1.1;
            else if (desc_size <= 30)
                return desc_size / 1.2;
            else if (desc_size <= 50)
                return desc_size / 1.5;
            else
                return desc_size / 2;
        }

    }

}
