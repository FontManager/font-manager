/* Preferences.vala
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preferences.ui")]
    public class Preferences : Gtk.Box {

        [GtkChild] public unowned Gtk.Paned paned { get; }

        [GtkChild] unowned Gtk.Stack stack;

        public void add_page (Gtk.Widget widget, string name, string title) {
            Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow();
            scroll.set_child(widget);
            stack.add_titled(scroll, name, title);
            return;
        }

        public new Gtk.Widget? get (string name) {
            Gtk.Widget? child = stack.get_child_by_name(name);
            return_val_if_fail(child != null, null);
            if (child is Gtk.ScrolledWindow)
                child = child.get_child();
            return ((child is Gtk.Viewport) ? child.get_child() : child);
        }

        public Preferences () {
            add_page(new UserInterfacePreferences(), "Interface", _("Interface"));
            add_page(new DesktopPreferences(), "Desktop", _("Desktop"));
            add_page(new UserActionList(), "UserActions", _("Actions"));
            add_page(new UserSourceList(), "Sources", _("Sources"));
            add_page(new SubstituteList(), "Substitutions", _("Substitutions"));
            add_page(new DisplayPreferences(), "Display", _("Display"));
            add_page(new RenderingPreferences(), "Rendering", _("Rendering"));
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preference-list.ui")]
    public class PreferenceList : Gtk.Box {

        [GtkChild] protected unowned Gtk.ListBox list;
        [GtkChild] protected unowned BaseControls controls;
        [GtkChild] protected unowned Gtk.Separator separator;

        construct {
            set_control_sensitivity(controls.add_button, true);
            set_control_sensitivity(controls.remove_button, false);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            controls.bind_property("visible", separator, "visible", flags);
        }

        [GtkCallback]
        protected virtual void on_add_selected () {}

        [GtkCallback]
        protected virtual void on_list_row_selected (Gtk.ListBox box,
                                                     Gtk.ListBoxRow? row) {
            set_control_sensitivity(controls.remove_button, row != null);
            return;
        }

        [GtkCallback]
        protected virtual void on_map () {
            select_first_row();
            return;
        }

        [GtkCallback]
        protected virtual void on_remove_selected () {}

        [GtkCallback]
        protected virtual void on_unmap () {}

        public void select_first_row () {
            list.select_row(list.get_row_at_index(0));
            return;
        }

        protected Gtk.Switch add_preference_switch (string name) {
            var control = new Gtk.Switch();
            append_row(new PreferenceRow(name, null, null, control));
            return control;
        }

        protected void append_row (Gtk.Widget widget) {
            var row = new Gtk.ListBoxRow() { activatable = false, selectable = false };
            row.set_child(widget);
            list.insert(row, -1);
            return;
        }

    }

    public const string FONTCONFIG_DISCLAIMER = _(
"""A Fontconfig configuration file will be generated from these settings.

Running applications may require a restart to reflect any changes.

Note that not all environments/applications will honor these settings."""
    );

    public class FontconfigFooter : Gtk.Box {

        public signal void reset_requested ();

        public FontconfigFooter () {
            orientation = Gtk.Orientation.HORIZONTAL;
            var help = inline_help_widget(FONTCONFIG_DISCLAIMER);
            help.halign = Gtk.Align.START;
            widget_set_margin(help, DEFAULT_MARGIN * 2);
            help.margin_start = (DEFAULT_MARGIN * 3) - 2;
            help.margin_bottom = DEFAULT_MARGIN;
            append(help);
            var reset = new Gtk.Button.from_icon_name("edit-undo-symbolic") {
                opacity = 0.65,
                hexpand = true,
                tooltip_text = _("Reset all values to default")
            };
            widget_set_align(reset, Gtk.Align.END);
            widget_set_margin(reset, DEFAULT_MARGIN * 2);
            reset.add_css_class("rounded");
            reset.clicked.connect(() => { reset_requested(); });
            append(reset);
        }

    }

    public class SubpixelGeometryIcon : Gtk.Box {

        public int preferred_size { get; set; default = 30; }

        public SubpixelGeometryIcon (SubpixelOrder rgba) {

            hexpand = vexpand = homogeneous = true;
            halign = valign = Gtk.Align.CENTER;
            margin_start = margin_end = DEFAULT_MARGIN;

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
                _rgba = value.clamp(0, ((int) options.length));
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
                var icon = new SubpixelGeometryIcon((SubpixelOrder) i);
                var button = new Gtk.CheckButton() {
                    margin_start = DEFAULT_MARGIN,
                    margin_end = DEFAULT_MARGIN,
                    child = icon,
                    tooltip_text = ((SubpixelOrder) i).to_string()
                };
                options.insert(i, button);
                button.set_group(i != 0 ? options[0] : null);
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

