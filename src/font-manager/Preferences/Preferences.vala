/* Preferences.vala
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

//    public Preferences construct_preference_pane () {
    public void initialize_preference_pane (Preferences pane) {
//        Preferences pane = new Preferences();
        pane.add_page(new UserInterfacePreferences(), "Interface", _("Interface"));
        pane.add_page(new SourcePreferences(), "Sources", _("Sources"));
        pane.add_page(new SubstitutionPreferences(), "Substitutions", _("Substitutions"));
        pane.add_page(new DesktopPreferences(), "Desktop", _("Desktop"));
        pane.add_page(new DisplayPreferences(), "Display", _("Display"));
        pane.add_page(new RenderingPreferences(), "Rendering", _("Rendering"));
        return;// pane;
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preferences.ui")]
    public class Preferences : Gtk.Paned {

        public Gtk.Widget visible_child { get; set; }
        public string visible_child_name { get; set; }

        [GtkChild] Gtk.Stack stack;
        [GtkChild] Gtk.StackSidebar sidebar;

        public override void constructed () {
            sidebar.get_style_context().remove_class(Gtk.STYLE_CLASS_SIDEBAR);
            stack.bind_property("visible-child", this, "visible-child");
            stack.bind_property("visible-child-name", this, "visible-child-name");
            base.constructed();
            return;
        }

        public void add_page (Gtk.Widget widget, string name, string title) {
            Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
            scroll.add(widget);
            stack.add_titled(scroll, name, title);
            widget.show();
            scroll.show();
            return;
        }

        public Gtk.Widget get_page (string name) {
            var scroll = ((Gtk.Container) stack.get_child_by_name(name));
            var viewport = scroll.get_children().nth_data(0);
            var widget = ((Gtk.Container) viewport).get_children().nth_data(0);
            return widget;
        }

    }

    /**
     * SettingsPage:
     *
     * Base class for preference panes.
     */
    public class SettingsPage : Gtk.Box {

        protected Gtk.Label message;
        protected Gtk.InfoBar infobar;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            infobar = new Gtk.InfoBar();
            infobar.message_type = Gtk.MessageType.INFO;
            message = new Gtk.Label(null);
            infobar.get_content_area().add(message);
            pack_start(infobar, false, false, 0);
            infobar.response.connect((id) => {
                if (id == Gtk.ResponseType.CLOSE)
                    infobar.hide();
            });
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        }

        public override void show () {
            message.show();
            base.show();
            return;
        }

        protected virtual void show_message (string m) {
            message.set_markup("<b>%s</b>".printf(m));
            infobar.show();
            infobar.queue_resize();
            Timeout.add_seconds(3, () => {
                infobar.hide();
                infobar.queue_resize();
                return infobar.visible;
            });
            return;
        }

    }

    /**
     * FontConfigControls:
     *
     * #Gtk.Actionbar containing a save and discard button along with a notice
     * informing the user that changes may not take effect immediately.
     * Intended for use in pages which generate Fontconfig configuration files.
     *
     * -----------------------------------------------------------------------
     * |                                                                     |
     * |  Discard                     note                           Save    |
     * |                                                                     |
     * -----------------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-config-controls.ui")]
    public class FontConfigControls : Gtk.ActionBar {

        /**
         * Controls::save_selected:
         *
         * Emitted when the user clicks Save
         */
        public signal void save_selected ();

        /**
         * Controls::discard_selected:
         *
         * Emitted when the user clicks Discard
         */
        public signal void discard_selected ();

        /**
         * Controls:note:
         *
         * Informational notice displayed between discard and save buttons.
         */
        public Gtk.Label note { get; private set; }

        [GtkChild] Gtk.Button save_button;
        [GtkChild] Gtk.Button discard_button;

        public override void constructed () {
            save_button.clicked.connect(() => { save_selected(); });
            discard_button.clicked.connect(() => { discard_selected(); });
            base.constructed();
            return;
        }

    }

    /**
     * FontConfigSettingsPage:
     *
     * Base class for panes which generate Fontconfig configuration files.
     */
    public class FontConfigSettingsPage : SettingsPage {

        protected FontConfigControls controls;

        construct {
            controls = new FontConfigControls();
            pack_end(controls, false, false, 0);
        }

        public override void show () {
            controls.show();
            base.show();
            return;
        }

    }

}

