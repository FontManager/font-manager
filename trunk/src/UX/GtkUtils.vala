/* GtkUtils.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    public enum DragTargetType {
        FAMILY,
        COLLECTION,
        EXTERNAL
    }

    public const Gdk.DragAction AppDragActions = Gdk.DragAction.COPY;

    public const Gtk.TargetEntry [] AppDragTargets = {
        { "font-family", Gtk.TargetFlags.SAME_APP, DragTargetType.FAMILY },
        { "text/uri-list", 0, DragTargetType.EXTERNAL }
    };

    public void show_help_dialog () {
        try {
            Gtk.show_uri(null, "help:%s".printf(NAME), Gdk.CURRENT_TIME);
        } catch (Error e) {
            error("Error launching uri handler : %s", e.message);
        }
        return;
    }

    public void set_gnome_app_menu (Gtk.Application app, Gtk.Builder builder) {
        try {
            builder.add_from_resource("/org/gnome/FontManager/ApplicationMenu.ui");
            app.app_menu = builder.get_object("ApplicationMenu") as GLib.MenuModel;
        } catch (Error e) {
            warning("Failed to set application menu : %s", e.message);
        }
        return;
    }

    public void set_application_style () {
        string css_uri = "resource:///org/gnome/FontManager/FontManager.css";
        File css_file = File.new_for_uri(css_uri);
        Gtk.CssProvider provider = new Gtk.CssProvider();
        try {
            provider.load_from_file(css_file);
        } catch (Error e) {
            warning("Failed to load Css Provider! Application will not appear as expected.");
            warning(e.message);
        }
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        return;
    }

}

public bool Gnome3 () {
    Gtk.Settings settings = Gtk.Settings.get_default();
    bool has_app_menu = settings.gtk_shell_shows_app_menu;
    bool has_menubar = settings.gtk_shell_shows_menubar;
    return has_app_menu && !has_menubar;
}

public void ensure_ui_update () {
    while (Gtk.events_pending())
        Gtk.main_iteration();
    return;
}

public bool is_left_to_right (Gtk.Widget widget) {
    var dir = widget.get_direction ();
    if (dir == Gtk.TextDirection.NONE)
        dir = Gtk.Widget.get_default_direction ();
    return dir == Gtk.TextDirection.LTR;
}

public Gtk.Separator add_separator (Gtk.Box box,
                                       Gtk.Orientation orientation = Gtk.Orientation.VERTICAL,
                                       Gtk.PackType pack_type = Gtk.PackType.START) {
    var separator = new Gtk.Separator(orientation);
    /* Requesting a pixel seems to be the only way to get some themes
     * to actually render the separator. i.e. Adwaita... */
    switch (orientation) {
        case Gtk.Orientation.HORIZONTAL:
            separator.set_size_request(-1, 1);
            break;
        default:
            separator.set_size_request(1, -1);
            break;
    }
    switch (pack_type) {
        case Gtk.PackType.END:
            box.pack_end(separator, false, true, 0);
            break;
        default:
            box.pack_start(separator, false, true, 0);
            break;
    }
    separator.show();
    return separator;
}

public void set_default_button_relief (Gtk.Container container) {
    foreach (Gtk.Widget widget in container.get_children())
        if (widget is Gtk.Button)
            ((Gtk.Button) widget).relief = Gtk.ReliefStyle.NONE;
    return;
}

public void cr_set_source_rgba (Cairo.Context cr, Gdk.RGBA color, double? alpha = null) {
    if (alpha == null)
        cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
    else
        cr.set_source_rgba(color.red, color.green, color.blue, alpha);
    return;
}

public Gdk.RGBA darker (Gdk.RGBA rgba, double factor) {
    var color = Color.from_gdk_rgba(rgba);
    color.darken_by_sat(factor);
    return color.to_gdk_rgba();
}

public bool color_is_light (Color color) {
    double Pr = (color.R * color.R) * 0.2126;
    double Pg = (color.G * color.G) * 0.7152;
    double Pb = (color.B * color.B) * 0.0722;
    return Math.sqrt(Pr + Pg + Pb) > 127.5;
}

/* From libplank, namespace modified, "using" declarations removed. */

//
//  Copyright (C) 2011 Robert Dyer
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

/**
 * Represents a RGBA color and has methods for manipulating the color.
 */
public struct Color
{
    /**
     * The red value for the color.
     */
    public double R;
    /**
     * The green value for the color.
     */
    public double G;
    /**
     * The blue value for the color.
     */
    public double B;
    /**
     * The alpha value for the color.
     */
    public double A;

    /**
     * Creates a new color from a {@link Gdk.Color}.
     *
     * @param color the color to use
     * @return new {@link Color} based on the given one
     */
    public static Color from_gdk_color (Gdk.Color color) {
        return { (double) color.red / uint16.MAX,
                  (double) color.green / uint16.MAX,
                  (double) color.blue / uint16.MAX,
                  1.0 };
    }

    /**
     * Creates a new {@link Gdk.Color}.from this color
     *
     * @return new {@link Gdk.Color}
     */
    public Gdk.Color to_gdk_color () {
        return { 0,
                (uint16) (R * uint16.MAX),
                (uint16) (G * uint16.MAX),
                (uint16) (B * uint16.MAX) };
    }

    /**
     * Creates a new color from a {@link Gdk.RGBA}.
     *
     * @param color the color to use
     * @return new {@link Color} based on the given one
     */
    public static Color from_gdk_rgba (Gdk.RGBA color) {
        return { color.red, color.green, color.blue, color.alpha };
    }

    /**
     * Creates a new {@link Gdk.RGBA}.from this color
     *
     * @return new {@link Gdk.RGBA}
     */
    public Gdk.RGBA to_gdk_rgba () {
        return { R, G, B, A };
    }

    /**
     * Check equality with the give color
     *
     * @return whether the give color equals this color.
     */
    public bool equal (Color color) {
        return (R == color.R && G == color.G && B == color.B && A == color.A);
    }

    /**
     * Set HSV color values of this color.
     */
    public void set_hsv (double h, double s, double v) {
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Sets the hue for the color.
     *
     * @param hue the new hue for the color
     */
    public void set_hue (double hue)
    requires (hue >= 0 && hue <= 360) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        h = hue;
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Sets the saturation for the color.
     *
     * @param sat the new saturation for the color
     */
    public void set_sat (double sat)
    requires (sat >= 0 && sat <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        s = sat;
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Sets the value for the color.
     *
     * @param val the new value for the color
     */
    public void set_val (double val)
    requires (val >= 0 && val <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        v = val;
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Sets the alpha for the color.
     *
     * @param alpha the new alpha for the color
     */
    public void set_alpha (double alpha)
    requires (alpha >= 0 && alpha <= 1) {
        A = alpha;
    }

    /**
     * Get HSV color values of this color.
     */
    public void get_hsv (out double h, out double s, out double v) {
        rgb_to_hsv(R, G, B, out h, out s, out v);
    }

    /**
     * Returns the hue for the color.
     *
     * @return the hue for the color
     */
    public double get_hue () {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        return h;
    }

    /**
     * Returns the saturation for the color.
     *
     * @return the saturation for the color
     */
    public double get_sat () {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        return s;
    }

    /**
     * Returns the value for the color.
     *
     * @return the value for the color
     */
    public double get_val () {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        return v;
    }

    /**
     * Increases the color's hue.
     *
     * @param val the amount to add to the hue
     */
    public void add_hue (double val) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        h = (((h + val) % 360) + 360) % 360;
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Limits the color's saturation.
     *
     * @param sat the minimum saturation allowed
     */
    public void set_min_sat (double sat)
    requires (sat >= 0 && sat <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        s = double.max (s, sat);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Limits the color's value.
     *
     * @param val the minimum value allowed
     */
    public void set_min_value (double val)
    requires (val >= 0 && val <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        v = double.max (v, val);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Limits the color's saturation.
     *
     * @param sat the maximum saturation allowed
     */
    public void set_max_sat (double sat)
    requires (sat >= 0 && sat <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        s = double.min (s, sat);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Limits the color's value.
     *
     * @param val the maximum value allowed
     */
    public void set_max_val (double val)
    requires (val >= 0 && val <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        v = double.min (v, val);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Multiplies the color's saturation using the amount.
     *
     * @param amount amount to multiply the saturation by
     */
    public void multiply_sat (double amount)
    requires (amount >= 0) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        s = double.min (1, s * amount);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Brighten the color's value using the value.
     *
     * @param amount percent of the value to brighten by
     */
    public void brighten_val (double amount)
    requires (amount >= 0 && amount <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        v = double.min (1, v + (1 - v) * amount);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Darkens the color's value using the value.
     *
     * @param amount percent of the value to darken by
     */
    public void darken_val (double amount)
    requires (amount >= 0 && amount <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        v = double.max (0, v - (1 - v) * amount);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    /**
     * Darkens the color's value using the saturtion.
     *
     * @param amount percent of the saturation to darken by
     */
    public void darken_by_sat (double amount)
    requires (amount >= 0 && amount <= 1) {
        double h, s, v;
        rgb_to_hsv(R, G, B, out h, out s, out v);
        v = double.max (0, v - amount * s);
        hsv_to_rgb(h, s, v, out R, out G, out B);
    }

    static void rgb_to_hsv (double r, double g, double b, out double h, out double s, out double v)
    requires (r >= 0 && r <= 1)
    requires (g >= 0 && g <= 1)
    requires (b >= 0 && b <= 1) {
        v = double.max (r, double.max (g, b));
        if (v == 0) {
            h = 0;
            s = 0;
            return;
        }

        // normalize value to 1
        r /= v;
        g /= v;
        b /= v;

        var min = double.min(r, double.min(g, b));
        var max = double.max(r, double.max(g, b));

        var delta = max - min;
        s = delta;
        if (s == 0) {
            h = 0;
            return;
        }

        // normalize saturation to 1
        r = (r - min) / delta;
        g = (g - min) / delta;
        b = (b - min) / delta;

        if (max == r) {
            h = 0 + 60 * (g - b);
            if (h < 0)
                h += 360;
        } else if (max == g) {
            h = 120 + 60 * (b - r);
        } else {
            h = 240 + 60 * (r - g);
        }
    }

    static void hsv_to_rgb (double h, double s, double v, out double r, out double g, out double b)
    requires (h >= 0 && h <= 360)
    requires (s >= 0 && s <= 1)
    requires (v >= 0 && v <= 1) {
        r = 0;
        g = 0;
        b = 0;

        if (s == 0) {
            r = v;
            g = v;
            b = v;
        } else {
            var secNum = (int) Math.floor(h / 60);
            var fracSec = h / 60.0 - secNum;

            var p = v * (1 - s);
            var q = v * (1 - s * fracSec);
            var t = v * (1 - s * (1 - fracSec));

            switch (secNum) {
                case 0:
                    r = v;
                    g = t;
                    b = p;
                    break;
                case 1:
                    r = q;
                    g = v;
                    b = p;
                    break;
                case 2:
                    r = p;
                    g = v;
                    b = t;
                    break;
                case 3:
                    r = p;
                    g = q;
                    b = v;
                    break;
                case 4:
                    r = t;
                    g = p;
                    b = v;
                    break;
                case 5:
                    r = v;
                    g = p;
                    b = q;
                    break;
            }
        }
    }

    /**
     * Convert color to string formatted like "%d;;%d;;%d;;%d"
     * with numeric entries ranged in 0..255
     *
     * @return the string representation of this color
     */
    public string to_string () {
        return "%d;;%d;;%d;;%d".printf ((int) (R * uint8.MAX),
                                         (int) (G * uint8.MAX),
                                         (int) (B * uint8.MAX),
                                         (int) (A * uint8.MAX));
    }

    /**
     * Create new color converted from string formatted like
     * "%d;;%d;;%d;;%d" with numeric entries ranged in 0..255
     *
     * @return new {@link Color} based on the given string
     */
    public static Color from_string (string s) {
        var parts = s.split (";;");

        if (parts.length != 4) {
            critical("Malformed color string '%s'", s);
            return {0};
        }

        return { double.min(uint8.MAX, double.max(0, int.parse(parts [0]))) / uint8.MAX,
                  double.min(uint8.MAX, double.max(0, int.parse(parts [1]))) / uint8.MAX,
                  double.min(uint8.MAX, double.max(0, int.parse(parts [2]))) / uint8.MAX,
                  double.min(uint8.MAX, double.max(0, int.parse(parts [3]))) / uint8.MAX };
    }
}
