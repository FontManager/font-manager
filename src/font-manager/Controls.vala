/* Controls.vala
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

    public class BaseControls : Gtk.Box {

        public signal void add_selected ();
        public signal void remove_selected ();

        public Gtk.Button add_button { get; protected set; }
        public Gtk.Button remove_button { get; protected set; }

        construct {
            spacing = DEFAULT_MARGIN;
            opacity = 0.9;
            margin_start = margin_end = margin_top = margin_bottom = MIN_MARGIN * 2;
            add_button = new Gtk.Button.from_icon_name("list-add-symbolic") {
                has_frame = false
            };
            remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic") {
                has_frame = false
            };
            set_control_sensitivity(remove_button, false);
            append(add_button);
            append(remove_button);
            add_button.clicked.connect((w) => { add_selected(); });
            remove_button.clicked.connect(() => { remove_selected(); });
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preview-entry.ui")]
    public class PreviewEntry : Gtk.Entry {

        public override void constructed () {
            on_changed_event();
            base.constructed();
            return;
        }

        [GtkCallback]
        void on_icon_press_event (Gtk.Entry entry, Gtk.EntryIconPosition position) {
            if (position == Gtk.EntryIconPosition.SECONDARY)
                set_text("");
            return;
        }

        [GtkCallback]
        void on_changed_event () {
            bool empty = (text_length == 0);
            string icon_name = !empty ? "edit-clear-symbolic" : "document-edit-symbolic";
            set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, icon_name);
            set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, !empty);
            set_icon_sensitive(Gtk.EntryIconPosition.SECONDARY, !empty);
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preview-colors.ui")]
    public class PreviewColors : Gtk.Box {

        public signal void color_set ();

        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }

        [GtkChild] unowned Gtk.ColorDialogButton bg_color_button;
        [GtkChild] unowned Gtk.ColorDialogButton fg_color_button;

        void flatten_color_button (Gtk.ColorDialogButton button) {
            button.get_first_child().remove_css_class(STYLE_CLASS_COLOR);
            button.get_first_child().add_css_class(STYLE_CLASS_FLAT);
            return;
        }

        public override void constructed () {
            flatten_color_button(bg_color_button);
            flatten_color_button(fg_color_button);
            bg_color_button.set_dialog(new Gtk.ColorDialog() {
                title = _("Select background color")
            });
            fg_color_button.set_dialog(new Gtk.ColorDialog() {
                title = _("Select text color")
            });
            BindingFlags flags = BindingFlags.BIDIRECTIONAL;
            bind_property("background-color", bg_color_button, "rgba", flags);
            bind_property("foreground-color", fg_color_button, "rgba", flags);
            Gdk.RGBA rgba = Gdk.RGBA();
            if (rgba.parse("rgb(255,255,255)"))
                bg_color_button.set_rgba(rgba);
            if (rgba.parse("rgb(0,0,0)"))
                fg_color_button.set_rgba(rgba);
            bg_color_button.notify["rgba"].connect(() => { color_set(); });
            fg_color_button.notify["rgba"].connect(() => { color_set(); });
            base.constructed();
            return;
        }

    }

}
