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

        [GtkChild] public unowned Gtk.Label title_label { get; }
        [GtkChild] public unowned Gtk.ListBox preview_list { get; }

        construct {
            widget_set_name(this, "FontManagerFontPreviewTile");
            notify["item"].connect((pspec) => { on_item_set(); });
        }

        public void on_item_set () {
            title_label.set_label("");
            preview_list.remove_all();
            if (item == null)
                return;
            string? f = null;
            Json.Array? variations = null;
            item.get("family", out f, "variations", out variations, null);
            title_label.set_label(f);
            variations.foreach_element((a, i, n) => {
                var font = new Font();
                font.source_object = n.get_object();
                var preview = new Gtk.Inscription(font.style) {
                    margin_top = 2,
                    margin_bottom = 2
                };
                preview.set_min_chars(font.style.length + 9);
                preview.set_xalign(0.5f);
                preview_list.append(preview);
                Pango.FontDescription font_desc;
                font_desc = Pango.FontDescription.from_string(font.description);
                Pango.AttrList attrs = new Pango.AttrList();
                attrs.insert(Pango.attr_fallback_new(false));
                attrs.insert(new Pango.AttrFontDesc(font_desc));
                preview.set_attributes(attrs);
            });
            return;
        }

    }

    public class BrowseListModel : BaseFontModel {

        construct {
            item_type = typeof(Family);
            entries = new Json.Array();
        }

    }

    public class BrowsePane : Gtk.Box {

        public Json.Array? available_fonts { get; set; default = null; }

        public Gtk.ListView listview { get; private set; }
        public BrowseListModel model { get; private set; }

        protected Gtk.SelectionModel selection;

        uint increment = 25;

        construct {
            hexpand = true;
            vexpand = true;
            model = new BrowseListModel();
            selection = new Gtk.NoSelection(model);
            listview = new Gtk.ListView(selection, get_factory()) {
                hexpand = true,
                vexpand = true
            };
            append(listview);
            listview.map.connect(on_map);
            notify["available-fonts"].connect(() => {
                model.entries = new Json.Array();
                if (listview.get_mapped())
                    on_map();
                else
                    load_initial_entries();
            });
            // BindingFlags flags = BindingFlags.SYNC_CREATE;
            // bind_property("available-fonts", model, "entries", flags, null, null);
        }

        void load_initial_entries() {
            uint n_loaded = model.entries.get_length();
            if (n_loaded > 0)
                return;
            for (uint i = 0; i < increment; i++) {
                var node = available_fonts.dup_element(i);
                model.entries.add_element(node);
            }
            model.update_items();
            return;
        }

        bool load_available_fonts () {
            uint n_available = available_fonts.get_length();
            uint n_loaded = model.entries.get_length();
            if (n_loaded >= n_available) {
                model.update_items();
                return GLib.Source.REMOVE;
            }
            uint remaining = n_available - n_loaded;
            uint _n_loaded = (n_loaded > 0) ? n_loaded - 1 : 0;
            uint n_load = (remaining >= increment) ? increment : remaining;
            uint limit = n_load + n_loaded;
            for (uint i = _n_loaded; i < limit; i++) {
                var node = available_fonts.dup_element(i);
                model.entries.add_element(node);
            }
            uint current = model.entries.get_length();
            if (current == increment)
                model.update_items();
            return GLib.Source.CONTINUE;
        }

        void on_map () {
            Timeout.add(500, load_available_fonts);
            return;
        }

        protected virtual void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var tile = new FontPreviewTile();
            list_item.set_child(tile);
            return;
        }

        protected virtual void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var real_item = list_item.get_item();
            var tile = (FontPreviewTile) list_item.get_child();
            tile.item = real_item;
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


