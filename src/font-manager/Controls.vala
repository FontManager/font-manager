/* Controls.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

    /**
     * Base class for controls that allow adding or removing.
     * By default includes add/remove buttons packed at start of @box
     */
    public class BaseControls : Gtk.Box {

        /**
         * Emitted when @add_button has been clicked
         */
        public signal void add_selected ();

        /**
         * Emitted when @remove_button is clicked
         */
        public signal void remove_selected ();

        public Gtk.Button add_button { get; protected set; }

        public Gtk.Button remove_button { get; protected set; }

        construct {
            hexpand = true;
            spacing = DEFAULT_MARGIN;
            margin_start = margin_end = margin_top = margin_bottom = DEFAULT_MARGIN;
            add_button = new Gtk.Button.from_icon_name("list-add-symbolic") {
                has_frame = false
            };
            remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic") {
                has_frame = false
            };
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-option-scale.ui")]
    public class OptionScale : Gtk.Box {

        public double @value { get; set; default = 0.0; }

        public Gtk.Adjustment adjustment {
            get {
                return scale.get_adjustment();
            }
        }

        public string [] options { get; construct set;}

        [GtkChild] unowned Gtk.Label label;
        [GtkChild] unowned Gtk.Scale scale;

        public OptionScale (string? heading, string [] options) {
            this.options = options;
            label.set_text(heading);
            scale.set_adjustment(new Gtk.Adjustment(0.0, 0.0, ((double) options.length - 1), 1.0, 1.0, 0.0));
            for (int i = 0; i < options.length; i++)
                scale.add_mark(i, Gtk.PositionType.BOTTOM, options[i]);
            bind_property("value", scale.adjustment, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

        [GtkCallback]
        void on_scale_value_changed () {
            scale.set_value(GLib.Math.round(scale.adjustment.get_value()));
            return;
        }

    }

    public class SubpixelGeometryIcon : Gtk.Box {

        public SubpixelGeometryIcon (SubpixelOrder rgba) {

            hexpand = vexpand = true;
            halign = valign = Gtk.Align.CENTER;
            margin_start = DEFAULT_MARGIN;
            margin_end = DEFAULT_MARGIN;

            string [,] colors = {
                { "gray", "gray", "gray" },
                { "red", "green", "blue" },
                { "blue", "green", "red" },
                { "red", "green", "blue" },
                { "blue", "green", "red" },
                { "gray", "gray", "gray" }
            };

            bool vertical = (rgba == SubpixelOrder.VBGR || rgba == SubpixelOrder.VRGB);
            orientation = vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL;

            for (int i = 0; i < 3; i++) {
                var pixel = new Gtk.DrawingArea();
                if (vertical)
                    pixel.set_size_request(35, 12);
                else
                    pixel.set_size_request(12, 35);
                append(pixel);
                /* @color: defined in FontManager.css */
                pixel.add_css_class(colors[rgba,i]);
            }

        }

        public override void measure (Gtk.Orientation orientation,
                                      int for_size,
                                      out int minimum,
                                      out int natural,
                                      out int minimum_baseline,
                                      out int natural_baseline) {
            minimum = natural = 36;
            minimum_baseline = natural_baseline = -1;
            return;
        }

}

    public class SubpixelGeometry : Gtk.Box {

        public int rgba {
            get {
                return _rgba;
            }
            set {
                if (value < 0 || value >= ((int) options.length))
                    return;
                _rgba = value;
                options[_rgba].active = true;
            }
        }

        public GenericArray <Gtk.CheckButton> options { get; private set; }

        int _rgba;

        public SubpixelGeometry () {
            hexpand = true;
            vexpand = false;
            halign = valign = Gtk.Align.CENTER;
            spacing = DEFAULT_MARGIN * 3;
            options = new GenericArray <Gtk.CheckButton> ();
            for (int i = 0; i < SubpixelOrder.NONE; i++) {
                var button = new Gtk.CheckButton();
                button.margin_start = DEFAULT_MARGIN;
                button.margin_end = DEFAULT_MARGIN;
                options.insert(i, button);
                if (i != 0)
                    button.set_group(options[0]);
                var icon = new SubpixelGeometryIcon((SubpixelOrder) i);
                button.set_child(icon);
                button.set_tooltip_text(((SubpixelOrder) i).to_string());
                button.toggled.connect(() => {
                    if (button.active) {
                        uint index;
                        options.find(button, out index);
                        rgba = (int) index;
                    }
                });
                append(button);
            }
        }

    }

}
