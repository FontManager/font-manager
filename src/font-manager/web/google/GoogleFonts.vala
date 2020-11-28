/* GoogleFonts.vala
 *
 * Copyright (C) 2020 Jerry Casiano
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
    const string WEBFONTS = "https://www.googleapis.com/webfonts/v1/webfonts?key=%s&sort=%s";

    public string get_font_directory () {
        return Path.build_filename(get_user_font_directory(), "Google Fonts");
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-fonts-catalog.ui")]
    public class Catalog : Gtk.Paned {

        [GtkChild] public FontListPane font_list_pane { get; private set; }
        [GtkChild] public Filters filters { get; private set; }
        [GtkChild] public Gtk.Paned content_pane { get; private set; }

        [GtkChild] Gtk.Paned filter_pane;
        [GtkChild] PreviewPane preview_pane;

        bool _connected_ = false;
        bool _visible_ = false;
        uint http_status = Soup.Status.OK;
        string status_message = "";
        NetworkMonitor network_monitor;

        public override void constructed () {
            font_list_pane.filter = filters;
            network_monitor = NetworkMonitor.get_default();
            network_monitor.notify["connectivity"].connect(() => {
                _connected_ = network_monitor.get_connectivity() != NetworkConnectivity.LOCAL;
                update_if_needed();
            });
            filters.sort_order.changed.connect(() => { populate_font_model(); });
            map.connect(() => { _visible_ = true; update_if_needed(); });
            unmap.connect(() => { _visible_ = false; });
            var list = font_list_pane.fontlist;
            list.get_selection().changed.connect(() => {
                List <Gtk.TreePath> selected = list.get_selection().get_selected_rows(null);
                if (selected == null || selected.length() < 1)
                    return;
                Gtk.TreePath path = selected.nth_data(0);
                Gtk.TreeIter iter;
                list.model.get_iter(out iter, path);
                Value val;
                list.model.get_value(iter, 0, out val);
                var obj = val.get_object();
                Family? family = null;
                Font? variant = null;
                if (list.model.iter_has_child(iter)) {
                    family = (Family) obj;
                    variant = family.get_default_variant();
                } else {
                    variant = (Font) obj;
                }
                return_if_fail(variant != null);
                preview_pane.family = family;
                preview_pane.font = variant;
            });
            _connected_ = network_monitor.get_connectivity() != NetworkConnectivity.LOCAL;
            if (_connected_)
                Idle.add(() => { check_font_list_cache(); return GLib.Source.REMOVE; });
            base.constructed();
            return;
        }

        void hide_http_status () {
            font_list_pane.place_holder.hide();
            preview_pane.show();
            filter_pane.show();
            preview_pane.update_preview();
            return;
        }

        void show_http_status (string? title, string? subtitle, string? message, string? icon_name) {
            font_list_pane.place_holder.set("title", title, "subtitle", subtitle,
                                            "message", message, "icon-name", icon_name, null);
            font_list_pane.place_holder.show();
            filter_pane.hide();
            preview_pane.hide();
            return;
        }

        void populate_font_model () {
            if (http_status == Soup.Status.OK) {
                try {
                    string filename = "gfc-%s.json".printf(filters.sort_order.active_id);
                    string cache = Path.build_filename(get_package_cache_directory(), filename);
                    var parser = new Json.Parser();
                    parser.load_from_file(cache);
                    Json.Array items = parser.get_root().get_object().get_array_member("items");
                    var model = new Gtk.TreeStore(3, typeof(Object), typeof(string), typeof(int));
                    items.foreach_element((array, index, node) => {
                        var font = new Family(node.get_object());
                        Gtk.TreeIter parent;
                        model.insert_with_values(out parent, null, (int) index, 0, font, 1, font.family, 2, font.count, -1);
                        font.variants.foreach((variant) => {
                            model.insert_with_values(null, parent, -1, 0, variant, 1, variant.to_display_name(), 2, 0, -1);
                        });
                    });
                    font_list_pane.model = model;
                    font_list_pane.select_first_row();
                    font_list_pane.place_holder.hide();
                } catch (Error e) {
                    show_http_status(_("Error procesing data"), e.message, null, "dialog-error-symbolic");
                }
            } else {
                if (http_status > 0 && http_status < 100) {
                    show_http_status(_("Network Error"), status_message,
                                     _("Please check your network settings"), "network-error-symbolic");
                } else if (http_status >= 400 && http_status < 500) {
                    show_http_status(_("Client Error"), status_message,
                                     _("Try restarting the application. If the issue persists, please file a bug."),
                                     "dialog-error-symbolic");
                } else if (http_status >= 500 && http_status < 600) {
                    show_http_status(_("Server Error"), status_message, null, "network-error-symbolic");
                }
                warning("%i : %s", (int) http_status, status_message);
            }
            return;
        }

        async void update_font_list_cache () {
            var session = new Soup.Session();
            var GFC_API_KEY = (string) Base64.decode(API_KEY);
            string [] order = { "alpha", "date", "popularity", "trending" };
            foreach (var entry in order) {
                var message = new Soup.Message(GET, WEBFONTS.printf(GFC_API_KEY, entry));
                session.queue_message(message, (s, m) => {
                    string filename = "gfc-%s.json".printf(entry);
                    string filepath = Path.build_filename(get_package_cache_directory(), filename);
                    if (message.status_code != Soup.Status.OK) {
                        http_status = message.status_code;
                        status_message = message.reason_phrase;
                        warning("Failed to download data for : %s :: %i", filename, (int) message.status_code);
                        return;
                    }
                    try {
                        Bytes bytes = message.response_body.flatten().get_as_bytes();
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
                                return;
                            }
                        });
                    } catch (Error e) {
                        warning("Failed to write data for : %s :: %i : %s", filename, e.code, e.message);
                        return;
                    }

                });
                Idle.add(update_font_list_cache.callback);
                yield;
            }
        }

        void check_font_list_cache () {
            string cache = Path.build_filename(get_package_cache_directory(), "gfc-alpha.json");
            File cache_file = File.new_for_path(cache);
            if (cache_file.query_exists()) {
                try {
                    FileInfo file_info = cache_file.query_info(FileAttribute.TIME_CREATED, FileQueryInfoFlags.NONE);
                    uint64 ctime = file_info.get_attribute_uint64(FileAttribute.TIME_CREATED);
                    DateTime now = new DateTime.now_local();
                    DateTime created = new DateTime.from_unix_local((int64) ctime);
                    if (now.difference(created) > TimeSpan.DAY)
                        update_font_list_cache.begin((obj, res) => { update_font_list_cache.end(res); });
                    return;
                } catch (Error e) {
                    warning("Failed to query file information : %s : %s",  cache, e.message);
                }
            }
            update_font_list_cache.begin((obj, res) => { update_font_list_cache.end(res); });
            return;
        }

        void update_if_needed () {
            if (!_connected_) {
                show_http_status(_("Network Offline"),
                                 _("An active internet connection is required to access the Google Fonts catalog"),
                                 null, "network-offline-symbolic");
            }
            if (!_connected_ || !_visible_)
                return;
            if (font_list_pane.model == null || font_list_pane.model.iter_n_children(null) == 0)
                populate_font_model();
            hide_http_status();
            return;
        }

    }

}

#endif /* HAVE_WEBKIT */
