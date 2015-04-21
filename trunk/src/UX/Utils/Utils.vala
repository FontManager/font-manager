/* Utils.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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
            critical("Error launching uri handler : %s", e.message);
        }
        return;
    }

    public void set_g_app_menu (Gtk.Application app, Gtk.Builder builder) {
        try {
            builder.add_from_resource("/org/gnome/FontManager/ApplicationMenu.ui");
            app.app_menu = builder.get_object("ApplicationMenu") as GLib.MenuModel;
        } catch (Error e) {
            warning("Failed to set application menu : %s", e.message);
        }
        return;
    }

    public void set_application_style () {
    #if GTK_314_OR_LATER
        Gtk.IconTheme.get_default().add_resource_path("/org/gnome/FontManager/icons");
    #endif
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

public Pango.FontDescription get_font (Gtk.Widget widget, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL) {
    Pango.FontDescription desc;
    widget.get_style_context().get(flags, "font", out desc, null);
    return desc.copy();
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
    var context = widget.get_style_context();
    var state = context.get_state();
    if ((state & Gtk.StateFlags.DIR_LTR) != 0)
        return true;
    return false;
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

