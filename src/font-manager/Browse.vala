/* Browse.vala
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


namespace FontManager {

    public class Browse : AdjustablePreview {

        public Gtk.TreeModel? model { get; set; }
        public Json.Object? samples { get; set; default = null; }
        public BaseTreeView treeview { get; private set; }
        public CustomPreviewEntry entry { get; private set; }

        Gtk.EventBox blend;
        Gtk.ScrolledWindow scroll;
        CellRendererTitle renderer;

        public Browse () {
            orientation = Gtk.Orientation.VERTICAL;
            treeview = new BaseTreeView();
            treeview.name = "FontManagerBrowseView";
            treeview.headers_visible = false;
            treeview.show_expanders = false;
            blend = new Gtk.EventBox();
            entry = new CustomPreviewEntry();
            entry.changed.connect(() => { treeview.queue_draw(); });
            blend.add(entry);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            add(blend);
            scroll = new Gtk.ScrolledWindow(null, null);
            scroll.add(treeview);
            scroll.expand = true;
            renderer = new CellRendererTitle();
            treeview.set_enable_search(true);
            treeview.set_search_column(FontModelColumn.DESCRIPTION);
            treeview.set_tooltip_column(FontModelColumn.DESCRIPTION);
            treeview.insert_column_with_data_func(0, "", renderer, cell_data_func);
            treeview.get_selection().set_mode(Gtk.SelectionMode.NONE);
            bind_property("model", treeview, "model", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            notify["model"].connect(() => { expand_all(); });
            adjustment.value_changed.connect(() => {
                treeview.get_column(0).queue_resize();
                treeview.queue_draw();
            });
            add(scroll);
        }

        public override void show () {
            treeview.show();
            scroll.show();
            blend.show();
            entry.show();
            base.show();
            return;
        }

        public void expand_all () {
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
            var obj = val.get_object();
            string font_desc;
            bool active;
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            cell.set_property("attributes", attrs);
            var default_desc = get_font(treeview);
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

