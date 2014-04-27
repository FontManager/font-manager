/* TitleBar.vala
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

    public class TitleBar : Gtk.HeaderBar {

        public signal void search_selected ();
        public signal void install_selected ();
        public signal void remove_selected ();

        public Gtk.MenuButton main_menu { get; private set; }
        public Gtk.Label main_menu_label { get; set; }
        public Gtk.MenuButton app_menu { get; private set; }

        Gtk.Button search;
        Gtk.Button install;
        Gtk.Button _remove;
        Gtk.Revealer revealer;

        public TitleBar () {
            title = About.NAME;
            Gtk.StyleContext ctx = get_style_context();
            ctx.add_class(Gtk.STYLE_CLASS_TITLEBAR);
            ctx.add_class(Gtk.STYLE_CLASS_MENUBAR);
            ctx.set_junction_sides(Gtk.JunctionSides.BOTTOM);
            //header.show_close_button = true;
            main_menu = new Gtk.MenuButton();
            var main_menu_icon = new Gtk.Image.from_icon_name("view-more-symbolic", Gtk.IconSize.MENU);
            var main_menu_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);
            main_menu_container.pack_start(main_menu_icon, false, false, 0);
            main_menu_label = new Gtk.Label(null);
            main_menu_container.pack_end(main_menu_label, false, true, 0);
            main_menu.add(main_menu_container);
            main_menu.direction = Gtk.ArrowType.DOWN;
            main_menu.relief = Gtk.ReliefStyle.NONE;
            app_menu = new Gtk.MenuButton();
            var app_menu_icon = new Gtk.Image.from_icon_name(About.ICON, Gtk.IconSize.LARGE_TOOLBAR);
            app_menu.add(app_menu_icon);
            app_menu.direction = Gtk.ArrowType.DOWN;
            app_menu.relief = Gtk.ReliefStyle.NONE;
            search = new Gtk.Button.from_icon_name("edit-find-symbolic", Gtk.IconSize.MENU);
            search.relief = Gtk.ReliefStyle.NONE;
            search.set_tooltip_text("Search Database");
            revealer = new Gtk.Revealer();
            revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
            var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
            install = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
            install.relief = Gtk.ReliefStyle.NONE;
            install.set_tooltip_text("Add Fonts");
            _remove = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU);
            _remove.relief = Gtk.ReliefStyle.NONE;
            _remove.set_tooltip_text("Remove Fonts");
            add_separator(button_box);
            button_box.pack_start(install, false, false, 1);
            button_box.pack_end(_remove, false, false, 1);
            revealer.add(button_box);
            pack_start(main_menu);
            pack_start(revealer);
            pack_end(search);
            pack_end(app_menu);
            main_menu_icon.show();
            main_menu_container.show();
            main_menu_label.show();
            main_menu.show();
            app_menu_icon.show();
            app_menu.show();
            search.show();
            button_box.show_all();
            revealer.get_style_context().add_class(Gtk.STYLE_CLASS_TITLEBAR);
            revealer.show();
            connect_signals();
        }

        internal void connect_signals () {
            search.clicked.connect((w) => { search_selected(); });
            install.clicked.connect((w) => { install_selected(); });
            _remove.clicked.connect((w) => { remove_selected(); });
            return;
        }

        public void reveal_controls (bool reveal) {
            revealer.set_reveal_child(reveal);
            return;
        }

    }


}
