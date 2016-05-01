/* FontSourceList.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    const string w1 = _("Font Sources");
    const string w2 = _("Easily add or preview fonts without actually installing them.");
    const string w3 = _("To add a new source simply drag a folder onto this area or click the add button in the toolbar.");
    const string welcome_tmpl = "<span size=\"xx-large\" weight=\"bold\">%s</span>\n<span size=\"large\">\n\n%s\n</span>\n\n\n<span size=\"x-large\">%s</span>";


    /**
     * FontSourceRow:
     *
     * Widget representing a #FontConfig.Source and its current status.
     * Intended for use in a #Gtk.Listbox
     */
    public class FontSourceRow : Gtk.Box {

        public weak FontConfig.Source source { get; set; }
        public Gtk.Image image { get; private set; }
        public LabeledSwitch toggle { get; private set; }

        public FontSourceRow (FontConfig.Source source) {
            Object(name: "FontManagerFontSourceRow", source: source, orientation: Gtk.Orientation.HORIZONTAL);
            image = new Gtk.Image();
            image.expand = false;
            image.margin = 6;
            toggle = new LabeledSwitch();
            source.bind_property("active", toggle.toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            source.bind_property("available", toggle.toggle, "sensitive", BindingFlags.SYNC_CREATE);
            source.bind_property("icon-name", image, "icon-name", BindingFlags.SYNC_CREATE);
            source.bind_property("name", toggle.label, "label", BindingFlags.SYNC_CREATE);
            toggle.dim_label.set_text(source.get_dirname());
            pack_start(image, false, false, 6);
            pack_end(toggle, true, true, 6);
        }

        public override void show () {
            image.show();
            toggle.show();
            base.show();
            return;
        }

    }

    /**
     * FontSourceList:
     */
    public class FontSourceList : Gtk.ScrolledWindow {

        /**
         * FontSourceList::changed:
         *
         * Emitted when a row has been added or removed
         */
        public signal void changed ();
        public signal void row_selected (Gtk.ListBoxRow? row);

        /**
         * FontSourceList:sources:
         *
         * #FontConfig.Sources to display
         */
        public FontConfig.Sources sources {
            get {
                return _sources;
            }
            set {
                _sources = value;
                _sources.changed.connect(() => { changed(); });
                changed.connect(() => { update(); });
                update();
            }
        }

        Gtk.ListBoxRow first_row {
            get {
                return list.get_row_at_index(0);
            }
        }

        Gtk.ListBox list;
        Gtk.Label welcome;
        FontConfig.Sources _sources;

        construct {
            string welcome_message = welcome_tmpl.printf(w1, w2, w3);
            welcome = new WelcomeLabel(welcome_message);
            list = new Gtk.ListBox();
            list.set_placeholder(welcome);
            add(list);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            list.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            list.row_selected.connect((r) => { row_selected(r); });
        }

        public FontSourceList () {
            Object(name: "FontSourceList");
        }

        public void update () {
            while (first_row != null)
                ((Gtk.Widget) first_row).destroy();
            foreach (var s in _sources) {
                var w = new FontSourceRow(s);
                list.add(w);
                w.show();
            }
            queue_draw();
            return;
        }

        public override void show () {
            welcome.show();
            list.show();
            update();
            base.show();
            return;
        }

        public void on_add_source () {
            var new_sources = FileSelector.source_selection((Gtk.Window) this.get_toplevel());
            if (new_sources.length < 1)
                return;
            foreach (var uri in new_sources)
                add_source_from_uri(uri);
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
            _sources.add_from_path(path);
            _sources.save();
            debug("Added new font source : %s", path);
            changed();
            return;
        }

        public void on_remove_source () {
            var selected_row = list.get_selected_row();
            if (selected_row == null)
                return;
            var selected_source = ((FontSourceRow) selected_row.get_child()).source;
            if (!_sources.remove(selected_source))
                return;
            _sources.save();
            debug("Removed font source : %s", selected_source.path);
            changed();
            return;
        }

        public override void drag_data_received (Gdk.DragContext context,
                                                    int x,
                                                    int y,
                                                    Gtk.SelectionData selection_data,
                                                    uint info,
                                                    uint time)
        {
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

        void add_sources(string [] arr) {
            foreach (var uri in arr)
                add_source_from_uri(uri);
            return;
        }

    }

}
