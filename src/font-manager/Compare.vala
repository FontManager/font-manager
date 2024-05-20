/* Compare.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

        public Object item { get; set; default = null; }
        public double preview_size { get; set; default = LARGE_PREVIEW_SIZE; }
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

        public string? description {
            get {
                Json.Object? source_object = null;
                item.get(JSON_PROXY_SOURCE, out source_object, null);
                if (source_object != null)
                    return source_object.get_string_member("description");
                return null;
            }
        }

        string? _preview_text = null;
        string? initial_preview = null;
        string? local_pangram = null;

        public CompareEntry (Object item, string preview_text, string default_preview) {
            Object(item: item, preview_text: preview_text);
            initial_preview = default_preview;
            local_pangram = get_localized_pangram();
            font_desc = Pango.FontDescription.from_string(description);
            attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_fallback_new(false));
            attrs.insert(new Pango.AttrFontDesc(font_desc));
            font_desc.set_absolute_size(preview_size * Pango.SCALE);
            attrs.insert(Pango.attr_foreground_new(0, 0, 0));
            attrs.insert(Pango.attr_background_new(65535, 65535, 65535));
            attrs.insert(Pango.attr_foreground_alpha_new(65535));
            attrs.insert(Pango.attr_background_alpha_new(65535));
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

        public GenericArray <CompareEntry>? items { get; private set; }

        construct {
            items = new GenericArray <CompareEntry> ();
        }

        public Type get_item_type () {
            return typeof(CompareEntry);
        }

        public uint get_n_items () {
            return items.length;
        }

        public Object? get_item (uint position) {
            return items[position];
        }

        public void add_item (CompareEntry item) {
            items.add(item);
            uint position = get_n_items() - 1;
            items_changed(position, 0, 1);
            return;
        }

        public void remove_item (uint position) {
            items.remove_index(position);
            items_changed(position, 1, 0);
            return;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-compare-row.ui")]
    public class CompareRow : Gtk.Grid {

        [GtkChild] unowned Gtk.Label description;
        [GtkChild] unowned Gtk.Label preview;

        public static CompareRow from_item (Object item) {
            var row = new CompareRow();
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            item.bind_property("description", row.description, "label", flags);
            item.bind_property("preview-text", row.preview, "label", flags);
            item.bind_property("attrs", row.preview, "attributes", flags);
            return row;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-compare-view.ui")]
    public class ComparePane : Gtk.Box {

        public double preview_size { get; set; default = LARGE_PREVIEW_SIZE; }
        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public GenericArray <Object>? selected_items { get; set; default = null; }
        public GLib.Settings? settings { get; set; default = null; }
        public StringSet? available_families { get; set; default = null; }
        public CompareModel model { get; set; }
        public PinnedComparisons pinned { get; private set; }

        public string? preview_text {
            get {
                return _preview_text != null ? _preview_text : default_preview_text;
            }
            set {
                _preview_text = value;
            }
        }

        [GtkChild] public unowned FontScale fontscale { get; }
        [GtkChild] public unowned PreviewColors preview_colors { get; }
        [GtkChild] public unowned PreviewEntry entry { get; }

        [GtkChild] unowned Gtk.Button add_button;
        [GtkChild] unowned Gtk.Button remove_button;
        [GtkChild] unowned Gtk.MenuButton pinned_button;
        [GtkChild] unowned Gtk.ListBox list;

        string? _preview_text = null;
        string? default_preview_text = null;

        public override void constructed () {
            widget_set_name(this, "FontManagerCompare");
            notify["model"].connect(() => { list.bind_model(model, CompareRow.from_item); });
            model = new CompareModel();
            pinned = new PinnedComparisons();
            pinned.compare = this;
            pinned_button.set_popover(pinned);
            _preview_text = default_preview_text = get_localized_pangram();
            entry.set_placeholder_text(preview_text);
            add_button.add_css_class(STYLE_CLASS_SUGGESTED_ACTION);
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            preview_colors.bind_property("foreground-color", this, "foreground-color", flags);
            preview_colors.bind_property("background-color", this, "background-color", flags);
            bind_property("preview-size", fontscale, "value", flags);
            set_control_sensitivity(pinned_button, pinned.model.get_n_items() > 0);
            model.items_changed.connect(on_items_changed);
            pinned.closed.connect(() => {
                bool have_items = (pinned.model.get_n_items() > 0 || model.get_n_items() > 0);
                set_control_sensitivity(pinned_button, have_items);
            });
            notify["foreground-color"].connect(() => { save_state(); });
            notify["background-color"].connect(() => { save_state(); });
            base.constructed();
            return;
        }

        public void on_items_changed (uint position, uint added, uint removed) {
            if (model.get_n_items() > 0)
                add_button.remove_css_class(STYLE_CLASS_SUGGESTED_ACTION);
            else
                add_button.add_css_class(STYLE_CLASS_SUGGESTED_ACTION);
            bool have_items = (pinned.model.get_n_items() > 0 || model.get_n_items() > 0);
            set_control_sensitivity(pinned_button, have_items);
            return;
        }

        public void restore_state (GLib.Settings? settings) {
            this.settings = settings;
            if (settings == null)
                return;
            preview_size = settings.get_double("compare-font-size");
            entry.text = settings.get_string("compare-preview-text");
            Idle.add(() => {
                var foreground = Gdk.RGBA();
                var background = Gdk.RGBA();
                bool foreground_set = foreground.parse(settings.get_string("compare-foreground-color"));
                bool background_set = background.parse(settings.get_string("compare-background-color"));
                if (foreground_set) {
                    if (foreground.alpha == 0.0f)
                        foreground.alpha = 1.0f;
                    preview_colors.foreground_color = foreground;
                }
                if (background_set) {
                    if (background.alpha == 0.0f)
                        background.alpha = 1.0f;
                    preview_colors.background_color = background;
                }
                return GLib.Source.REMOVE;
            });
            settings.bind("compare-preview-text", entry, "text", SettingsBindFlags.DEFAULT);
            settings.bind("compare-font-size", this, "preview-size", SettingsBindFlags.DEFAULT);
            return;
        }

        public void save_state () {
            if (settings == null)
                return;
            settings.set_string("compare-foreground-color", foreground_color.to_string());
            settings.set_string("compare-background-color", background_color.to_string());
            return;
        }

        void add_entry (Object item) {
            string? p = null;
            item.get("preview-text", out p, null);
            var preview = entry.text_length > 0 ? entry.text : p != null ? p : preview_text;
            var default_preview = p != null ? p : default_preview_text;
            var entry = new CompareEntry(item, preview, default_preview);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("preview-size", entry, "preview-size", flags);
            bind_property("preview-text", entry, "preview-text", flags);
            bind_property("foreground-color", entry, "foreground-color", flags);
            bind_property("background-color", entry, "background-color", flags);
            model.add_item(entry);
            return;
        }

        public void add_items (GenericArray <Object> items) {
            foreach (Object item in items) {
                string? family = null;
                item.get("family", out family, null);
                if (available_families == null || family in available_families) {
                    if (item is Family) {
                        Json.Array variations = ((Family) item).variations;
                        variations.foreach_element((a, i, n) => {
                            var _item = new Font();
                            _item.source_object = n.get_object();
                            add_entry(_item);
                        });
                    } else {
                        add_entry(item);
                    }
                }
            }
            return;
        }

        public GenericArray <Font> list_items () {
            var results = new GenericArray <Font> ();
            model.items.foreach((it) => { results.add((Font) it.item); });
            return results;
        }

        [GtkCallback]
        void on_entry_changed () {
            preview_text = (entry.text_length > 0) ? entry.text : null;
            return;
        }

        [GtkCallback]
        void on_list_row_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            set_control_sensitivity(remove_button, row != null);
            return;
        }

        [GtkCallback]
        void on_add_button_clicked () {
            add_items(selected_items);
            return;
        }

        [GtkCallback]
        void on_remove_button_clicked () {
            if (list.get_selected_row() == null)
                return;
            uint position = list.get_selected_row().get_index();
            model.remove_item(position);
            while (position > 0 && position >= model.get_n_items()) { position--; }
            list.select_row(list.get_row_at_index((int) position));
            return;
        }

    }

    public class PinnedComparison : Object {
        public string? label { get; set; default = ""; }
        public string? created { get; set; default = new GLib.DateTime.now_local().format("%c"); }
        public GenericArray <Object>? items { get; set; default = null; }
    }

    public class PinnedComparisonModel : Object, ListModel {

        public List <PinnedComparison>? items = null;

        public Type get_item_type () {
            return typeof(PinnedComparison);
        }

        public uint get_n_items () {
            return items != null ? items.length() : 0;
        }

        public Object? get_item (uint position) {
            return items.nth_data(position);
        }

        public void add_item (PinnedComparison item) {
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

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-pinned-comparisons-row.ui")]
    public class PinnedComparisonRow : Gtk.Grid {

        public signal void activated ();

        [GtkChild] unowned Gtk.Entry label;
        [GtkChild] unowned Gtk.Label created;

        const string placeholder_text = _("Saved Comparison");

        construct {
            label.set_placeholder_text(placeholder_text);
            ((Gtk.Entry) label).activate.connect(() => { activated(); });
        }

        public static PinnedComparisonRow from_item (Object item) {
            var row = new PinnedComparisonRow();
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            item.bind_property("label", row.label, "text", flags);
            item.bind_property("created", row.created, "label", flags);
            return row;
        }

        public override bool grab_focus () {
            base.grab_focus();
            label.grab_focus();
            return label.has_focus;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-pinned-comparisons.ui")]
    public class PinnedComparisons : Gtk.Popover {

        [GtkChild] unowned Gtk.ListBox list;
        [GtkChild] unowned Gtk.Button save_button;
        [GtkChild] unowned Gtk.Button remove_button;
        [GtkChild] unowned Gtk.Button restore_button;

        public ComparePane? compare { get; set; default = null; }
        public PinnedComparisonModel? model { get; set; default = null; }

        public override void constructed () {
            /* Translators : Please preserve the newline character somewhere in the middle of the string */
            var place_holder_text = _("Save the current comparison\nby clicking the + button");
            var place_holder = new PlaceHolder(null, null, place_holder_text, "view-pin-symbolic");
            list.set_placeholder(place_holder);
            place_holder.show();
            notify["compare"].connect(() => {
                if (compare != null)
                    compare.model.items_changed.connect((p, r, a) => {
                        set_control_sensitivity(save_button,
                                                compare.model.get_n_items() > 0);
                    });
            });
            notify["model"].connect((obj, pspec) => {
                list.bind_model(model, PinnedComparisonRow.from_item);
                model.items_changed.connect(on_items_changed);
            });
            model = new PinnedComparisonModel();
            load();
            base.constructed();
            return;
        }

        static string get_cache_file () {
            string dirpath = get_package_config_directory();
            string filepath = Path.build_filename(dirpath, "PinnedComparisons.json");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        void on_items_changed (uint position, uint removed, uint added) {
            if (added > 0) {
                Gtk.ListBoxRow row = list.get_row_at_index((int) position);
                var widget = (PinnedComparisonRow) row.get_child();
                list.select_row(row);
                widget.grab_focus();
                widget.activated.connect(() => { popdown(); });
            }
            return;
        }

        public void load () {
            Json.Node? root_node = load_json_file(get_cache_file());
            if (root_node == null)
                return;
            root_node.get_array().foreach_element((array, index, node) => {
                var obj = node.get_object();
                var item = new PinnedComparison();
                item.label = obj.get_string_member("label");
                item.created = obj.get_string_member("created");
                item.items = new GenericArray <Object> ();
                obj.get_array_member("items").foreach_element((a, i, n) => {
                    var o = n.get_object();
                    var entry = new Font();
                    entry.source_object = o;
                    item.items.add(entry);
                });
                model.add_item(item);
            });
            return;
        }

        [GtkCallback]
        void on_list_row_activated (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            on_restore_button_clicked();
            return;
        }

        [GtkCallback]
        void on_list_row_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            set_control_sensitivity(remove_button, row != null);
            set_control_sensitivity(restore_button, row != null);
            return;
        }

        [GtkCallback]
        void on_closed () {
            var arr = new Json.Array();
            uint total = model.get_n_items();
            for (uint i = 0; i < total; i++) {
                var item = (PinnedComparison) model.get_item(i);
                var obj = new Json.Object();
                obj.set_string_member("label", item.label);
                obj.set_string_member("created", item.created);
                var _arr = new Json.Array();
                foreach (var it in item.items)
                    _arr.add_object_element(((Font) it).source_object);
                obj.set_array_member("items", _arr);
                arr.add_object_element(obj);
            }
            var node = new Json.Node(Json.NodeType.ARRAY);
            node.set_array(arr);
            write_json_file(node, get_cache_file(), true);
            return;
        }

        [GtkCallback]
        void on_save_clicked () {
            var item = new PinnedComparison();
            model.add_item(item);
            item.items = compare.list_items();
            return;
        }

        [GtkCallback]
        void on_remove_clicked () {
            if (list.get_selected_row() == null)
                return;
            uint position = list.get_selected_row().get_index();
            model.remove_item(position);
            while (position > 0 && position >= model.get_n_items()) { position--; }
            list.select_row(list.get_row_at_index((int) position));
            return;
        }

        [GtkCallback]
        void on_restore_button_clicked () {
            if (list.get_selected_row() == null)
                return;
            uint position = list.get_selected_row().get_index();
            var item = model.get_item(position);
            return_if_fail(compare != null);
            while (compare.model.get_n_items() > 0)
                compare.model.remove_item(0);
            var items = new GenericArray <Object> ();
            foreach (var it in ((PinnedComparison) item).items)
                items.add(it);
            compare.add_items(items);
            popdown();
            return;
        }

    }

}

