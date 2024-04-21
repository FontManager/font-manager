/* MainWindow.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    public enum Mode {

        MANAGE,
        BROWSE,
        COMPARE,
        N_MODES;

        public static Mode parse (string mode) {
            switch (mode.down()) {
                case "browse":
                    return Mode.BROWSE;
                case "compare":
                    return Mode.COMPARE;
                default:
                    return Mode.MANAGE;
            }
        }

        public string to_string () {
            switch (this) {
                case BROWSE:
                    return "Browse";
                case COMPARE:
                    return "Compare";
                default:
                    return "Default";
            }
        }

        public string to_translatable_string () {
            switch (this) {
                case BROWSE:
                    return _("Browse");
                case COMPARE:
                    return _("Compare");
                default:
                    return _("Manage");
            }
        }

    }

    public class MainWindow : ApplicationWindow {

        public bool show_preferences { get; set; default = false; }
        public bool show_webfonts { get; set; default = false; }

        public Mode mode {
            get {
                return _mode;
            }
            set {
                if (!show_webfonts)
                    _mode = value;
                notify_property("mode");
            }
        }

        public Json.Array? available_fonts { get; set; default = null; }

        Gtk.Stack main_stack;
        MainPane main_pane;
        PreferencePane prefs_pane;
        HeaderBarWidgets header_widgets;

        Mode _mode = Mode.MANAGE;

#if HAVE_WEBKIT
        GoogleFonts.Catalog webfonts;
#endif /* HAVE_WEBKIT */

        static construct {
            install_property_action("mode", "mode");
            install_property_action("show-preferences", "show-preferences");
            install_property_action("show-webfonts", "show-webfonts");
            uint [] mode_accels = { Gdk.Key.@1, Gdk.Key.@2, Gdk.Key.@3 };
            Gdk.ModifierType mode_mask = Gdk.ModifierType.CONTROL_MASK;
            EnumClass mode_class = ((EnumClass) typeof(Mode).class_ref());
            for (int i = 0; i < Mode.N_MODES; i++) {
                string nick = mode_class.get_value(i).value_nick;
                add_binding_action(mode_accels[i], mode_mask, "mode", "s", nick);
            }
        }

        construct {
            var header = new Gtk.HeaderBar();
            header_widgets = new HeaderBarWidgets();
            header.pack_start(header_widgets.main_menu);
#if HAVE_WEBKIT
            header.pack_start(header_widgets.revealer);
#endif /* HAVE_WEBKIT */
            header.pack_end(header_widgets.app_menu);
            header.pack_end(header_widgets.prefs_toggle);
            set_titlebar(header);
            main_stack = new Gtk.Stack();
            main_stack.set_transition_type(Gtk.StackTransitionType.OVER_DOWN_UP);
            main_stack.set_transition_duration(500);
            main_pane = new MainPane();
            prefs_pane = new PreferencePane();
            main_stack.add_named(main_pane, "Default");
#if HAVE_WEBKIT
            webfonts = new GoogleFonts.Catalog();
            main_stack.add_named(webfonts, "WebFonts");
#endif /* HAVE_WEBKIT */
            main_stack.add_named(prefs_pane, "Preferences");
            set_child(main_stack);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("mode", main_pane, "mode", flags);
            bind_property("available-fonts", main_pane, "available-fonts", flags);
            prefs_pane.bind_property("user-actions", main_pane, "user-actions", flags);
            prefs_pane.bind_property("user-sources", main_pane, "user-sources", flags);
            main_pane.bind_property("sidebar-position", prefs_pane, "sidebar-position", flags);
#if HAVE_WEBKIT
            main_pane.bind_property("content-position", webfonts, "content-position", flags);
            main_pane.bind_property("sidebar-position", webfonts, "sidebar-position", flags);
#endif /* HAVE_WEBKIT */
            notify["mode"].connect(on_mode_changed);
            notify["show-preferences"].connect(on_stack_page_changed);
#if HAVE_WEBKIT
            notify["show-webfonts"].connect(on_stack_page_changed);
#endif /* HAVE_WEBKIT */
        }

        void on_mode_changed (ParamSpec pspec) {
            string markup = "<b>%s</b>".printf(mode.to_translatable_string());
            header_widgets.main_menu_label.set_markup(markup);
            header_widgets.reveal_manage_controls(mode == Mode.MANAGE);
            return;
        }

        void on_stack_page_changed (ParamSpec pspec) {
            if (show_preferences)
                main_stack.set_visible_child_name("Preferences");
#if HAVE_WEBKIT
            else if (show_webfonts)
                main_stack.set_visible_child_name("WebFonts");
#endif /* HAVE_WEBKIT */
            else
                main_stack.set_visible_child_name("Default");
            header_widgets.main_menu.set_sensitive(!show_webfonts);
            return;
        }

    }

}
