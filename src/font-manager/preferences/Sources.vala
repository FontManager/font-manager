/* Sources.vala
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

    public class SourcePreferences : SettingsPage {

        const string help_text = _("""Fonts in any folders listed here will be available within the application.

They will not be visible to other applications until the source is actually enabled.

Note that not all environments/applications will honor these settings.""");

        public signal void changed ();

        BaseControls controls;
        FontSourceList source_list;
        InlineHelp help;

        public SourcePreferences () {
            source_list = new FontSourceList();
            source_list.expand = true;
            controls = new BaseControls();
            controls.add_button.set_tooltip_text(_("Add source"));
            controls.add_button.sensitive = true;
            controls.remove_button.set_tooltip_text(_("Remove selected source"));
            controls.remove_button.sensitive = false;
            controls.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            controls.add_button.sensitive = (sources != null);
            help = new InlineHelp();
            help.margin = 1;
            help.message.set_text(help_text);
            controls.box.pack_end(help, false, false, 0);
            box.pack_start(controls, false, false, 1);
            add_separator(box, Gtk.Orientation.HORIZONTAL);
            box.pack_end(source_list, true, true, 1);
            connect_signals();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            controls.show();
            controls.remove_button.hide();
            source_list.show();
            help.show();
        }

        public void update () {
            source_list.update();
            return;
        }

        void connect_signals () {
            controls.add_selected.connect(() => {
                source_list.on_add_source();
            });
            controls.remove_selected.connect(() => {
                source_list.on_remove_source();
            });
            source_list.row_selected.connect((r) => {
                if (r != null)
                    controls.remove_button.show();
                else
                    controls.remove_button.hide();
                controls.remove_button.sensitive = (r != null);
            });
            source_list.changed.connect(() => { changed(); });
            source_list.place_holder.map.connect(() => {
                controls.add_button.set_relief(Gtk.ReliefStyle.NORMAL);
                controls.add_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            source_list.place_holder.unmap.connect(() => {
                controls.add_button.set_relief(Gtk.ReliefStyle.NONE);
                controls.add_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            return;
        }

    }

    /**
     * FontSourceList:
     */
    class FontSourceList : Gtk.ScrolledWindow {

        /**
         * FontSourceList::changed:
         *
         * Emitted when a row has been added or removed
         */
        public signal void changed ();

        /**
         * FontSourceList::row_selected:
         *
         * Emitted when a row has been selected
         */
        public signal void row_selected (Gtk.ListBoxRow? row);

        public PlaceHolder place_holder { get; private set; }

        /**
         * FontSourceList:first_row:
         */
        Gtk.ListBoxRow first_row {
            get {
                return list.get_row_at_index(0);
            }
        }

        Gtk.ListBox list;

        public FontSourceList () {
            Object(name: "FontManagerFontSourceList");
            string w1 = _("Font Sources");
            string w2 = _("Easily add or preview fonts without actually installing them.");
            string w3 = _("To add a new source simply drag a folder onto this area or click the add button in the toolbar.");
            string welcome_tmpl = "<span size=\"xx-large\" weight=\"bold\">%s</span>\n<span size=\"large\">\n\n%s\n</span>\n\n\n<span size=\"x-large\">%s</span>";
            string welcome_message = welcome_tmpl.printf(w1, w2, w3);
            place_holder = new PlaceHolder(welcome_message, "folder-symbolic");
            list = new Gtk.ListBox();
            list.set_placeholder(place_holder);
            add(list);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            list.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            list.row_selected.connect((r) => { row_selected(r); });
            changed.connect(() => { Idle.add(() => { update(); return false; }); });
            sources.changed.connect(() => { changed(); });
            update();
            place_holder.show();
            list.show();
        }

        /**
         * update:
         *
         * Updates list to match sources
         */
        public void update () {
            /* Simply destroy current list, it should never be long enough to be an issue */
            while (first_row != null)
                ((Gtk.Widget) first_row).destroy();
            if (sources == null)
                return;
            GLib.List <weak Source> _sources_ = sources.list_objects();
            foreach (var s in _sources_) {
                var w = new FontSourceRow(s);
                list.add(w);
                w.show();
            }
            return;
        }

        void add_source_from_uri (string uri) {
            var file = File.new_for_uri(uri);
            var filetype = file.query_file_type(FileQueryInfoFlags.NONE);
            if (filetype != FileType.DIRECTORY && filetype != FileType.MOUNTABLE) {
                warning("Adding individual font files is not supported");
                return;
            }
            var path = file.get_path();
            if (sources.add_from_path(path))
                sources.save();
            return;
        }

        void add_sources(string [] arr) {
            foreach (var uri in arr)
                add_source_from_uri(uri);
            return;
        }

        /**
         * on_add_source:
         *
         * Displays a file selection dialog where source folders can be added
         */
        public void on_add_source () {
            string? [] arr = FileSelector.get_selected_sources();
            if (arr.length > 0)
                Idle.add(() => { add_sources(arr); return false; });
            return;
        }

        /**
         * on_remove_source:
         *
         * Removes currently selected source
         */
        public void on_remove_source () {
            var selected_row = list.get_selected_row();
            if (selected_row == null)
                return;
            var selected_source = ((FontSourceRow) selected_row.get_child()).source;
            if (!sources.remove(selected_source))
                warning("Failed to remove selected source");
            else
                Idle.add(() => { sources.save(); return false; });
            return;
        }

        public override void drag_data_received (Gdk.DragContext context,
                                                    int x,
                                                    int y,
                                                    Gtk.SelectionData selection_data,
                                                    uint info,
                                                    uint time) {
            switch (info) {
                case DragTargetType.EXTERNAL:
                    add_sources(selection_data.get_uris());
                    break;
                default:
                    warning("Unsupported drag target.");
                    return;
            }
            return;
        }

        /**
         * FontSourceRow:
         *
         * Widget representing a #Source and its current status.
         * Intended for use in a #Gtk.Listbox
         */
        internal class FontSourceRow : LabeledSwitch {

            public weak Source source { get; set; }
            public Gtk.Image image { get; private set; }

            public FontSourceRow (Source source) {
                Object(name: "FontSourceRow", source: source, orientation: Gtk.Orientation.HORIZONTAL);
                image = new Gtk.Image();
                image.set("expand", false, "margin-end", DEFAULT_MARGIN_SIZE, null);
                source.bind_property("active", toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
                source.bind_property("available", toggle, "sensitive", BindingFlags.SYNC_CREATE);
                source.bind_property("icon-name", image, "icon-name", BindingFlags.SYNC_CREATE);
                source.bind_property("name", label, "label", BindingFlags.SYNC_CREATE);
                description.set_text(source.get_status_message());
                pack_start(image, false, false, 0);
                reorder_child(image, 0);
                image.show();
            }

        }

    }

}

