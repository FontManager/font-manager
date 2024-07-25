/* WebFont.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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

    const string FONT_FACE = """
    @font-face {
        font-family: '%s';
        font-style: %s;
        font-weight: %i;
        src: local('%s'), local('%s'), url(%s) format('truetype');
    }
    """;

    public enum FileStatus {
        NOT_INSTALLED,
        INSTALLED,
        REQUIRES_UPDATE;
    }

    public class Family : Object {

        public signal void changed ();

        public uint position { get; set; default = 0; }

        public bool inconsistent {
            get {
                bool possibly_sensitive = active;
                if (!possibly_sensitive)
                    return false;
                int installed = 0;
                foreach (var entry in variants)
                    if (entry.active)
                        installed++;
                return (possibly_sensitive && installed < count);
            }
        }

        public bool active {
            get {
                return (get_installation_status() != FileStatus.NOT_INSTALLED);
            }
            set {
                foreach (var entry in variants)
                    Idle.add(() => {
                        entry.active = value;
                        return GLib.Source.REMOVE;
                    });
                notify_property("active");
            }
        }

        public string family { get; set; }
        public string category { get; set; }
        public GenericArray <Font> variants { get; set; }
        public StringSet subsets { get; set; }
        public int count { get { return variants.length; } }
        public int version { get; private set; default = 1; }

        public Family (Json.Object source) {
            family = source.get_string_member("family");
            category = source.get_string_member("category");
            variants = new GenericArray <Font> ();
            subsets = new StringSet();
            var filelist = source.get_object_member("files");
            source.get_array_member("variants").foreach_element((array, index, node) => {
                var entry = node.get_string();
                var variant = new Font(family, entry, filelist.get_string_member(entry), subsets);
                variants.insert((int) index, variant);
                variant.notify["active"].connect(() => {
                    Idle.add_full(GLib.Priority.LOW, () => {
                        notify_property("active");
                        notify_property("inconsistent");
                        return GLib.Source.REMOVE;
                    });
                });
            });
            source.get_array_member("subsets").foreach_element((array, index, node) => {
                subsets.add(node.get_string());
            });
            string [] _version = variants[0].url.split("/");
            version = int.parse(_version[_version.length - 2].replace("v", ""));
        }

        public Font get_default_variant () {
            Font result = variants[0];
            variants.foreach((variant) => {
                if (variant.italic)
                    return;
                if ((Weight) variant.weight == Weight.REGULAR)
                    result = variant;
            });
            return result;
        }

        public string to_stylesheet () {
            var builder = new StringBuilder();
            variants.foreach((variant) => { builder.append(variant.to_font_face_rule()); });
            return builder.str;
        }

        public FileStatus get_installation_status () {
            for (int i = 0; i < variants.length; i++) {
                if (variants[i].active)
                    return FileStatus.INSTALLED;
            }
            return FileStatus.NOT_INSTALLED;
        }

    }

    public enum Weight {

        THIN = 100,
        EXTRA_LIGHT = 200,
        LIGHT = 300,
        REGULAR = 400,
        MEDIUM = 500,
        SEMI_BOLD = 600,
        BOLD = 700,
        EXTRA_BOLD = 800,
        BLACK = 900;

        public string to_string () {
            switch (this) {
                case THIN:
                    return "Thin";
                case EXTRA_LIGHT:
                    return "ExtraLight";
                case LIGHT:
                    return "Light";
                case REGULAR:
                    return "Regular";
                case MEDIUM:
                    return "Medium";
                case SEMI_BOLD:
                    return "SemiBold";
                case BOLD:
                    return "Bold";
                case EXTRA_BOLD:
                    return "ExtraBold";
                case BLACK:
                    return "Black";
                default:
                    assert_not_reached();
            }
        }

        public string to_translatable_string () {
            switch (this) {
                case THIN:
                    return _("Thin");
                case EXTRA_LIGHT:
                    return _("ExtraLight");
                case LIGHT:
                    return _("Light");
                case REGULAR:
                    return _("Regular");
                case MEDIUM:
                    return _("Medium");
                case SEMI_BOLD:
                    return _("SemiBold");
                case BOLD:
                    return _("Bold");
                case EXTRA_BOLD:
                    return _("ExtraBold");
                case BLACK:
                    return _("Black");
                default:
                    assert_not_reached();
            }
        }

    }

    public class Font : Object {

        public signal void changed ();

        public uint position { get; set; default = 0; }
        public bool inconsistent { get { return false; } }

        public bool active {
            get {
                return (get_installation_status() != FileStatus.NOT_INSTALLED);
            }
            set {
                set_installation_status(value);
            }
        }

        public string family { get; set; }
        public string url { get; set; }
        public int weight { get; set; }
        public bool italic { get; set; }
        public string style { get { return italic ? "italic" : "normal"; } }
        public int version { get; private set; default = 1; }
        public StringSet subsets { get; set; }

        public Font (string family, string variant, string url, StringSet subsets) {
            Object(family: family, url: url, subsets: subsets);
            italic = variant.contains("italic");
            if (variant == "regular" || variant == "italic")
                weight = (int) Weight.REGULAR;
            else
                weight = int.parse(italic ? variant.replace("italic", "") : variant);
            string [] _version = url.split("/");
            version = int.parse(_version[_version.length - 2].replace("v", ""));
            if (get_installation_status() == FileStatus.REQUIRES_UPDATE)
                set_installation_status(true);
        }

        public string to_display_name () {
            string ital = italic ? _("Italic") : "";
            if (italic && weight == Weight.REGULAR)
                return ital;
            return "%s %s".printf(((Weight) weight).to_translatable_string(), ital).strip();
        }

        public string to_description () {
            string ital = italic ? "Italic" : "";
            if (italic && (Weight) weight == Weight.REGULAR)
                return ital;
            return "%s %s".printf(((Weight) weight).to_string(), ital).strip();
        }

        public string to_font_face_rule () {
            string description = to_description();
            string local = "%s %s".printf(family, description);
            string _local = "%s-%s".printf(family.replace(" ", ""), description.replace(" ", ""));
            string style = italic ? "italic" : "normal";
            return FONT_FACE.printf(family, style, weight, local, _local, url);
        }

        public string get_filename () {
            string ext = get_file_extension(url);
            string style = to_description().replace(" ", "_");
            string family = family.replace(" ", "_");
            return "%s_%s.%i.%s".printf(family, style, version, ext);
        }

        File get_outdated_file () {
            File font_dir = File.new_for_path(Path.build_filename(get_font_directory(), family));
            string ext = get_file_extension(url);
            string style = to_description().replace(" ", "_");
            string family = family.replace(" ", "_");
            string filename =  "%s_%s.%i.%s".printf(family, style, version - 1, ext);
            File outdated = font_dir.get_child(filename);
            return outdated;
        }

        FileStatus get_installation_status () {
            string dir = get_font_directory();
            string filepath = Path.build_filename(dir, family, get_filename());
            File font = File.new_for_path(filepath);
            if (font.query_exists())
                return FileStatus.INSTALLED;
            File font_dir = File.new_for_path(Path.build_filename(dir, family));
            if (font_dir.query_exists()) {
                File outdated = get_outdated_file();
                if (outdated.query_exists())
                    return FileStatus.REQUIRES_UPDATE;
            }
            return FileStatus.NOT_INSTALLED;
        }

        void remove_outdated_files () {
            File outdated_file = get_outdated_file();
            if (!outdated_file.query_exists())
                return;
            try {
                outdated_file.delete();
                string font_dir = get_font_directory();
                string target_dir = Path.build_filename(font_dir, family);
                File outdated_dir = File.new_for_path(target_dir);
                remove_directory_tree_if_empty(outdated_dir);
            } catch (Error e) {
                string path = outdated_file.get_path();
                warning("Failed to remove outdated font file : %s", path);
            }
            return;
        }

        void on_download_complete (Object? source, GLib.Task task) {
            if (task.propagate_boolean())
                remove_outdated_files();
            notify_property("active");
            return;
        }

        static void download_file (Task task, Object source, void* data, Cancellable? cancellable = null) {
            assert(source is Font);
            var font = (Font) source;
            var session = new Soup.Session();
            string font_dir = Path.build_filename(get_font_directory(), font.family);
            if (DirUtils.create_with_parents(font_dir, 0755) != 0) {
                warning("Failed to create directory : %s", font_dir);
                task.return_boolean(false);
                return;
            }
            string filename = font.get_filename();
            string filepath = Path.build_filename(font_dir, filename);
            var message = new Soup.Message(GET, font.url);
            try {
                Bytes? bytes = session.send_and_read(message, null);
                if (bytes == null)
                    task.return_boolean(false);
                return_if_fail(bytes != null);
                File font_file = File.new_for_path(filepath);
                // File.create errors out if file already exists regardless of flags
                if (font_file.query_exists())
                    font_file.delete();
                FileOutputStream stream = font_file.create(FileCreateFlags.PRIVATE);
                try {
                    stream.write_bytes(bytes);
                    stream.close();
                } catch (Error e) {
                    task.return_boolean(false);
                    warning("Failed to write data to file : %s : %s", filepath, e.message);
                }
            } catch (Error e) {
                task.return_boolean(false);
                warning("Failed to read data for : %s :: %i :: %s",
                        filename,
                        (int) message.status_code,
                        e.message);
            }
            task.return_boolean(true);
            return;
        }

        void set_installation_status (bool install) {
            if (install) {
                GLib.Task task = new GLib.Task(this, null, on_download_complete);
                task.run_in_thread(download_file);
            } else if (active) {
                string font_dir = get_font_directory();
                string file_name = get_filename();
                string target_dir = Path.build_filename(font_dir, family);
                string target_file = Path.build_filename(target_dir, file_name);
                File dir = File.new_for_path(target_dir);
                File file = File.new_for_path(target_file);
                try {
                    if (file.delete())
                        remove_directory_tree_if_empty(dir);
                } catch (Error e) {
                    if (e.code != FileError.NOENT)
                        warning(e.message);
                }
            }
            return;
        }

    }

}

#endif /* HAVE_WEBKIT */

