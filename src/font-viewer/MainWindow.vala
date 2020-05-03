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
    internal const string welcome_tmpl = "<span size=\"xx-large\" weight=\"bold\">%s</span>\n<span size=\"large\">\n\n%s\n</span>\n\n\n<span size=\"x-large\">%s</span>";

    internal const int DEFAULT_WIDTH = 600;
    internal const int DEFAULT_HEIGHT = 400;

    struct FontTypeEntry {

        public string name;
        public string tooltip;
        public string url;

        public FontTypeEntry (string name, string tooltip, string url) {
            this.name = name;
            this.tooltip = tooltip;
            this.url = url;
        }

    }

    class TypeInfoCache : Object {

        FontTypeEntry [] types = {
            FontTypeEntry("null", "", ""),
            FontTypeEntry("opentype", _("OpenType Font"), "http://wikipedia.org/wiki/OpenType"),
            FontTypeEntry("truetype", _("TrueType Font"), "http://wikipedia.org/wiki/TrueType"),
            FontTypeEntry("type1", _("PostScript Type 1 Font"), "http://wikipedia.org/wiki/Type_1_Font#Type_1"),
        };

        public new FontTypeEntry get (string key) {
            var _key = key.down().replace(" ", "");
            foreach (var entry in types)
                if (entry.name == _key)
                    return entry;
            return types[0];
        }

        public void update (Gtk.Image icon, string key) {
            var entry = this[key];
            icon.set_from_icon_name(entry.name, Gtk.IconSize.LARGE_TOOLBAR);
            icon.set_tooltip_text(entry.tooltip);
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-viewer-main-window.ui")]
    public class MainWindow : Gtk.ApplicationWindow {

        public signal void mode_changed (FontPreviewMode mode);

        public FontPreviewMode mode { get; set; }
        public PreviewPane preview { get; private set; }
        public Settings? settings { get; set; default = null; }

        [GtkChild] Gtk.Stack stack;
        [GtkChild] Gtk.Box preview_page;
        [GtkChild] Gtk.Box welcome_page;
        [GtkChild] Gtk.Image type_icon;
        [GtkChild] Gtk.HeaderBar titlebar;

        Gtk.Button install_button;

        PlaceHolder welcome;
        StringHashset installed;
        TypeInfoCache type_info_cache;

        public override void constructed () {
            settings = get_gsettings(FontViewer.BUS_ID);
            type_info_cache = new TypeInfoCache();
            installed = new StringHashset();
            preview = new PreviewPane();
            install_button = new Gtk.Button();
            install_button.margin = MINIMUM_MARGIN_SIZE;
            install_button.set_label(_("Install Font"));
            install_button.opacity = 0.725;
            install_button.clicked.connect(on_install_clicked);
            update_install_button_state();
            preview.notebook.set_action_widget(install_button, Gtk.PackType.END);
            welcome = new PlaceHolder(welcome_tmpl.printf(w1, w2, w3), "font-x-generic-symbolic");
            preview_page.add(preview);
            welcome_page.add(welcome);
            stack.set_visible_child_name("Welcome");
            preview.show();
            welcome.show();
            install_button.show();

            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            Gtk.drag_dest_set(stack, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);

            bind_property("mode", preview, "mode", BindingFlags.BIDIRECTIONAL);
            preview.preview_mode_changed.connect((m) => { mode_changed(m); });
            preview.changed.connect(this.update);

            insert_action_group("default", new SimpleActionGroup());

            var action = new SimpleAction("zoom_in", null);
            action.activate.connect((a, v) => { preview.preview_size += 0.5; });
            string? [] accels = { "<Ctrl>plus", "<Ctrl>equal", null };
            add_keyboard_shortcut(this, action, "zoom_in", accels);

            action = new SimpleAction("zoom_out", null);
            action.activate.connect((a, v) => { preview.preview_size -= 0.5; });
            accels = { "<Ctrl>minus", null };
            add_keyboard_shortcut(this, action, "zoom_out", accels);

            action = new SimpleAction("zoom_default", null);
            action.activate.connect((a, v) => { preview.preview_size = DEFAULT_PREVIEW_SIZE; });
            accels = { "<Ctrl>0", null };
            add_keyboard_shortcut(this, action, "zoom_default", accels);

            base.constructed();
            return;
        }

        public bool ready () {
            return this.visible;
        }

        public void show_uri (string uri) {
            preview.show_uri(uri);
            update();
            return;
        }

        public void open (string arg)  {
            preview.show_uri(arg);
            return;
        }

        public void set_preview_text (string preview_text) {
            preview.set_preview_text(preview_text);
            return;
        }

        public void update () {
            bool have_valid_source = preview.selected_font.is_valid();
            if (have_valid_source) {
                preview.metadata.update();
                update_titlebar(preview.selected_font.family,
                                preview.selected_font.style,
                                preview.metadata.info.filetype);
            } else {
                update_titlebar(null, null, "");
            }
            stack.set_visible_child_name(have_valid_source ? "Preview" : "Welcome");
            update_install_button_state();
            queue_draw();
            return;
        }

        void reset_titlebar () {
            titlebar.set_title(null);
            titlebar.set_subtitle(null);
            type_info_cache.update(type_icon, "null");
            return;
        }

        void update_titlebar (string? family, string? style, string? filetype) {
            reset_titlebar();
            if (family == null && style == null) {
                titlebar.set_title(_("No file selected"));
                titlebar.set_subtitle(_("Or unsupported filetype."));
                return;
            }
            titlebar.set_title(family);
            titlebar.set_subtitle(style);
            const string tt_tmpl = "<big><b>%s</b> </big><b>%s</b>";
            titlebar.set_tooltip_markup(tt_tmpl.printf(Markup.escape_text(family), style));
            type_info_cache.update(type_icon, filetype);
            return;
        }

        void on_install_clicked () {
            var filelist = new StringHashset();
            filelist.add(preview.selected_font.filepath);
            var installer = new Library.Installer();
            installer.process.begin(filelist, (obj, res) => {
                installer.process.end(res);
                installed.add(preview.metadata.info.checksum);
                update_install_button_state();
            });
            return;
        }

        void update_install_button_state () {
            bool have_valid_source = preview.selected_font.is_valid();
            install_button.set_visible(have_valid_source);
            if (!have_valid_source)
                return;
            clear_application_fonts();
            return_if_fail(preview.metadata.info.is_valid());
            bool _installed = Library.is_installed(preview.metadata.info);
            string? conflict = Library.conflicts(preview.selected_font);
            add_application_font(preview.metadata.info.filepath);
            if (!_installed && installed.contains(preview.metadata.info.checksum))
                _installed = true;
            install_button.sensitive = false;
            install_button.get_style_context().add_class("InsensitiveButton");
            if (conflict != null && timecmp(conflict, preview.selected_font.filepath) > 0) {
                install_button.set_label(_("Newer version already installed"));
            } else if (_installed) {
                install_button.set_label(_("Installed"));
            } else {
                install_button.get_style_context().remove_class("InsensitiveButton");
                install_button.set_label(_("Install Font"));
                install_button.sensitive = true;
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
            mode_changed.connect((m) => {
                settings.set_enum("mode", ((int) m));
            });
            preview.preview_text_changed.connect((p) => { settings.set_string("preview-text", p); });
            settings.bind("preview-font-size", preview, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("charmap-font-size", preview.charmap, "preview-size", SettingsBindFlags.DEFAULT);
            settings.delay();
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
            preview.preview_size = settings.get_double("preview-font-size");
            var preview_text = settings.get_string("preview-text");
            if (preview_text != "DEFAULT")
                preview.set_preview_text(preview_text);
            preview.mode = ((FontPreviewMode) settings.get_enum("mode"));
            Idle.add(() => { bind_settings(); return false; });
            return;
        }

        public override void drag_data_received (Gdk.DragContext context,
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
