/* BaseControls.vala
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

    /**
     * Base class for controls that allow adding or removing.
     * By default includes add/remove buttons packed at start of @box
     */
    public class BaseControls : Gtk.EventBox {

        /**
         * Emitted when @add_button has been clicked
         */
        public signal void add_selected ();

        /**
         * Emitted when @remove_button is clicked
         */
        public signal void remove_selected ();

        public Gtk.Box box { get; protected set; }

        public Gtk.Button add_button { get; protected set; }

        public Gtk.Button remove_button { get; protected set; }

        construct {
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
            box.border_width = 2;
            set_size_request(0, 0);
            add_button = new Gtk.Button();
            add_button.set_image(new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU));
            remove_button = new Gtk.Button();
            remove_button.set_image(new Gtk.Image.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU));
            box.pack_start(add_button, false, false, 1);
            box.pack_start(remove_button, false, false, 1);
            set_button_relief_style(box);
            add(box);
            add_button.clicked.connect((w) => { add_selected(); });
            remove_button.clicked.connect(() => { remove_selected(); });
            add_button.show();
            remove_button.show();
            box.show();
        }

    }

    /**
     * Row like widget containing two #GtkLabel and a #GtkSwitch.
     * Use #GtkLabel.set_text() / #GtkLabel.set_markup()
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-switch.ui")]
    public class LabeledSwitch : Gtk.Box {

        [GtkChild] public Gtk.Label label { get; }

        /**
         * Centered Label with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        [GtkChild] public Gtk.Switch toggle { get; }

        public LabeledSwitch (string? label = null) {
            this.label.set_text(label != null ? label : "");
        }

    }

    /**
     * Row like widget containing a #GtkLabel and a #GtkSpinButton.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-spin-button.ui")]
    public class LabeledSpinButton : Gtk.Box {

        [GtkChild] public Gtk.Label label { get; }

        /**
         * Centered Label with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        public double @value { get; set; default = 0.0; }

        [GtkChild] Gtk.SpinButton spin;

        public LabeledSpinButton (string? label, double min, double max, double step) {
            this.label.set_text(label != null ? label : "");
            spin.set_adjustment(new Gtk.Adjustment(0, min, max, step, 0, 0));
            bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

    /**
     * Row like widget containing two #GtkLabel and a #GtkSwitch.
     * Use #GtkLabel.set_text() / #GtkLabel.set_markup()
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-font-button.ui")]
    public class LabeledFontButton : Gtk.Box {

        [GtkChild] public Gtk.Label label { get; }

        /**
         * Centered Label with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        [GtkChild] public Gtk.FontButton button { get; private set; }

        public string font { get; set; default = DEFAULT_FONT; }

        public LabeledFontButton (string? label = null) {
            this.label.set_text(label != null ? label : "");
            bind_property("font", button, "font", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

    /**
     * Row like widget containing a Label displayed centered above the scale.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-option-scale.ui")]
    public class OptionScale : Gtk.Box {

        public double @value { get; set; default = 0.0; }

        public Gtk.Adjustment adjustment {
            get {
                return scale.get_adjustment();
            }
        }

        public string [] options { get; construct set;}

        [GtkChild] Gtk.Label label;
        [GtkChild] Gtk.Scale scale;

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
            scale.set_value(Math.round(scale.adjustment.get_value()));
            return;
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
        void on_icon_press_event (Gtk.Entry entry, Gtk.EntryIconPosition position, Gdk.Event event) {
            if (position == Gtk.EntryIconPosition.SECONDARY)
                set_text("");
            return;
        }

        [GtkCallback]
        void on_changed_event () {
            string icon_name = (text_length > 0) ? "edit-clear-symbolic" : "document-edit-symbolic";
            set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, icon_name);
            set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, (text_length > 0));
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-inline-help.ui")]
    public class InlineHelp : Gtk.MenuButton {

        public Gtk.Label message {
            get {
                return ((Gtk.Label) popover.get_child());
            }
        }

        construct {
            var style_context = get_style_context();
            style_context.remove_class("toggle");
            style_context.remove_class(Gtk.STYLE_CLASS_POPUP);
            style_context.add_class("image-button");
            popover.get_style_context().remove_class(Gtk.STYLE_CLASS_BACKGROUND);
        }

    }

    /**
     * Widget allowing user to select pixel layout.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-subpixel-geometry.ui")]
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

        public GenericArray <Gtk.RadioButton> options { get; private set; }

        int _rgba;

        [GtkChild] Gtk.ButtonBox button_box;

        public SubpixelGeometry () {
            options = new GenericArray <Gtk.RadioButton> ();
            for (int i = 0; i < SubpixelOrder.NONE; i++) {
                if (i == 0)
                    options.insert(i, new Gtk.RadioButton(null));
                else
                    options.insert(i, new Gtk.RadioButton.from_widget(options[0]));
                Gtk.RadioButton button = options[i];
                var icon = new SubpixelGeometryIcon((SubpixelOrder) i);
                button.add(icon);
                button.set_tooltip_text(((SubpixelOrder) i).to_string());
                button.toggled.connect(() => {
                    if (button.active) {
                        uint index;
                        options.find(button, out index);
                        rgba = (int) index;
                    }
                });
                button_box.pack_start(button);
                icon.show();
                button.show();
            }
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-subpixel-geometry-icon.ui")]
    public class SubpixelGeometryIcon : Gtk.Box {

        public int size { get; set; default = 36; }

        [GtkChild] Gtk.Label l1;
        [GtkChild] Gtk.Label l2;
        [GtkChild] Gtk.Label l3;

        public SubpixelGeometryIcon (SubpixelOrder rgba) {

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

            Gtk.Label [] labels = { l1, l2, l3 };
            for (int i = 0; i < labels.length; i++) {
                /* @color: defined in FontManager.css */
                labels[i].get_style_context().add_class(colors[rgba,i]);
            }

        }

        /* Used to force square widget */

        public override void get_preferred_width (out int minimum_size, out int natural_size) {
            minimum_size = natural_size = size;
            return;
        }

        public override void get_preferred_height (out int minimum_size, out int natural_size) {
            minimum_size = natural_size = size;
            return;
        }

        public override void get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {
            minimum_height = natural_height = width;
            return;
        }

        public override void get_preferred_width_for_height (int height, out int minimum_width, out int natural_width) {
            minimum_width = natural_width = height;
            return;
        }

    }

}

