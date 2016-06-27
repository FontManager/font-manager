/* Controls.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

/**
 * LabeledSwitch:
 *
 * Row like widget containing two #Gtk.Label and a #Gtk.Switch.
 * Use #Gtk.Label.set_text() / #Gtk.Label.set_markup()
 * @label is intended to display main option name
 * @dim_label is intended to display additional information
 * @toggle is #Gtk.Switch connect to its active signal to monitor changes
 *
 * ------------------------------------------------------------
 * |                                                          |
 * | label                 dim_label                switch    |
 * |                                                          |
 * ------------------------------------------------------------
 */
public class LabeledSwitch : Gtk.Box {

    /**
     * LabeledSwitch:label:
     *
     * #Gtk.Label
     */
    public Gtk.Label label { get; private set; }

    /**
     * LabeledSwitch:dim_label:
     *
     * Centered #Gtk.Label with dim-label style class
     */
    public Gtk.Label dim_label { get; private set; }

    /**
     * LabeledSwitch:toggle:
     *
     * #Gtk.Switch
     */
    public Gtk.Switch toggle { get; private set; }

    construct {
        label = new Gtk.Label(null);
        label.hexpand = false;
        label.halign = Gtk.Align.START;
        dim_label = new Gtk.Label(null);
        dim_label.hexpand = true;
        dim_label.halign = Gtk.Align.CENTER;
        dim_label.get_style_context().add_class(Gtk.STYLE_CLASS_DIM_LABEL);
        toggle = new Gtk.Switch();
        toggle.expand = false;
        pack_start(label, false, false, 0);
        set_center_widget(dim_label);
        pack_end(toggle, false, false, 0);
    }

    public LabeledSwitch (string label = "") {
        Object(name: "LabeledSwitch", margin: DEFAULT_MARGIN_SIZE);
        this.label.set_text(label);
    }

    /**
     * {@inheritDoc}
     */
    public override void show () {
        label.show();
        dim_label.show();
        toggle.show();
        base.show();
        return;
    }
}

/**
 * LabeledSpinButton:
 *
 * @value       current value
 *
 * Row like widget containing a #Gtk.Label and a #Gtk.SpinButton.
 *
 * ------------------------------------------------------------
 * |                                                          |
 * | label                                       spinbutton   |
 * |                                                          |
 * ------------------------------------------------------------
 */
public class LabeledSpinButton : Gtk.Grid {

    /**
     * LabeledSpinButton:value:
     *
     * Current value.
     */
    public double @value { get; set; default = 0.0; }

    Gtk.Label label;
    Gtk.SpinButton spin;

    public LabeledSpinButton (string label = "", double min, double max, double step) {
        Object(name: "LabeledspinButton", margin: DEFAULT_MARGIN_SIZE);
        this.label = new Gtk.Label(label);
        this.label.hexpand = true;
        this.label.halign = Gtk.Align.START;
        spin = new Gtk.SpinButton.with_range(min, max, step);
        attach(this.label, 0, 0, 1, 1);
        attach(spin, 1, 0, 1, 1);
        bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
    }

    /**
     * {@inheritDoc}
     */
    public override void show () {
        label.show();
        spin.show();
        base.show();
        return;
    }

}

/**
 * OptionScale:
 *
 * @heading     string to display centered above scale
 * @options     string [] of options to create marks for
 *
 * Row like widget containing a #Gtk.Label displayed centered
 * above the scale.
 *
 * ---------------------------------------------------------------
 * |                          heading                            |
 * |                                                             |
 * |   options[0] ---------- options[1] ----------- options[2]   |
 * |                                                             |
 * ---------------------------------------------------------------
 */
public class OptionScale : Gtk.Grid {

    /**
     * OptionScale:value:
     *
     * Current value.
     */
    public double @value { get; set; default = 0.0; }

    /**
     * FontScale:adjustment:
     *
     * #Gtk.Adjustment in use
     */
    public Gtk.Adjustment adjustment {
        get {
            return scale.get_adjustment();
        }
    }

    /**
     * OptionScale:options:
     */
    public string [] options { get; private set; }

    Gtk.Label label;
    Gtk.Scale scale;

    public OptionScale (string? heading = null, string [] options) {
        Object(name: "OptionScale", margin: DEFAULT_MARGIN_SIZE);
        hexpand = true;
        this.options = options;
        scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, options.length, 1);
        scale.hexpand = true;
        scale.draw_value = false;
        scale.round_digits = 1;
        scale.adjustment.lower = 0;
        scale.adjustment.page_increment = 1;
        scale.adjustment.step_increment = 1;
        scale.adjustment.upper = options.length - 1;
        scale.show_fill_level = false;
        for (int i = 0; i < options.length; i++)
            scale.add_mark(i, Gtk.PositionType.BOTTOM, options[i]);
        scale.value_changed.connect(() => {
            scale.set_value(Math.round(scale.adjustment.get_value()));
        });
        label = new Gtk.Label(null);
        label.hexpand = true;
        if (heading != null)
            label.set_text(heading);
        attach(label, 0, 0, options.length, 1);
        attach(scale, 0, 1, options.length, 1);
        bind_property("value", scale.adjustment, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
    }

    /**
     * {@inheritDoc}
     */
    public override void show () {
        label.show();
        scale.show();
        base.show();
        return;
    }

}

/**
 * FontScale:
 *
 * Row like widget which displays a #Gtk.Scale and a #Gtk.SpinButton
 * for adjusting font display size.
 *
 * ------------------------------------------------------------------
 * |                                                                |
 * |  a |------------------------------------------| A     [  +/-]  |
 * |                                                                |
 * ------------------------------------------------------------------
 */
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
     * #Gtk.Adjustment in use
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

    Gtk.Box container;
    Gtk.Scale scale;
    Gtk.SpinButton spin;
    ReactiveLabel min;
    ReactiveLabel max;

    public FontScale () {
        Object(name: "FontScale");
        scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5);
        scale.draw_value = false;
        scale.set_range(MIN_FONT_SIZE, MAX_FONT_SIZE);
        scale.set_increments(0.5, 1.0);
        spin = new Gtk.SpinButton.with_range(MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5);
        spin.set_adjustment(adjustment);
        min = new ReactiveLabel(null);
        max = new ReactiveLabel(null);
        min.label.set_markup("<span font=\"Serif Italic Bold\" size=\"small\"> A </span>");
        max.label.set_markup("<span font=\"Serif Italic Bold\" size=\"large\"> A </span>");
        container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        container.pack_start(min, false, true, 2);
        container.pack_start(scale, true, true, 0);
        container.pack_start(max, false, true, 2);
        container.pack_end(spin, false, true, 8);
        container.border_width = 5;
        add(container);
        min.clicked.connect(() => { scale.set_value(MIN_FONT_SIZE); });
        max.clicked.connect(() => { scale.set_value(MAX_FONT_SIZE); });
        bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
    }

    /**
     * add_style_class:
     *
     * Convenience function which applies given style_class.
     */
    public void add_style_class (string gtk_style_class) {
        container.forall((w) => {
            if ((w is Gtk.SpinButton) || (w is Gtk.Scale))
                return;
            w.get_style_context().add_class(gtk_style_class);
        });
        get_style_context().add_class(gtk_style_class);
        return;
    }

    /**
     * {@inheritDoc}
     */
    public override void show () {
        container.show();
        min.show();
        max.show();
        spin.show();
        scale.show();
        base.show();
        return;
    }

}
