/* Browse.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-font-preview-tile.ui")]
    public class FontPreviewTile : Gtk.Box {

        public Object? item { get; set; default = null; }

        // [GtkChild] public unowned Gtk.Label family { get; }
        // [GtkChild] public unowned Gtk.Label count { get; }
        [GtkChild] public unowned Gtk.Inscription preview { get; }

        construct {
            widget_set_name(this, "FontManagerFontPreviewTile");
            notify["item"].connect((pspec) => { on_item_set(); });
            set_size_request(128, 128);
        }

        public void reset () {
            // family.set_label("");
            // count.set_label("");
            preview.set_text(null);
            return;
        }

        public void on_item_set () {
            reset();
            if (item == null)
                return;
            Family f = (Family) item;
            set_tooltip_text(f.family);
            // int n_variations = (int) f.n_variations;
            // family.set_label(f.family);
            preview.set_text(f.preview_text == null ?
                             f.family.substring(0, 2).make_valid() :
                             f.preview_text.substring(0, 2).make_valid());
            Pango.FontDescription font_desc;
            font_desc = Pango.FontDescription.from_string(f.description);
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            attrs.insert(Pango.AttrSize.new(48 * Pango.SCALE));
            attrs.insert(new Pango.AttrFontDesc(font_desc));
            preview.set_attributes(attrs);
            // count.set_label(n_variations.to_string());
            return;
        }

    }

    public class BrowsePane : Gtk.Box {

        public signal void selection_changed (Object? item);

        public Json.Array? available_fonts { get; set; default = null; }

        public virtual BaseFontModel model { get; set; default = new FontModel(); }

        protected Gtk.GridView listview { get; protected set; }

        protected Gtk.SelectionModel selection;

        construct {
            listview = new Gtk.GridView(null, null) {
                hexpand = true,
                vexpand = true
            };
            listview.add_css_class("rich-list");
            var scrolled_window = new Gtk.ScrolledWindow();
            scrolled_window.set_child(listview);
            append(scrolled_window);
            selection = new Gtk.SingleSelection(model);
            listview.set_model(selection);
            listview.set_factory(get_factory());
            BindingFlags flags = BindingFlags.DEFAULT;
            bind_property("available-fonts", model, "entries", flags, null, null);
        }

        protected virtual void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            list_item.set_child(new FontPreviewTile());
            return;
        }

        protected virtual void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var row = (FontPreviewTile) list_item.get_child();
            Object? _item = list_item.get_item();
            // Setting item triggers update to row widget
            row.item = _item;
            return;
        }

        Gtk.SignalListItemFactory get_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            return factory;
        }

    }

}


