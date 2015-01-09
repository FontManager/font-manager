/* PreviewControls.vala
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

    public class PreviewControls : Gtk.EventBox {

        public signal void justification_set (Gtk.Justification justification);
        public signal void editing (bool enabled);
        public signal void on_clear_clicked ();

        public bool clear_is_sensitive {
            get {
                return clear.get_sensitive();
            }
            set {
                clear.set_sensitive(value);
            }
        }

        private Gtk.Box box;
        private Gtk.Button clear;
        private Gtk.ToggleButton edit;
        private Gtk.RadioButton justify_left;
        private Gtk.RadioButton justify_center;
        private Gtk.RadioButton justify_fill;
        private Gtk.RadioButton justify_right;

        construct {
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
            box.border_width = 1;
            justify_left = new Gtk.RadioButton(null);
            justify_left.set_tooltip_text(_("Left Aligned"));
            justify_center = new Gtk.RadioButton.from_widget(justify_left);
            justify_center.set_tooltip_text(_("Centered"));
            justify_fill = new Gtk.RadioButton.from_widget(justify_left);
            justify_fill.set_tooltip_text(_("Fill"));
            justify_right = new Gtk.RadioButton.from_widget(justify_left);
            justify_right.set_tooltip_text(_("Right Aligned"));
            justify_left.set_image(new Gtk.Image.from_icon_name("format-justify-left-symbolic", Gtk.IconSize.MENU));
            justify_center.set_image(new Gtk.Image.from_icon_name("format-justify-center-symbolic", Gtk.IconSize.MENU));
            justify_fill.set_image(new Gtk.Image.from_icon_name("format-justify-fill-symbolic", Gtk.IconSize.MENU));
            justify_right.set_image(new Gtk.Image.from_icon_name("format-justify-right-symbolic", Gtk.IconSize.MENU));
            edit = new Gtk.ToggleButton();
            edit.set_image(new Gtk.Image.from_icon_name("insert-text-symbolic", Gtk.IconSize.MENU));
            edit.set_tooltip_text(_("Edit preview text"));
            clear = new Gtk.Button();
            clear.set_image(new Gtk.Image.from_icon_name("edit-undo-symbolic", Gtk.IconSize.MENU));
            clear.set_tooltip_text(_("Undo changes"));
            edit.relief = Gtk.ReliefStyle.NONE;
            clear.relief = Gtk.ReliefStyle.NONE;
            Gtk.RadioButton [] buttons = {justify_left, justify_center, justify_fill, justify_right};
            foreach (var button in buttons) {
                button.relief = Gtk.ReliefStyle.NONE;
                ((Gtk.ToggleButton) button).draw_indicator = false;
                button.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
            }
            box.pack_start(justify_left, false, false, 0);
            box.pack_start(justify_center, false, false, 0);
            box.pack_start(justify_fill, false, false, 0);
            box.pack_start(justify_right, false, false, 0);
            box.pack_end(clear, false, false, 0);
            box.pack_end(edit, false, false, 0);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            add(box);
            connect_signals();

        }

        public override void show () {
            clear.show();
            edit.show();
            justify_left.show();
            justify_center.show();
            justify_fill.show();
            justify_right.show();
            box.show();
            base.show();
            return;
        }

        private void connect_signals () {
            justify_center.active = true;
            edit.active = false;
            clear.sensitive = false;
            justify_left.toggled.connect(() => { justification_set(Gtk.Justification.LEFT); });
            justify_center.toggled.connect(() => { justification_set(Gtk.Justification.CENTER); });
            justify_fill.toggled.connect(() => { justification_set(Gtk.Justification.FILL); });
            justify_right.toggled.connect(() => { justification_set(Gtk.Justification.RIGHT); });
            clear.clicked.connect(() => { on_clear_clicked(); });
            edit.toggled.connect(() => { editing(edit.get_active()); });
            return;
        }

    }

}
