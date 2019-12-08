/* Browse.vala
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

namespace FontManager {

    public enum BrowseMode {
        LIST,
        GRID,
        N_MODES;
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-preview-tile.ui")]
    public class FontPreviewTile : Gtk.Grid {

        [GtkChild] public Gtk.Label family { get; }
        [GtkChild] public Gtk.Label count { get; }
        [GtkChild] public Gtk.TextView preview { get; }

        public override void constructed () {
            preview.event.connect((event) => {
                if (event.type == Gdk.EventType.SCROLL)
                    return false;
                preview.get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
                return true;
            });
            base.constructed();
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-browse-view.ui")]
    public class Browse : Gtk.Box {

        public signal void mode_selected (BrowseMode mode);

        public double preview_size { get; set; }
        public Json.Object? samples { get; set; default = null; }
        public Gtk.Adjustment adjustment { get; set; }

        public Gtk.TreeModel? model { get; set; }

        public BrowseMode mode {
            get {
                return grid_is_visible ? BrowseMode.GRID : BrowseMode.LIST;
            }
            set {
                if (value == BrowseMode.LIST)
                    list_view.set_active(true);
                else
                    grid_view.set_active(true);
            }
        }

        [GtkChild] public Gtk.TreeView treeview { get; }
        [GtkChild] public PreviewEntry entry { get; private set; }

        [GtkChild] FontScale fontscale;
        [GtkChild] Gtk.Stack browse_stack;
        [GtkChild] Gtk.FlowBox flowbox;
        [GtkChild] Gtk.ScrolledWindow browse_grid;
        [GtkChild] Gtk.Label page_count;
        [GtkChild] Gtk.Button prev_page;
        [GtkChild] Gtk.Button next_page;
        [GtkChild] Gtk.RadioButton list_view;
        [GtkChild] Gtk.RadioButton grid_view;
        [GtkChild] Gtk.Box page_controls;
        [GtkChild] Gtk.Entry selected_page;

        double n_pages = 0.0;
        double current_page = 0.0;
        double MAX_TILES = 25.0;
        bool grid_is_visible = false;

        public override void constructed () {
            var renderer = new CellRendererTitle();
            treeview.insert_column_with_data_func(0, "", renderer, cell_data_func);
            treeview.get_selection().set_mode(Gtk.SelectionMode.NONE);
            bind_property("model", treeview, "model", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            bind_property("preview-size", fontscale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            fontscale.bind_property("adjustment", this, "adjustment", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            entry.changed.connect(() => {
                treeview.get_column(0).queue_resize();
                treeview.queue_draw();
                update_grid();
            });
            adjustment.value_changed.connect(() => {
                treeview.get_column(0).queue_resize();
                treeview.queue_draw();
                update_grid();
            });
            notify["model"].connect(() => {
                expand_all();
                n_pages = 1.0;
                current_page = 1.0;
                update_grid();
                if (model != null)
                    n_pages = Math.ceil(model.iter_n_children(null) / MAX_TILES);
                update_page_controls();
            });
            browse_grid.map.connect(() => {
                grid_is_visible = true;
                update_grid();
            });
            browse_grid.unmap.connect(() => {
                grid_is_visible = false;
                update_grid();
            });
            base.constructed();
            return;
        }

        [GtkCallback]
        public void on_click (Gtk.Button button) {
            browse_stack.set_visible_child_name(button.name);
            page_controls.set_visible(button.name == "grid");
            mode_selected(button.name == "grid" ? BrowseMode.GRID : BrowseMode.LIST);
            return;
        }

        [GtkCallback]
        public void on_prev_page_clicked (Gtk.Button button) {
            current_page--;
            update_grid();
            return;
        }

        [GtkCallback]
        public void on_next_page_clicked (Gtk.Button button) {
            current_page++;
            update_grid();
            return;
        }

        [GtkCallback]
        public void on_selected_page_changed (Gtk.Editable entry) {
            double selected = double.parse(((Gtk.Entry) entry).get_text());
            current_page = selected.clamp(1.0, n_pages);
            update_grid();
            return;
        }

        [GtkCallback]
        public bool on_selected_page_focus_in_event (Gtk.Widget entry,
                                                       Gdk.EventFocus unused) {
            selected_page.set_text("");
            return false;
        }

        [GtkCallback]
        public bool on_selected_page_focus_out_event (Gtk.Widget entry,
                                                       Gdk.EventFocus unused) {
            selected_page.set_text("%.f".printf(current_page));
            return false;
        }

        void update_page_controls () {
            selected_page.set_width_chars(n_pages < 100 ? 2 : 3);
            page_count.set_text("/ %.f".printf(n_pages));
            selected_page.set_text("%.f".printf(current_page));
            prev_page.set_sensitive(current_page > 1);
            next_page.set_sensitive(n_pages > 1 && current_page < n_pages);
            return;
        }

        string get_preview_label_markup (Family family) {
            uint n_variations = family.variations.get_length();
            string result = "";
            for (uint i = 0; i < n_variations; i++) {
                if (i > 0)
                    result += "\n";
                Font variation = new Font();
                variation.source_object = family.variations.get_object_element(i);
                string markup = "<span fallback = \"false\" font = \"%s %i\">%s</span>";
                string preview_text = variation.style != null ?
                                       variation.style :
                                       variation.description;
                if (entry.text_length > 0)
                    preview_text = entry.text;
                else if (samples != null && samples.has_member(variation.description))
                    preview_text = samples.get_string_member(variation.description);
                result += markup.printf(variation.description,
                                        (int) preview_size,
                                        Markup.escape_text(preview_text));
            }
            return result;
        }

        [CCode (instance_pos = -1)]
        Gtk.Widget preview_tile_from_item (Family item) {
            var tile = new FontPreviewTile();
            string markup = "<span size=\"%i\"><b>%s</b></span>";
            int title_size = (int) get_desc_size() * Pango.SCALE;
            string title = markup.printf(title_size, Markup.escape_text(item.family));
            tile.family.set_markup(title);
            Gtk.TextBuffer buffer = tile.preview.get_buffer();
            Gtk.TextIter iter;
            buffer.get_start_iter(out iter);
            buffer.insert_markup(ref iter, get_preview_label_markup(item), -1);
            tile.count.set_text(item.variations.get_length().to_string());
            tile.show();
            return tile;
        }

        void update_grid () {
            flowbox.bind_model(null, null);
            if (!grid_is_visible)
                return;
            if (model != null) {
                var list_model = new GLib.ListStore(typeof(Family));
                double end = (current_page * MAX_TILES);
                int start = (current_page == 1) ? 0 : (int) (end - MAX_TILES);
                double current = start;
                Gtk.TreeIter iter;
                bool valid = model.iter_nth_child(out iter, null, start);
                while (valid && current < end) {
                    Value val;
                    model.get_value(iter, FontModelColumn.OBJECT, out val);
                    var temp = (Family) val.get_object();
                    Family family = new Family();
                    family.source_object = new Json.Object();
                    family.source_object.set_string_member("description", temp.description);
                    family.source_object.set_string_member("family", temp.family);
                    int n_children = model.iter_n_children(iter);
                    Json.Array variations = new Json.Array.sized(n_children);
                    Gtk.TreeIter child;
                    for (int i = 0; i < n_children; i++) {
                        model.iter_nth_child(out child, iter, i);
                        Value _val;
                        model.get_value(child, FontModelColumn.OBJECT, out _val);
                        var _var = (Font) _val.get_object();
                        var variation = new Json.Object();
                        variation.set_string_member("style", _var.style);
                        variation.set_string_member("description", _var.description);
                        variations.add_object_element(variation);
                    }
                    family.source_object.set_array_member("variations", variations);
                    list_model.append(family);
                    valid = model.iter_next(ref iter);
                    current++;
                }
                flowbox.bind_model(list_model, (Gtk.FlowBoxCreateWidgetFunc) preview_tile_from_item);
                update_page_controls();
            }
            flowbox.queue_resize();
            return;
        }

        void expand_all () {
            treeview.expand_all();
            /* Workaround first row height bug? */
            treeview.get_column(0).queue_resize();
            return;
        }

        void cell_data_func (Gtk.TreeViewColumn layout,
                             Gtk.CellRenderer cell,
                             Gtk.TreeModel model,
                             Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            Object obj = val.get_object();
            string font_desc;
            bool active;
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            cell.set_property("attributes", attrs);
            Pango.FontDescription default_desc = get_font(treeview);
            default_desc.set_size((int) ((get_desc_size()) * Pango.SCALE));
            cell.set_property("font-desc" , default_desc);
            if (obj is Family) {
                font_desc = ((Family) obj).family;
                active = !(((Family) obj).family in reject);
                cell.set_property("title" , font_desc);
                cell.set_padding(24, 8);
                ((CellRendererPill) cell).render_background = true;
            } else {
                ((CellRendererPill) cell).render_background = false;
                font_desc = ((Font) obj).description;
                active = !(((Font) obj).family in reject);
                Pango.FontDescription desc = Pango.FontDescription.from_string(font_desc);
                desc.set_size((int) (preview_size * Pango.SCALE));
                cell.set_property("font-desc" , desc);
                cell.set_padding(32, 10);
                if (entry.text_length > 0)
                    cell.set_property("text", entry.text);
                else if (samples != null && samples.has_member(font_desc))
                    cell.set_property("text", samples.get_string_member(font_desc));
                else
                    cell.set_property("text", font_desc);
            }
            cell.set_property("sensitive" , active);
            cell.set_property("strikethrough", !active);
            val.unset();
            return;
        }

        double get_desc_size () {
            double desc_size = preview_size;
            if (desc_size <= 10)
                return desc_size;
            else if (desc_size <= 20)
                return desc_size / 1.25;
            else if (desc_size <= 30)
                return desc_size / 1.5;
            else if (desc_size <= 50)
                return desc_size / 1.75;
            else
                return desc_size / 2;
        }

    }

}
