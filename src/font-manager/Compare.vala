/* Compare.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    internal Pango.Color gdk_rgba_to_pango_color (Gdk.RGBA rgba) {
        var color = Pango.Color();
        color.red = (uint16) (rgba.red * 65535);
        color.green = (uint16) (rgba.green * 65535);
        color.blue = (uint16) (rgba.blue * 65535);
        return color;
    }

    public class CompareEntry : Object {

        public string? description { get; set; default = null; }
        public double preview_size { get; set; default = MIN_FONT_SIZE; }
        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public Pango.FontDescription? font_desc { get; set; default = null; }
        public Pango.AttrList? attrs { get; set; default = null; }

        public string? preview_text {
            get {
                return _preview_text;
            }
            set {
                _preview_text = (value != null && value != local_pangram) ? value : initial_preview;
            }
        }

        string? _preview_text = null;
        string? initial_preview = null;
        string? local_pangram = null;

        public CompareEntry (string description, string preview_text, string default_preview) {
            Object(description: description, preview_text: preview_text);
            initial_preview = default_preview;
            local_pangram = get_localized_pangram();
            font_desc = Pango.FontDescription.from_string(description);
            attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            attrs.insert(new Pango.AttrFontDesc(font_desc));
            font_desc.set_absolute_size(preview_size * Pango.SCALE);
            attrs.insert(Pango.attr_foreground_new(0, 0, 0));
            attrs.insert(Pango.attr_background_new(65535, 65535, 65535));
            attrs.insert(Pango.attr_foreground_alpha_new(0));
            attrs.insert(Pango.attr_background_alpha_new(0));
            notify["foreground-color"].connect(() => {
                var fg = gdk_rgba_to_pango_color(foreground_color);
                attrs.change(Pango.attr_foreground_new(fg.red, fg.green, fg.blue));
                var alpha = (uint16) (foreground_color.alpha * 65535);
                attrs.change(Pango.attr_foreground_alpha_new(alpha));
                notify_property("attrs");
            });
            notify["background-color"].connect(() => {
                var bg = gdk_rgba_to_pango_color(background_color);
                attrs.change(Pango.attr_background_new(bg.red, bg.green, bg.blue));
                var alpha = (uint16) (background_color.alpha * 65535);
                attrs.change(Pango.attr_background_alpha_new(alpha));
                notify_property("attrs");
            });
            notify["preview-size"].connect(() => {
                font_desc.set_absolute_size(preview_size * Pango.SCALE);
                attrs.change(new Pango.AttrFontDesc(font_desc));
                notify_property("attrs");
            });
        }

    }

    public class CompareModel : Object, ListModel {

        public List <CompareEntry>? items = null;

        public Type get_item_type () {
            return typeof(CompareEntry);
        }

        public uint get_n_items () {
            return items != null ? items.length() : 0;
        }

        public Object? get_item (uint position) {
            return items.nth_data(position);
        }

        public void add_item (CompareEntry item) {
            items.append(item);
            uint position = items.length() - 1;
            items_changed(position, 0, 1);
            return;
        }

        public void remove_item (uint position) {
            items.remove(items.nth_data(position));
            items_changed(position, 1, 0);
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-compare-row.ui")]
    public class CompareRow : Gtk.Grid {

        [GtkChild] Gtk.Label description;
        [GtkChild] Gtk.Label preview;

        public static CompareRow from_item (Object item) {
            var row = new CompareRow();
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            item.bind_property("description", row.description, "label", flags);
            item.bind_property("preview-text", row.preview, "label", flags);
            item.bind_property("attrs", row.preview, "attributes", flags);
            return row;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-compare-view.ui")]
    public class Compare : Gtk.Box {

        public signal void color_set ();

        public double preview_size { get; set; }
        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public Gtk.Adjustment adjustment { get; set; }
        public GLib.HashTable <string, string>? samples { get; set; default = null; }
        public Font? selected_font { get; set; default = null; }
        public CompareModel model { get; set; }

        public string? preview_text {
            get {
                return _preview_text != null ? _preview_text : default_preview_text;
            }
            set {
                _preview_text = value;
            }
        }

        [GtkChild] public PreviewEntry entry { get; }
        [GtkChild] public FontScale fontscale { get; }
        [GtkChild] public Gtk.ColorButton bg_color_button { get; }
        [GtkChild] public Gtk.ColorButton fg_color_button { get; }

        [GtkChild] Gtk.Box controls;
        [GtkChild] Gtk.Button add_button;
        [GtkChild] Gtk.Button remove_button;
        [GtkChild] Gtk.ListBox list;

        string? _preview_text = null;
        string? default_preview_text = null;

        public override void constructed () {
            name = "FontManagerCompare";
            notify["model"].connect(() => { list.bind_model(model, CompareRow.from_item); });
            model = new CompareModel();
            _preview_text = default_preview_text = get_localized_pangram();
            entry.set_placeholder_text(preview_text);
            set_button_relief_style(controls);
            foreground_color = fg_color_button.get_rgba();
            background_color = bg_color_button.get_rgba();
            bind_property("foreground_color", fg_color_button, "rgba", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("background_color", bg_color_button, "rgba", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("preview-size", fontscale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            fontscale.bind_property("adjustment", this, "adjustment", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            list.row_selected.connect((row) => {
                remove_button.set_visible(row != null);
            });
            add_button.clicked.connect(() => {
                add_from_string(selected_font.description);
            });
            remove_button.clicked.connect(() => {
                on_remove();
            });
            notify["preview-text"].connect(() => {
                entry.set_placeholder_text(preview_text);
            });
            entry.changed.connect(() => {
                preview_text = (entry.text_length > 0) ? entry.text : null;
            });
            bg_color_button.color_set.connect(() => { color_set(); });
            fg_color_button.color_set.connect(() => { color_set(); });
            base.constructed();
            return;
        }

        public void add_from_string (string description, GLib.List <string>? checklist = null) {
            Pango.FontDescription _desc = Pango.FontDescription.from_string(description);
            if (checklist == null || checklist.find_custom(_desc.get_family(), strcmp) != null) {
                var preview = entry.text_length > 0 ? entry.text :
                              (samples != null && samples.contains(description)) ?
                              samples.lookup(description) : preview_text;
                var default_preview = (samples != null && samples.contains(description)) ?
                                       samples.lookup(description) : default_preview_text;
                var item = new CompareEntry(description, preview, default_preview);
                BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
                bind_property("preview-size", item, "preview-size", flags);
                bind_property("preview-text", item, "preview-text", flags);
                bind_property("foreground-color", item, "foreground-color", flags);
                bind_property("background-color", item, "background-color", flags);
                model.add_item(item);
            }
            return;
        }

        public string [] list_items () {
            string [] results = {};
            foreach (var item in model.items)
                results += item.description;
            return results;
        }

        void on_remove () {
            if (list.get_selected_row() == null)
                return;
            uint position = list.get_selected_row().get_index();
            model.remove_item(position);
            while (position > 0 && position >= model.get_n_items()) { position--; }
            list.select_row(list.get_row_at_index((int) position));
            return;
        }

    }

}
