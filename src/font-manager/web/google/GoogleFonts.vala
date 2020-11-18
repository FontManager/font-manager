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

namespace FontManager.GoogleFonts {

    const string API_KEY = "QUl6YVN5QTlpUmZqMFlYc184RGhJR1Q1YzNGRDBWNmtSQWV5cFA4";
    const string GET = "https://www.googleapis.com/webfonts/v1/webfonts?sort=ALPHA&key=%s";

    public WebKit.WebContext get_webkit_context () {
        var ctx = new WebKit.WebContext.ephemeral();
        ctx.set_cache_model(WebKit.CacheModel.DOCUMENT_BROWSER);
        ctx.prefetch_dns("https://www.googleapis.com/");
        ctx.prefetch_dns("http://fonts.gstatic.com/");
        return ctx;
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-fonts-catalog.ui")]
    public class Catalog : Gtk.Paned {

        [GtkChild] public FontListPane font_list_pane { get; private set; }
        [GtkChild] public Filters filters { get; private set; }
        [GtkChild] public Gtk.Paned content_pane { get; private set; }

        [GtkChild] PreviewPane preview_pane;

        bool _connected_ = false;
        bool _visible_ = false;
        NetworkMonitor network_monitor;

        public override void constructed () {
            font_list_pane.filter = filters;
            network_monitor = NetworkMonitor.get_default();
            network_monitor.notify["connectivity"].connect(() => {
                _connected_ = network_monitor.get_connectivity() != NetworkConnectivity.LOCAL;
                update_if_needed();
            });
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
                Font? variant = null;
                if (list.model.iter_has_child(iter))
                    variant = ((Family) obj).get_default_variant();
                else
                    variant = (Font) obj;
                if (variant == null)
                    return;
                preview_pane.font = variant;
            });
            _connected_ = network_monitor.get_connectivity() != NetworkConnectivity.LOCAL;
            base.constructed();
            return;
        }

        void populate_font_model (Soup.Session session, Soup.Message message) {
            if (message.status_code == Soup.Status.OK) {
                var data = (string) message.response_body.flatten().data;
                try {
                    var parser = new Json.Parser();
                    parser.load_from_data(data);
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
                    font_list_pane.place_holder.set("title", _("Error procesing retrieved data"),
                                                    "subtitle", e.message,
                                                    "icon-name", "dialog-error-symbolic",
                                                    null);
                    font_list_pane.place_holder.show();
                }
            } else {
                if (message.status_code > 0 && message.status_code < 100) {
                    font_list_pane.place_holder.set("title", _("Network Error"),
                                                    "subtitle", message.reason_phrase,
                                                    "message", _("Please check your network settings"),
                                                    "icon-name", "network-error-symbolic",
                                                    null);
                    font_list_pane.place_holder.show();
                }
                warning("%i : %s", (int) message.status_code, message.reason_phrase);
            }
            return;
        }

        void update_if_needed () {
            if (!_connected_) {
                font_list_pane.place_holder.set("title", _("Network Offline"),
                                                "subtitle", _("An active internet connection is required to access the Google Fonts catalog"),
                                                "icon-name", "network-offline-symbolic",
                                                null);
                font_list_pane.place_holder.show();
                preview_pane.font = null;
            }
            if (!_connected_ || !_visible_)
                return;
            if (font_list_pane.model == null || font_list_pane.model.iter_n_children(null) == 0) {
                var session = new Soup.Session();
                var message = new Soup.Message("GET", GET.printf((string) Base64.decode(API_KEY)));
                session.queue_message(message, populate_font_model);
            } else {
                font_list_pane.place_holder.hide();
            }
            return;
        }

    }

}

