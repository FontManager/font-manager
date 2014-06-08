/* Migration.vala
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

    public bool update_declined () {
        if (Migration.required()) {
            if (Migration.approved(null)) {
                Migration.run();
            } else {
                return true;
            }
        }
        return false;
    }

    [Compact]
    public class Migration {

        static string old_prefs_file;
        static string old_cache_file;
        static string old_collections_file;
        static Collections collections;

        public static bool required () {
            old_prefs_file = Path.build_filename(Environment.get_user_config_dir(), NAME, "preferences.ini");
            File old_prefs = File.new_for_path(old_prefs_file);
            old_cache_file = Path.build_filename(Environment.get_user_cache_dir(), NAME, "font-manager.cache");
            File old_cache = File.new_for_path(old_cache_file);
            old_collections_file = Path.build_filename(Environment.get_user_data_dir(), NAME, "Collections.xml");
            File old_collections = File.new_for_path(old_collections_file);
            return (old_prefs.query_exists() || old_cache.query_exists() || old_collections.query_exists());
        }

        public static bool approved (Gtk.Window? parent) {
            int response = 0;
            var ni = new Gtk.Dialog.with_buttons(_("Update Required"),
                                                    parent,
                                                    (Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT),
                                                    "Cancel",
                                                    0,
                                                    "Continue",
                                                    1);
            var box = ni.get_content_area();
            box.set_orientation(Gtk.Orientation.VERTICAL);
            var scrolled = new Gtk.ScrolledWindow(null, null);
            var textview = new StaticTextView(null);
            textview.hexpand = textview.vexpand = true;
            textview.view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            add_separator(box, Gtk.Orientation.HORIZONTAL);
            scrolled.add(textview);
            box.pack_start(scrolled, true, true, 0);
            add_separator(box, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            textview.buffer.set_text(update_notice);
            box.show_all();
            ni.response.connect((i) => { response = i; ni.destroy(); });
            ni.close.connect(() => { ni.destroy(); });
            ni.delete_event.connect(() => { ni.destroy(); return false; });
            ni.set_transient_for(parent);
            ni.set_size_request(475, 350);
            ni.run();
            return (response != 0);
        }

        public static void run () {
            /* XXX : progress? */
            import_fonts();
            import_collections();
            purge_cache();
            purge_config();
            purge_fontconfig_config();
            purge_data();
            purge_obsolete();
            collections.cache();
           return;
        }

        static bool purge_cache () {
            File cache_dir = File.new_for_path(Path.build_filename(Environment.get_user_cache_dir(), NAME));
            return remove_directory(cache_dir);
        }

        static bool purge_config () {
            File config_dir = File.new_for_path(Path.build_filename(Environment.get_user_config_dir(), NAME));
            return remove_directory(config_dir);
        }

        static bool purge_fontconfig_config () {
            File fontconfig_dir = File.new_for_path(Path.build_filename(Environment.get_user_config_dir(), "fontconfig"));
            return remove_directory(fontconfig_dir);
        }

        static bool purge_data () {
            File data_dir = File.new_for_path(Path.build_filename(Environment.get_user_data_dir(), NAME));
            return remove_directory(data_dir);
        }

        static bool purge_obsolete () {
            File fontsconf = File.new_for_path(Path.build_filename(Environment.get_home_dir(), ".fonts.conf"));
            if (fontsconf.query_exists())
                try {
                    fontsconf.delete();
                    return true;
                } catch (Error e) {
                    warning("Failed to remove obsolete file : %s", e.message);
                }
            return false;
        }

        static void import_fonts () {
            File? [] font_dirs = null;
            string old_font_dir = Path.build_filename(Environment.get_home_dir(), ".fonts");
            File ofd = File.new_for_path(old_font_dir);
            if (ofd.query_exists())
                font_dirs += ofd;
            string old_library = Path.build_filename(Environment.get_user_data_dir(), NAME, "Library");
            File ol = File.new_for_path(old_library);
            if (ol.query_exists())
                font_dirs += ol;
            Library.Install.from_file_array(font_dirs);
            return;
        }

        static bool import_collections () {
            {
                File file = File.new_for_path(old_collections_file);
                if (!file.query_exists())
                    return false;
            }

            collections = load_collections();

            Xml.Parser.init();

            Xml.Doc * doc = Xml.Parser.parse_file(old_collections_file);
            if (doc == null) {
                /* File not found */
                Xml.Parser.cleanup();
                return false;
            }

            Xml.XPath.Context ctx = new Xml.XPath.Context(doc);
            Xml.XPath.Object * res = ctx.eval_expression("//fontcollection");

            for (int i = 0; i < res->nodesetval->length (); i++) {
                Xml.Node* node = res->nodesetval->item(i);
                string name = node->get_prop("name");
                Collection collection = new Collection(name);
                collections.entries[name] = collection;
                collection.comment = node->get_prop("comment");
                for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                    // Spaces between tags are also nodes, discard them
                    if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                        continue;
                    }
                    collection.families.add(iter->get_content().strip());
                }
            }

            delete res;
            delete doc;
            Xml.Parser.cleanup();
            return true;
        }

    }

}

const string update_notice = _("""
Font Manager has detected files from a previous installation. Some files from previous versions are incompatible with this release. Others have been deprecated or moved.

Font Manager will now attempt to migrate your fonts and collections. Files and settings which are no longer necessary or valid will be deleted. Any configuration files that could cause a conflict will also be deleted.

It is strongly recommended that you back up any important files before proceeding.
""");

