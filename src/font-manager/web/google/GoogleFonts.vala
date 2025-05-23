/* GoogleFonts.vala
 *
 * Copyright (C) 2020-2025 Jerry Casiano
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

#if HAVE_WEBKIT

namespace FontManager.GoogleFonts {

    const string API_KEY = "QUl6YVN5QTlpUmZqMFlYc184RGhJR1Q1YzNGRDBWNmtSQWV5cFA4";
    const string GET = "GET";
    const string GOOGLE_FONTS_API = "https://www.googleapis.com/webfonts/v1/webfonts?key=%s&sort=%s";
    const string SORT_OPTIONS [5] = { "alpha", "date", "popularity", "style", "trending" };

    public string get_font_directory () {
        return Path.build_filename(get_user_font_directory(), "Google Fonts");
    }

    public class Catalog : FontManager.DualPaned {

        public Json.Array? available_families { get; set; default = null; }
        public WaterfallSettings waterfall_settings { get; set; }

        bool initialized = false;
        uint status_code = Soup.Status.NONE;
        string? reason_phrase = null;
        Error? error = null;
        NetworkMonitor network_monitor;
        PlaceHolder placeholder;
        PreviewPage preview;
        FontListView fontlist;

        static construct {
            install_action("focus-search", null, (Gtk.WidgetActionActivateFunc) focus_search_entry);
            add_binding_action(Gdk.Key.F, Gdk.ModifierType.CONTROL_MASK, "focus-search", null);
        }

        public Catalog (GLib.Settings? settings) {
            base(settings);
            placeholder = new PlaceHolder(null, null, null, "google-fonts-symbolic");
            placeholder.opacity = 0.99;
            widget_set_expand(placeholder, true);
            widget_set_align(placeholder, Gtk.Align.FILL);
            overlay.add_overlay(placeholder);
        }

        bool initialize_pane () {
            var sidebar = new Sidebar();
            fontlist = new FontListView();
            preview = new PreviewPage();
            set_sidebar_widget(sidebar);
            set_list_widget(fontlist);
            set_content_widget(preview);
            network_monitor = NetworkMonitor.get_default();
            network_monitor.network_changed.connect(on_network_changed);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("available-families", fontlist, "available-families", flags);
            bind_property("waterfall-settings", preview, "waterfall-settings", flags);
            sidebar.bind_property("filter", fontlist, "filter", flags);
            fontlist.bind_property("selected-item", preview, "selected-item", flags);
            sidebar.sort_changed.connect(on_sort_changed);
            preview.restore_state(settings);
            on_network_changed();
            initialized = true;
            return GLib.Source.REMOVE;
        }

        public override void on_map () {
            base.on_map();
            if (initialized)
                return;
            placeholder.set_visible(true);
            Idle.add(initialize_pane);
            return;
        }

        void focus_search_entry (Gtk.Widget widget, string? action, Variant? parameter) {
            fontlist.focus_search_entry();
            return;
        }

        public void select_first_font () {
            fontlist.select_item(0);
            return;
        }

        void on_network_changed () {
            update_cache.begin((obj, res) => {
                update_cache.end(res);
                Idle.add(() => {
                    update_placeholder();
                    return GLib.Source.REMOVE;
                });
            });
            return;
        }

        void on_sort_changed (string order) {
            string filename = @"gfc-$order.json";
            string cache_dir = get_package_cache_directory();
            string cache = Path.build_filename(cache_dir, filename);
            var parser = new Json.Parser();
            try {
                parser.load_from_file(cache);
                Json.Object jobject = parser.get_root().get_object();
                Json.Array items = jobject.get_array_member("items");
                available_families = items;
            } catch (Error e) {
                error = null;
                error = e.copy();
            }
            update_placeholder();
            ((FontListView) get_list_widget()).queue_refilter();
            return;
        }

        bool network_available () {
            if (settings != null && settings.get_boolean("restrict-network-access"))
                return false;
            bool available = (network_monitor.connectivity == NetworkConnectivity.FULL);
            if (!available && network_monitor.connectivity != NetworkConnectivity.LOCAL) {
                try {
                    NetworkAddress google = new NetworkAddress("www.google.com", 80);
                    available = network_monitor.can_reach(google);
                } catch (Error e) {
                    debug("NetworkConnectivity check failed : %s", e.message);
                }
            }
            return available;
        }

        void set_placeholder_message (string? title,
                                      string? subtitle,
                                      string? message,
                                      string? icon_name) {
            placeholder.set("title", title, "subtitle", subtitle,
                            "message", message, "icon-name", icon_name, null);
            return;
        }

        void update_placeholder () {
            placeholder.visible = true;
            if (settings != null && settings.get_boolean("restrict-network-access")) {
                set_placeholder_message(_("Network Access Disabled"),
                                        _("Contact your system administrator to request access."),
                                        null, "network-offline-symbolic");
            } else if (!network_available()) {
                set_placeholder_message(_("Network Offline"),
                                        // Translators : Avoid translating "Google Fonts" in this message, if possible
                                        _("An active internet connection is required to access the Google Fonts catalog"),
                                        null, "network-offline-symbolic");
            } else if (error == null && status_code == Soup.Status.OK) {
                set_placeholder_message(null, null, null, null);
                placeholder.visible = false;
            } else if (error != null) {
                set_placeholder_message(error.domain.to_string(),
                                        "%i : %s".printf(error.code, error.message),
                                        null, "dialog-error-symbolic");
            } else if (status_code >= Soup.Status.BAD_REQUEST && status_code < Soup.Status.INTERNAL_SERVER_ERROR) {
                set_placeholder_message(_("Client Error"), reason_phrase,
                                        _("Try restarting the application. If the issue persists, please file a bug."),
                                          "dialog-error-symbolic");
            } else if (status_code >= Soup.Status.INTERNAL_SERVER_ERROR) {
                set_placeholder_message(_("Server Error"), reason_phrase, null, "network-error-symbolic");
            }
            return;
        }

        bool have_valid_cache (string filename) {
            string cache_dir = get_package_cache_directory();
            string cache = Path.build_filename(cache_dir, filename);
            File cache_file = File.new_for_path(cache);
            if (cache_file.query_exists()) {
                try {
                    FileInfo file_info = cache_file.query_info(FileAttribute.TIME_CREATED,
                                                               FileQueryInfoFlags.NONE);
                    uint64 ctime = file_info.get_attribute_uint64(FileAttribute.TIME_CREATED);
                    DateTime now = new DateTime.now_local();
                    DateTime created = new DateTime.from_unix_local((int64) ctime);
                    return (now.difference(created) <= (TimeSpan.DAY * 2));
                } catch (Error e) {
                    warning("Failed to query file information : %s : %s", cache, e.message);
                    return false;
                }
            }
            return false;
        }

        async bool update_cache () {
            if (!network_available())
                return false;
            error = null;
            status_code = Soup.Status.OK;
            var session = new Soup.Session();
            var GFC_API_KEY = (string) Base64.decode(API_KEY);
            foreach (var entry in SORT_OPTIONS) {
                string filename = @"gfc-$entry.json";
                if (have_valid_cache(filename))
                    continue;
                var message = new Soup.Message(GET, GOOGLE_FONTS_API.printf(GFC_API_KEY, entry));
                try {
                    Bytes? bytes = session.send_and_read(message, null);
                    assert(bytes != null);
                    string filepath = Path.build_filename(get_package_cache_directory(), filename);
                    File cache_file = File.new_for_path(filepath);
                    if (cache_file.query_exists())
                        cache_file.delete();
                    FileOutputStream stream = cache_file.create(FileCreateFlags.PRIVATE);
                    stream.write_bytes_async.begin(bytes, Priority.DEFAULT, null, (obj, res) => {
                        try {
                            stream.write_bytes_async.end(res);
                            stream.close();
                        } catch (Error e) {
                            warning("Failed to write data for : %s :: %i : %s", filename, e.code, e.message);
                            error = e.copy();
                        }
                    });
                } catch (Error e) {
                    warning("Failed to write data for : %s :: %i : %s", filename, e.code, e.message);
                    status_code = message.status_code;
                    reason_phrase = message.reason_phrase;
                    return false;
                }
                if (error != null)
                    return false;
                status_code = message.status_code;
                reason_phrase = message.reason_phrase;
                Idle.add(update_cache.callback);
                yield;
            }
            on_sort_changed("alpha");
            return true;
        }

    }

}

#endif /* HAVE_WEBKIT */

