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

    public class FontconfigFooter : Gtk.Box {

        public signal void reset_requested ();

        public FontconfigFooter () {
            orientation = Gtk.Orientation.HORIZONTAL;
            var help = inline_help_widget(

_("""Running applications may require a restart to reflect any changes.

Note that not all environments/applications will honor these settings.""")

            );
            help.halign = Gtk.Align.START;
            help.margin_start = (DEFAULT_MARGIN * 3) - 2;
            help.margin_end = DEFAULT_MARGIN * 2;
            help.margin_bottom = DEFAULT_MARGIN;
            help.margin_top = DEFAULT_MARGIN * 2;
            append(help);
            var reset = new Gtk.Button.from_icon_name("edit-undo-symbolic") {
                opacity = 0.65,
                hexpand = true,
                halign = Gtk.Align.END,
                valign = Gtk.Align.END,
                margin_start = DEFAULT_MARGIN * 2,
                margin_end = DEFAULT_MARGIN * 2,
                margin_top = DEFAULT_MARGIN * 2,
                margin_bottom = DEFAULT_MARGIN * 2
            };
            reset.add_css_class("rounded");
            reset.clicked.connect(() => { reset_requested(); });
            reset.set_tooltip_text(_("Reset all values to default"));
            append(reset);
        }

    }

    public class SubpixelGeometryIcon : Gtk.Box {

        public int preferred_size { get; set; default = 30; }

        public SubpixelGeometryIcon (SubpixelOrder rgba) {

            hexpand = vexpand = homogeneous = true;
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
                append(pixel);
                /* @color: defined in FontManager.css */
                pixel.add_css_class(colors[rgba,i]);
            }

            set_child_size_request();
            notify["preferred-size"].connect(() => { set_child_size_request(); });

        }

        void set_child_size_request () {
            bool vertical = (orientation == Gtk.Orientation.VERTICAL);
            Gtk.Widget? child = ((Gtk.Widget) this).get_first_child();
            while (child != null) {
                child.set_size_request(vertical ? preferred_size : preferred_size / 3,
                                       vertical ? preferred_size / 3 : preferred_size);
                child = child.get_next_sibling();
            }
            return;
        }

        public override void measure (Gtk.Orientation orientation,
                                      int for_size,
                                      out int minimum,
                                      out int natural,
                                      out int minimum_baseline,
                                      out int natural_baseline) {
            minimum = natural = preferred_size;
            minimum_baseline = natural_baseline = -1;
            return;
        }

    }

    public class SubpixelGeometry : Gtk.Box {

        public string active_id {
            set {
                rgba = int.parse(value);
            }
            get {
                return _rgba_;
            }
        }

        public int rgba {
            get {
                return _rgba;
            }
            set {
                if (value < 0 || value >= ((int) options.length))
                    return;
                _rgba = value;
                options[_rgba].active = true;
                _rgba_ = _rgba.to_string();
                notify_property("rgba");
                notify_property("active-id");
            }
        }

        public int preferred_size { get; set; default = 30; }
        public GenericArray <Gtk.CheckButton> options { get; private set; }

        int _rgba;
        string? _rgba_ = null;

        public SubpixelGeometry () {
            hexpand = true;
            vexpand = false;
            halign = valign = Gtk.Align.CENTER;
            spacing = DEFAULT_MARGIN * 3;
            options = new GenericArray <Gtk.CheckButton> ();
            for (int i = 0; i <= SubpixelOrder.NONE; i++) {
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
                BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
                bind_property("preferred-size", icon, "preferred-size", flags);
            }
        }

    }

}

