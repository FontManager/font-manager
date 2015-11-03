/* RenderingOptions.vala
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

    public class RenderingOptions : Gtk.Window {

        public FontConfig.FontProperties properties {
            get {
                return pane.properties;
            }
        }

//        public Gtk.ToggleButton toggle { get; private set; }

        Gtk.Box box;
        Gtk.Label note;
        Gtk.ActionBar action_bar;
        Gtk.HeaderBar header_bar;
        Gtk.Button save;
        Gtk.Button discard;
        FontConfig.FontPropertiesPane pane;

        public RenderingOptions () {
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            pane = new FontConfig.FontPropertiesPane();
            action_bar = new Gtk.ActionBar();
            header_bar = new Gtk.HeaderBar();
            save = new Gtk.Button.with_label(_("Save"));
            discard = new Gtk.Button.with_label(_("Discard"));
            action_bar.pack_end(save);
            action_bar.pack_start(discard);
            discard.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            save.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            note = new Gtk.Label(_("Running applications may require a restart to reflect any changes."));
            note.opacity = 0.75;
            note.margin_start = note.margin_end = 6;
            note.wrap = true;
            note.justify = Gtk.Justification.CENTER;
            action_bar.set_center_widget(note);
            if (((Application) GLib.Application.get_default()).use_headerbar) {
                set_titlebar(header_bar);
                header_bar.show_close_button = true;
            } else {
                box.pack_start(header_bar, true, true, 0);
            }
            box.pack_start(pane, true, true, 0);
            box.pack_end(action_bar, false, false, 0);
            add(box);
//            toggle = new Gtk.ToggleButton();
//            toggle.relief = Gtk.ReliefStyle.NONE;
//            toggle.can_focus = false;
//            toggle.margin = 2;
//            toggle.set_tooltip_text(_("Adjust rendering options"));
//            var icon = new Gtk.Image.from_icon_name("preferences-system-symbolic", Gtk.IconSize.MENU);
//            toggle.add(icon);
//            icon.show();
//            toggle.show();
//            toggle.toggled.connect(() => {
//                if (toggle.active)
//                    this.show();
//                else
//                    this.hide();
//            });
            save.clicked.connect(() => {
                properties.save();
                this.hide();
            });
            discard.clicked.connect(() => {
                properties.discard();
                this.hide();
            });
            delete_event.connect(() => {
                return this.hide_on_delete();
            });
            properties.changed.connect(() => {
                header_bar.set_title(properties.family);
                if (properties.font != null)
                    header_bar.set_subtitle(properties.font.style);
                else
                    header_bar.set_subtitle(null);
            });
        }

        public override void show () {
            pane.show();
            note.show();
            action_bar.show();
            header_bar.show();
            save.show();
            discard.show();
            box.show();
            base.show();
            return;
        }

    }

}
