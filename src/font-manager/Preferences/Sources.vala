/* Sources.vala
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

    public class SourcePreferences : SettingsPage {

        public signal void changed ();

        BaseControls controls;
        FontSourceList source_list;

        public SourcePreferences () {
            orientation = Gtk.Orientation.VERTICAL;
            source_list = new FontSourceList();
            source_list.expand = true;
            controls = new BaseControls();
            controls.add_button.set_tooltip_text(_("Add source"));
            controls.add_button.sensitive = true;
            controls.remove_button.set_tooltip_text(_("Remove selected source"));
            controls.remove_button.sensitive = false;
            controls.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            controls.add_button.sensitive = (sources != null);
            pack_start(controls, false, false, 1);
            add_separator(this, Gtk.Orientation.HORIZONTAL);
            pack_end(source_list, true, true, 1);
            connect_signals();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        }

        public override void show () {
            controls.show();
            controls.remove_button.hide();
            source_list.show();
            base.show();
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

        /**
         * FontSourceList:first_row:
         */
        Gtk.ListBoxRow first_row {
            get {
                return list.get_row_at_index(0);
            }
        }

        Gtk.ListBox list;
        PlaceHolder welcome;

        construct {
            string w1 = _("Font Sources");
            string w2 = _("Easily add or preview fonts without actually installing them.");
            string w3 = _("To add a new source simply drag a folder onto this area or click the add button in the toolbar.");
            string welcome_tmpl = "<span size=\"xx-large\" weight=\"bold\">%s</span>\n<span size=\"large\">\n\n%s\n</span>\n\n\n<span size=\"x-large\">%s</span>";
            string welcome_message = welcome_tmpl.printf(w1, w2, w3);
            welcome = new PlaceHolder(welcome_message, "folder-symbolic");
            list = new Gtk.ListBox();
            list.set_placeholder(welcome);
            add(list);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            list.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            list.row_selected.connect((r) => { row_selected(r); });
            changed.connect(() => { Idle.add(() => { update(); return false; }); });
            sources.changed.connect(() => { changed(); });
            update();
        }

        public FontSourceList () {
            Object(name: "FontSourceList");
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

        /**
         * {@inheritDoc}
         */
        public override void show () {
            welcome.show();
            list.show();
            update();
            base.show();
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
            string? [] arr = { };
            var dialog = new Gtk.FileChooserDialog(_("Select source folders"),
                                                    (Gtk.Window) this.get_toplevel(),
                                                    Gtk.FileChooserAction.SELECT_FOLDER,
                                                    _("_Cancel"),
                                                    Gtk.ResponseType.CANCEL,
                                                    _("_Open"),
                                                    Gtk.ResponseType.ACCEPT,
                                                    null);
            dialog.set_select_multiple(true);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                foreach (var uri in dialog.get_uris())
                    arr += uri;
            }
            dialog.destroy();
            if (arr.length > 0)
                add_sources(arr);
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
                return;
            sources.save();
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
        class FontSourceRow : Gtk.Box {

            public weak Source source { get; set; }
            public Gtk.Image image { get; private set; }
            public LabeledSwitch toggle { get; private set; }

            public FontSourceRow (Source source) {
                Object(name: "FontSourceRow", source: source, orientation: Gtk.Orientation.HORIZONTAL);
                image = new Gtk.Image();
                image.set("expand", false, margin: DEFAULT_MARGIN_SIZE / 4, "margin-start", DEFAULT_MARGIN_SIZE, null);
                toggle = new LabeledSwitch();
                source.bind_property("active", toggle.toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
                source.bind_property("available", toggle.toggle, "sensitive", BindingFlags.SYNC_CREATE);
                source.bind_property("icon-name", image, "icon-name", BindingFlags.SYNC_CREATE);
                source.bind_property("name", toggle.label, "label", BindingFlags.SYNC_CREATE);
                toggle.dim_label.set_text(source.get_status_message());
                pack_start(image, false, false, 6);
                pack_end(toggle, true, true, 6);
            }

            /**
             * {@inheritDoc}
             */
            public override void show () {
                image.show();
                toggle.show();
                base.show();
                return;
            }

        }

    }

}

