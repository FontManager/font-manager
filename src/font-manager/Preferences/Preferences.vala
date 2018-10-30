/* Preferences.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

    public Preferences construct_preference_pane () {
        Preferences pane = new Preferences();
        pane.add_page(new UserInterfacePreferences(), "Interface", _("Interface"));
        pane.add_page(new DisplayPreferences(), "Display", _("Display"));
        pane.add_page(new RenderingPreferences(), "Rendering", _("Rendering"));
        pane.add_page(new SourcePreferences(), "Sources", _("Sources"));
        pane.add_page(new SubstitutionPreferences(), "Substitutions", _("Substitutions"));
        return pane;
    }

    public class Preferences : Gtk.Paned {

        public Gtk.Widget visible_child { get; set; }
        public string visible_child_name { get; set; }

        Gtk.Box box;
        Gtk.Stack stack;
        Gtk.StackSidebar sidebar;

        public Preferences () {
            Object(name: "Preferences",
                    orientation: Gtk.Orientation.HORIZONTAL,
                    expand: true, position: 275);
            stack = new Gtk.Stack();
            stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            sidebar = new Gtk.StackSidebar();
            sidebar.set_stack(stack);
            sidebar.get_style_context().remove_class(Gtk.STYLE_CLASS_SIDEBAR);
            sidebar.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            box.pack_start(sidebar, true, true, 0);
            add1(box);
            add2(stack);
            bind_properties();
            connect_signals();
        }

        void bind_properties () {
            stack.bind_property("visible-child", this, "visible-child");
            stack.bind_property("visible-child-name", this, "visible-child-name");
        }

        void connect_signals () {
            return;
        }

        public override void show () {
            box.show();
            stack.show();
            sidebar.show();
            base.show();
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

        Gtk.Button save;
        Gtk.Button discard;

        public FontConfigControls () {
            save = new Gtk.Button.with_label(_("Save"));
            save.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            discard = new Gtk.Button.with_label(_("Discard"));
            discard.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            note = new Gtk.Label(_("Running applications may require a restart to reflect any changes."));
            note.set("opacity", 0.75, "wrap", true, "justify", Gtk.Justification.CENTER, null);
            pack_end(save);
            pack_start(discard);
            set_center_widget(note);
            connect_signals();
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            save.show();
            discard.show();
            note.show();
            base.show();
            return;
        }

        void connect_signals () {
            save.clicked.connect(() => { save_selected(); });
            discard.clicked.connect(() => { discard_selected(); });
            return;
        }

    }

    /**
     * SettingsPage:
     *
     * Base class for pages which generate Fontconfig configuration files.
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

