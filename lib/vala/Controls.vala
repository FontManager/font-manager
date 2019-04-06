/* Controls.vala
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

    /**
     * LabeledSwitch:
     * @label:      text to display in label or %NULL
     *
     * Row like widget containing two #GtkLabel and a #GtkSwitch.
     * Use #GtkLabel.set_text() / #GtkLabel.set_markup()
     * @label is intended to display main option name
     * @description is intended to display additional information
     * @toggle is #GtkSwitch connect to its active signal to monitor changes
     *
     * ------------------------------------------------------------
     * |                                                          |
     * | label                 description                switch  |
     * |                                                          |
     * ------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-switch.ui")]
    public class LabeledSwitch : Gtk.Box {

        /**
         * LabeledControl:label:
         *
         * #GtkLabel
         */
        [GtkChild] public Gtk.Label label { get; }

        /**
         * LabeledControl:description:
         *
         * Centered #GtkLabel with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        /**
         * LabeledSwitch:toggle:
         *
         * #GtkSwitch
         */
        [GtkChild] public Gtk.Switch toggle { get; }

        public LabeledSwitch (string? label = null) {
            this.label.set_text(label != null ? label : "");
        }

    }

    /**
     * LabeledSpinButton:
     *
     * @label:      text to display in label
     * @min:        minimum value for #GtkSpinButton
     * @max:        maximum value for #GtkSpinButton
     * @step:       step increment for #GtkSpinButton.adjustment
     *
     * Row like widget containing a #GtkLabel and a #GtkSpinButton.
     *
     * ------------------------------------------------------------
     * |                                                          |
     * | label                                       spinbutton   |
     * |                                                          |
     * ------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-spin-button.ui")]
    public class LabeledSpinButton : Gtk.Box {

        /**
         * LabeledControl:label:
         *
         * #GtkLabel
         */
        [GtkChild] public Gtk.Label label { get; }

        /**
         * LabeledControl:description:
         *
         * Centered #GtkLabel with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        /**
         * LabeledSpinButton:value:
         *
         * Current value.
         */
        public double @value { get; set; default = 0.0; }

        [GtkChild] Gtk.SpinButton spin;

        public LabeledSpinButton (string? label, double min, double max, double step) {
            this.label.set_text(label != null ? label : "");
            spin.set_adjustment(new Gtk.Adjustment(0, min, max, step, 0, 0));
            bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

    /**
     * LabeledFontButton:
     * @label:      text to display in label or %NULL
     *
     * Row like widget containing two #GtkLabel and a #GtkSwitch.
     * Use #GtkLabel.set_text() / #GtkLabel.set_markup()
     * @label is intended to display main option name
     * @description is intended to display additional information
     * @button is #GtkFontButton
     *
     * ------------------------------------------------------------
     * |                                                          |
     * | label                 description                button  |
     * |                                                          |
     * ------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-font-button.ui")]
    public class LabeledFontButton : Gtk.Box {

        /**
         * LabeledControl:label:
         *
         * #GtkLabel
         */
        [GtkChild] public Gtk.Label label { get; }

        /**
         * LabeledControl:description:
         *
         * Centered #GtkLabel with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        /**
         * LabeledFontButton:button:
         *
         * #GtkFontButton
         */
        [GtkChild] public Gtk.FontButton button { get; private set; }

        public string font { get; set; default = DEFAULT_FONT; }

        public LabeledFontButton (string? label = null) {
            this.label.set_text(label != null ? label : "");
            bind_property("font", button, "font", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

    /**
     * OptionScale:
     *
     * @heading:    string to display centered above scale
     * @options:    string [] of options to create marks for
     *
     * Row like widget containing a #GtkLabel displayed centered
     * above the scale.
     *
     * ---------------------------------------------------------------
     * |                          heading                            |
     * |                                                             |
     * |   options[0] ---------- options[1] ----------- options[2]   |
     * |                                                             |
     * ---------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-option-scale.ui")]
    public class OptionScale : Gtk.Box {

        /**
         * OptionScale:value:
         *
         * Current value.
         */
        public double @value { get; set; default = 0.0; }

        /**
         * FontScale:adjustment:
         *
         * #GtkAdjustment in use
         */
        public Gtk.Adjustment adjustment {
            get {
                return scale.get_adjustment();
            }
        }

        /**
         * OptionScale:options:
         */
        public string [] options { get; construct set;}

        [GtkChild] Gtk.Label label;
        [GtkChild] Gtk.Scale scale;

        public OptionScale (string? heading, string [] options) {
            this.options = options;
            label.set_text(heading);
            scale.set_adjustment(new Gtk.Adjustment(0.0, 0.0, ((double) options.length - 1), 1.0, 1.0, 0.0));
            for (int i = 0; i < options.length; i++)
                scale.add_mark(i, Gtk.PositionType.BOTTOM, options[i]);
            scale.value_changed.connect(() => {
                scale.set_value(Math.round(scale.adjustment.get_value()));
            });
            bind_property("value", scale.adjustment, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

    /**
     * FontScale:
     *
     * Row like widget which displays a #GtkScale and a #GtkSpinButton
     * for adjusting font display size.
     *
     * ------------------------------------------------------------------
     * |                                                                |
     * |  a  |------------------------------------------|  A   [  +/-]  |
     * |                                                                |
     * ------------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-scale.ui")]
    public class FontScale : Gtk.EventBox {

        /**
         * FontScale:value:
         *
         * Current value.
         */
        public double @value { get; set; default = 0.0; }

        /**
         * FontScale:adjustment:
         *
         * #GtkAdjustment in use
         */
        public Gtk.Adjustment adjustment {
            get {
                return scale.get_adjustment();
            }
            set {
                scale.set_adjustment(value);
                spin.set_adjustment(value);
            }
        }

        [GtkChild] Gtk.Scale scale;
        [GtkChild] Gtk.SpinButton spin;
        [GtkChild] ReactiveLabel min;
        [GtkChild] ReactiveLabel max;

        public override void constructed () {
            adjustment = new Gtk.Adjustment(DEFAULT_PREVIEW_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5, 1.0, 0);
            min.label.set_markup("<span font=\"Serif Italic Bold\" size=\"small\"> A </span>");
            max.label.set_markup("<span font=\"Serif Italic Bold\" size=\"large\"> A </span>");
            min.clicked.connect(() => { scale.set_value(MIN_FONT_SIZE); });
            max.clicked.connect(() => { scale.set_value(MAX_FONT_SIZE); });
            bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            base.constructed();
            return;
        }

    }

    /**
     * PreviewControls:
     *
     * Toolbar providing controls to justify, edit and reset preview text.
     *
     * -------------------------------------------------------------------
     * |                                                                 |
     * | justify controls           description             edit  reset  |
     * |                                                                 |
     * -------------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preview-controls.ui")]
    public class PreviewControls : Gtk.EventBox {

        /**
         * PreviewControls::justification_set:
         *
         * Emitted when the user toggles justification
         */
        public signal void justification_set (Gtk.Justification justification);

        /**
         * PreviewControls::editing:
         *
         * Emitted when editing mode has changed.
         */
        public signal void editing (bool enabled);

        /**
         * PreviewControls::on_clear_clicked:
         *
         * Emitted when user has requested text be reset to default
         */
        public signal void on_clear_clicked ();

        /**
         * PreviewControls:clear_is_sensitive:
         *
         * Whether reset function is available.
         */
        public bool clear_is_sensitive {
            get {
                return clear.get_sensitive();
            }
            set {
                clear.set_sensitive(value);
            }
        }

        public string title {
            get {
                return description.get_text();
            }
            set {
                description.set_text(value);
            }
        }

        [GtkChild] Gtk.Label description;
        [GtkChild] Gtk.Button clear;
        [GtkChild] Gtk.ToggleButton edit;
        [GtkChild] Gtk.RadioButton justify_left;
        [GtkChild] Gtk.RadioButton justify_center;
        [GtkChild] Gtk.RadioButton justify_fill;
        [GtkChild] Gtk.RadioButton justify_right;

        public override void constructed () {
            justify_center.set_active(true);
            justify_left.toggled.connect(() => { justification_set(Gtk.Justification.LEFT); });
            justify_center.toggled.connect(() => { justification_set(Gtk.Justification.CENTER); });
            justify_fill.toggled.connect(() => { justification_set(Gtk.Justification.FILL); });
            justify_right.toggled.connect(() => { justification_set(Gtk.Justification.RIGHT); });
            clear.clicked.connect(() => { on_clear_clicked(); });
            edit.toggled.connect(() => { editing(edit.get_active()); });
            base.constructed();
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
        public void on_icon_press_event (Gtk.EntryIconPosition position, Gdk.EventButton event) {
            if (position == Gtk.EntryIconPosition.SECONDARY)
                set_text("");
            return;
        }

        [GtkCallback]
        public void on_changed_event () {
            string icon_name = (text_length > 0) ? "edit-clear-symbolic" : "document-edit-symbolic";
            set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, icon_name);
            set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, (text_length > 0));
            return;
        }

    }

    /**
     * BaseControls:
     *
     * Base class for controls that allow adding or removing.
     * By default includes add/remove buttons packed at start of @box
     *
     * ----------------------------------------------------------------------
     * |  +  -                                                              |
     * ----------------------------------------------------------------------
     */
    public class BaseControls : Gtk.EventBox {

        /**
         * BaseControls::add_selected:
         *
         * Emitted when @add_button has been clicked
         */
        public signal void add_selected ();

        /**
         * BaseControls::remove_selected:
         *
         * Emitted when @remove_button is clicked
         */
        public signal void remove_selected ();

        /**
         * BaseControls:box:
         *
         * #GtkBox
         */
        public Gtk.Box box { get; protected set; }

        /**
         * BaseControls:add_button:
         *
         * #GtkButton
         */
        public Gtk.Button add_button { get; protected set; }

        /**
         * BaseControls:remove_button:
         *
         * #GtkButton
         */
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
            set_default_button_relief(box);
            add(box);
            add_button.clicked.connect((w) => { add_selected(); });
            remove_button.clicked.connect(() => { remove_selected(); });
            add_button.show();
            remove_button.show();
            box.show();
        }

    }

    /**
     * SubpixelGeometry:
     *
     * https://en.wikipedia.org/wiki/Subpixel_rendering
     *
     * Widget allowing user to select pixel layout.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-subpixel-geometry.ui")]
    public class SubpixelGeometry : Gtk.Box {

        public int rgba {
            get {
                return _rgba;
            }
            set {
                if (value < 0 || value >= ((int) options.length()))
                    return;
                _rgba = value;
                options.nth_data(_rgba).active = true;
            }
        }

        public GLib.List <Gtk.RadioButton> options;

        int _rgba;

        [GtkChild] Gtk.ButtonBox button_box;

        public SubpixelGeometry () {
            options = new GLib.List <Gtk.RadioButton> ();
            for (int i = 0; i < SubpixelOrder.NONE; i++) {
                if (i == 0)
                    options.append(new Gtk.RadioButton(null));
                else
                    options.append(new Gtk.RadioButton.from_widget(options.nth_data(0)));
                Gtk.RadioButton button = options.nth_data(i);
                var val = (SubpixelOrder) i;
                var icon = new SubpixelGeometryIcon(val);
                button.add(icon);
                icon.show();
                button.set_tooltip_text(val.to_string());
                button.toggled.connect(() => {
                    if (button.active)
                        rgba = i;
                });
                button_box.pack_start(button);
                button.show();
            }
        }

    }

}

