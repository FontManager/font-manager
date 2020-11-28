/* FontList.vala
 *
 * Copyright (C) 2020 Jerry Casiano
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

#if HAVE_WEBKIT

namespace FontManager.GoogleFonts {

    public class FontListControls : Gtk.EventBox {

        /**
         * Emitted when the expand_button is clicked
         */
        public signal void expand_all (bool expand);

        public bool expanded { get; private set; }
        public Gtk.Button expand_button { get; private set; }
        public Gtk.SearchEntry entry { get; private set; }

        Gtk.Box box;
        Gtk.Image arrow;

        string expand_icon = "pan-end-symbolic";
        string collapse_icon = "pan-down-symbolic";

        public FontListControls () {
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
            box.border_width = 2;
            set_button_relief_style(box);
            if (get_direction() == Gtk.TextDirection.RTL)
                expand_icon = "pan-start-symbolic";
            expand_button = new Gtk.Button();
            arrow = new Gtk.Image.from_icon_name(expand_icon, Gtk.IconSize.SMALL_TOOLBAR);
            expand_button.add(arrow);
            expand_button.set_tooltip_text(_("Expand all"));
            entry = new Gtk.SearchEntry();
            entry.set_size_request(0, 0);
            entry.margin_end = MIN_MARGIN;
            entry.placeholder_text = _("Search Families…");
            entry.set_tooltip_text(_("Case insensitive search of family names."));
            box.pack_end(entry, false, false, 0);
            box.pack_start(expand_button, false, false, 0);
            set_button_relief_style(box);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            set_size_request(0, 0);
            expand_button.clicked.connect((w) => {
                expanded = !expanded;
                expand_all(expanded);
                expand_button.set_tooltip_text(expanded ? _("Collapse all") : _("Expand all"));
                if (expanded)
                    arrow.set_from_icon_name(collapse_icon, Gtk.IconSize.SMALL_TOOLBAR);
                else
                    arrow.set_from_icon_name(expand_icon, Gtk.IconSize.SMALL_TOOLBAR);
            });
            entry.show();
            arrow.show();
            expand_button.show();
            add(box);
            box.show();
        }

    }

    public class FontListPane : Gtk.Overlay {

        public FontListControls controls { get; protected set; }
        public Filters? filter { get; set; default = null; }
        public PlaceHolder place_holder { get; set; }

        public Gtk.TreeView fontlist {
            get {
                return ((Gtk.TreeView) scrolled_window.get_child());
            }
            set {
                Gtk.Widget? current_child = scrolled_window.get_child();
                if (current_child != null)
                    scrolled_window.remove(current_child);
                scrolled_window.add(value);
                value.expand = true;
                value.headers_visible = false;
                value.show();
            }
        }

        public Gtk.TreeModel? model {
            get {
                return real_model;
            }
            set {
                real_set_model(value);
            }
        }

        uint? search_timeout;
        uint16 text_length = 0;
        Gtk.Box box;
        Gtk.TreeModel? real_model = null;
        Gtk.TreeModelFilter? search_filter = null;
        Gtk.ScrolledWindow scrolled_window;

        construct {
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            controls = new FontListControls();
            box.pack_start(controls, false, true, 0);
            scrolled_window = new Gtk.ScrolledWindow(null, null) { expand = true };
            scrolled_window.shadow_type = Gtk.ShadowType.NONE;
            box.pack_end(scrolled_window, true, true, 0);
            fontlist = new Gtk.TreeView();
            var text = new Gtk.CellRendererText();
            var count = new CellRendererStyleCount();
            fontlist.insert_column_with_attributes(-1, "", text, "text", 1, null);
            fontlist.insert_column_with_attributes(-1, "", count, "count", 2, null);
            fontlist.get_column(0).expand = true;
            text.ellipsize = Pango.EllipsizeMode.END;
            fontlist.get_column(1).expand = false;
            connect_signals();
            controls.show();
            scrolled_window.show();
            add(box);
            box.show();
            var view = new Gtk.EventBox();
            place_holder = new PlaceHolder(null, null, null, null);
            view.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            view.expand = true;
            view.add(place_holder);
            place_holder.show.connect(() => { view.show(); });
            place_holder.hide.connect(() => { view.hide(); });
            add_overlay(view);
        }

        public bool refilter () {
            /* NOTE :
             * Creating a new Gtk.TreeModelFilter is cheaper than calling
             * refilter on an existing one with a large child model.
             */
            var saved_model = real_model;
            real_set_model(null);
            real_set_model(saved_model);
            select_first_row();
            if (controls.expanded)
                fontlist.expand_all();
            search_timeout = null;
            return GLib.Source.REMOVE;
        }

        void real_set_model (Gtk.TreeModel? model) {
            real_model = model;
            if (model != null) {
                search_filter = new Gtk.TreeModelFilter(model, null);
                search_filter.set_visible_func((m, i) => { return visible_func(m, i); });
                fontlist.model = search_filter;
            } else {
                search_filter = null;
                fontlist.model = null;
            }
            return;
        }

        public void select_first_row () {
            if (model == null)
                return;
            Gtk.TreePath path = new Gtk.TreePath.first();
            Gtk.TreeSelection selection = fontlist.get_selection();
            selection.unselect_all();
            selection.select_path(path);
            if (selection.path_is_selected(path))
                fontlist.scroll_to_cell(path, null, true, 0.5f, 0.5f);
            return;
        }

        public void select_next_row (bool forward = true) {
            Gtk.TreeSelection selection = fontlist.get_selection();
            GLib.List <Gtk.TreePath> paths = selection.get_selected_rows(null);
            Gtk.TreePath path = paths.nth_data(0);
            if (path != null) {
                bool path_changed = false;
                if (forward)
                    path.next();
                else
                    path_changed = path.prev();
                if (forward || path_changed) {
                    selection.unselect_all();
                    selection.select_path(path);
                }
            }
            if (!selection.path_is_selected(path))
                select_first_row();
            else if (path != null)
                fontlist.scroll_to_cell(path, null, true, 0.0f, 0.0f);
            return;
        }

        /* Add slight delay to avoid filtering while search is still changing */
        public void queue_refilter () {
            if (search_timeout != null)
                GLib.Source.remove(search_timeout);
            search_timeout = Timeout.add(333, refilter);
            return;
        }

        void connect_signals () {
            notify["filter"].connect(() => {
                refilter();
                filter.changed.connect(() => { refilter(); });
            });
            controls.entry.search_changed.connect(() => {
                queue_refilter();
                text_length = controls.entry.get_text_length();
            });
            controls.expand_all.connect((e) => {
                if (e)
                    fontlist.expand_all();
                else
                    fontlist.collapse_all();
            });
            controls.entry.next_match.connect(() => {
                select_next_row();
            });
            controls.entry.previous_match.connect(() => {
                select_next_row(false);
            });
            controls.entry.activate.connect(() => {
                select_next_row();
            });
            return;
        }

        bool visible_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
            bool search_match = true;
            if (text_length > 0) {
                Value val;
                model.get_value(iter, FontModelColumn.OBJECT, out val);
                Object object = val.get_object();
                string needle = controls.entry.get_text().casefold();
                string family = get_family_from_object(object).casefold();
                search_match = family.contains(needle);
            }
            if (filter != null)
                return search_match && filter.visible_func(model, iter);
            return search_match;
        }

    }

    internal string get_family_from_object (Object object)
    requires (object is Family || object is Font) {
        return (object is Family) ? ((Family) object).family : ((Font) object).family;
    }

}

#endif /* HAVE_WEBKIT */
