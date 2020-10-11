/* MainWindow.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

namespace FontManager.FontViewer {

    internal const string w1 = _("Font Viewer");
    internal const string w2 = _("Preview font files before installing them.");
    internal const string w3 = _("To preview a font simply drag it onto this area.");

    internal const int DEFAULT_WIDTH = 600;
    internal const int DEFAULT_HEIGHT = 400;

    internal const Gtk.TargetEntry [] DragTargets = {
        { "text/uri-list", Gtk.TargetFlags.OTHER_APP, DragTargetType.EXTERNAL }
    };

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-viewer-main-window.ui")]
    public class MainWindow : Gtk.ApplicationWindow {

        [GtkChild] Gtk.Stack stack;
        [GtkChild] Gtk.HeaderBar titlebar;
        [GtkChild] Gtk.Button install;
        [GtkChild] PreviewPane preview_pane;

        PlaceHolder welcome;
        StringHashset installed;
        Settings? settings = null;

        public override void constructed () {
            settings = get_gsettings(FontViewer.BUS_ID);
            installed = new StringHashset();
            welcome = new PlaceHolder(w1, w2, w3, "font-x-generic-symbolic");
            welcome.show();
            stack.add_named(welcome, "Welcome");
            stack.set_visible_child_name("Welcome");
            preview_pane.set_action_widget(install, Gtk.PackType.END);
            preview_pane.changed.connect(this.update);
            add_actions();
            update_install_state();
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, DragTargets, Gdk.DragAction.COPY);
            base.constructed();
            return;
        }

        void zoom (bool zoom_in, bool zoom_out) {
            var page = (PreviewPanePage) preview_pane.get_current_page();
            if (zoom_in) {
                if (page == PreviewPanePage.CHARACTER_MAP)
                    preview_pane.character_map_preview_size += 0.5;
                else
                    preview_pane.preview_size += 0.5;
            } else if (zoom_out) {
                if (page == PreviewPanePage.CHARACTER_MAP)
                    preview_pane.character_map_preview_size -= 0.5;
                else
                    preview_pane.preview_size -= 0.5;
            } else {
                if (page == PreviewPanePage.CHARACTER_MAP)
                    preview_pane.character_map_preview_size = CHARACTER_MAP_PREVIEW_SIZE;
                else
                    preview_pane.preview_size = DEFAULT_PREVIEW_SIZE;
            }
            return;
        }

        void add_actions () {

            var action = new SimpleAction("zoom_in", null);
            action.activate.connect((a, v) => { zoom(true, false); });
            string? [] accels = { "<Ctrl>plus", "<Ctrl>equal", null };
            add_keyboard_shortcut(action, "zoom_in", accels);

            action = new SimpleAction("zoom_out", null);
            action.activate.connect((a, v) => { zoom(false, true); });
            accels = { "<Ctrl>minus", null };
            add_keyboard_shortcut(action, "zoom_out", accels);

            action = new SimpleAction("zoom_default", null);
            action.activate.connect((a, v) => { zoom(false, false); });
            accels = { "<Ctrl>0", null };
            add_keyboard_shortcut(action, "zoom_default", accels);

            return;
        }

        public void open (string arg)  {
            preview_pane.show_uri(arg);
            update();
            return;
        }

        public void update () {
            bool have_valid_source = preview_pane.font != null && preview_pane.font.is_valid();
            if (have_valid_source)
                update_titlebar(preview_pane.font.family, preview_pane.font.style);
            else
                update_titlebar(null, null);
            stack.set_visible_child_name(have_valid_source ? "Preview" : "Welcome");
            update_install_state();
            queue_draw();
            return;
        }

        void update_titlebar (string? family, string? style) {
            if (family == null && style == null) {
                titlebar.set_title(_("No file selected"));
                titlebar.set_subtitle(_("Or unsupported filetype."));
                return;
            }
            titlebar.set_title(family);
            titlebar.set_subtitle(style);
            const string tt_tmpl = "<big><b>%s</b> </big><b>%s</b>";
            titlebar.set_tooltip_markup(tt_tmpl.printf(Markup.escape_text(family), style));
            return;
        }

        string? conflicts (Font font) {
            try {
                Database db = get_database(DatabaseType.FONT);
                db.execute_query("SELECT DISTINCT filepath FROM Fonts WHERE description = \"%s\"".printf(font.description));
                if (db.stmt.step() == Sqlite.ROW)
                    return db.stmt.column_text(0);
            } catch (Error e) {
                warning(e.message);
            }
            return null;
        }

        bool is_installed (FontInfo info) {
            if (installed.contains(preview_pane.metadata.checksum))
                return true;
            GLib.List <string> filelist = list_available_font_files();
            if (filelist.find_custom(info.filepath, strcmp) != null)
                return true;
            try {
                Database db = get_database(DatabaseType.METADATA);
                db.execute_query("SELECT DISTINCT filepath FROM Metadata WHERE checksum = \"%s\"".printf(info.checksum));
                foreach (unowned Sqlite.Statement row in db)
                    if (filelist.find_custom(row.column_text(0), strcmp) != null)
                        return true;
            } catch (Error e) { }
            return false;
        }

        void update_install_state () {
            bool have_valid_source = preview_pane.font != null && preview_pane.font.is_valid();
            install.set_visible(have_valid_source);
            if (!have_valid_source)
                return;
            clear_application_fonts();
            return_if_fail(preview_pane.metadata.is_valid());
            bool _installed = is_installed(preview_pane.metadata);
            string? conflict = conflicts(preview_pane.font);
            add_application_font(preview_pane.metadata.filepath);
            install.sensitive = false;
            install.get_style_context().add_class("SensitiveChildLabel");
            if (conflict != null && exists(conflict) && timecmp(conflict, preview_pane.font.filepath) > 0) {
                install.set_label(_("Newer version already installed"));
            } else if (_installed) {
                install.set_label(_("Installed"));
            } else {
                install.get_style_context().remove_class("SensitiveChildLabel");
                install.set_label(_("Install Font"));
                install.sensitive = true;
            }
            return;
        }

        void bind_settings () {
            if (settings == null)
                return;
            configure_event.connect((w, e) => {
                /* Avoid tiny windows on Wayland */
                if (e.width < DEFAULT_WIDTH || e.height < DEFAULT_HEIGHT)
                    return false;
                /* Size provided by event is not usable on Gtk+ > 3.18 */
                int actual_window_width, actual_window_height;
                get_size(out actual_window_width, out actual_window_height);
                settings.set("window-size", "(ii)", actual_window_width, actual_window_height);
                settings.set("window-position", "(ii)", e.x, e.y);
                return false;
            });
            settings.bind("mode", preview_pane, "preview-mode", SettingsBindFlags.DEFAULT);
            settings.bind("preview-text", preview_pane, "preview-text", SettingsBindFlags.DEFAULT);
            settings.bind("preview-font-size", preview_pane, "preview-size", SettingsBindFlags.DEFAULT);
            var charmap = preview_pane.get_nth_page(PreviewPanePage.CHARACTER_MAP);
            settings.bind("charmap-font-size", charmap, "preview-size", SettingsBindFlags.DEFAULT);
            settings.delay();
            return;
        }

        [GtkCallback]
        public void on_install_clicked () {
            try {
                File file = File.new_for_path(preview_pane.font.filepath);
                File install_dir = File.new_for_path(get_user_font_directory());
                FontManager.install_file(file, install_dir);
                installed.add(preview_pane.metadata.checksum);
                update_install_state();
            } catch (Error e) {
                critical(e.message);
            }
            return;
        }

        [GtkCallback]
        public bool on_delete_event (Gtk.Widget widget, Gdk.EventAny event) {
            settings.apply();
            ((Application) GLib.Application.get_default()).quit();
            return true;
        }

        [GtkCallback]
        public void on_realize (Gtk.Widget widget) {
            if (settings == null)
                return;
            int x, y, w, h;
            settings.get("window-size", "(ii)", out w, out h);
            settings.get("window-position", "(ii)", out x, out y);
            set_default_size(w, h);
            move(x, y);
            preview_pane.preview_size = settings.get_double("preview-font-size");
            preview_pane.preview_text = settings.get_string("preview-text");
            preview_pane.preview_mode = ((FontPreviewMode) settings.get_enum("mode"));
            Idle.add(() => { bind_settings(); return GLib.Source.REMOVE; });
            return;
        }

        [GtkCallback]
        public void on_drag_data_received (Gdk.DragContext context,
                                           int x,
                                           int y,
                                           Gtk.SelectionData selection_data,
                                           uint info,
                                           uint time) {
            switch (info) {
                case DragTargetType.EXTERNAL:
                    this.open(selection_data.get_uris()[0]);
                    break;
                default:
                    return;
            }
            return;
        }

    }

}
