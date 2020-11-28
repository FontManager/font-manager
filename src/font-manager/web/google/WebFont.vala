/* WebFont.vala
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

    const string FONT_FACE = "@font-face { font-family: '%s'; font-style: %s; font-weight: %i; src: local('%s'), local('%s'), url(%s) format('truetype'); }";

    public enum FileStatus {
        NOT_INSTALLED,
        INSTALLED,
        REQUIRES_UPDATE;
    }

    public async bool download_font_files (Font [] fonts) {
        var session = new Soup.Session();
        bool retval = true;
        foreach (var font in fonts) {
            string font_dir = Path.build_filename(get_font_directory(), font.family);
            if (DirUtils.create_with_parents(font_dir, 0755) != 0) {
                warning("Failed to create directory : %s", font_dir);
                return false;
            }
            string filename = font.get_filename();
            string filepath = Path.build_filename(font_dir, filename);
            var message = new Soup.Message(GET, font.url);
            session.queue_message(message, (s, m) => {
                if (message.status_code != Soup.Status.OK) {
                    warning("Failed to download data for : %s :: %i", filename, (int) message.status_code);
                    retval = false;
                    return;
                }
                try {
                    Bytes bytes = message.response_body.flatten().get_as_bytes();
                    File font_file = File.new_for_path(filepath);
                    if (font_file.query_exists())
                        font_file.delete();
                    FileOutputStream stream = font_file.create(FileCreateFlags.PRIVATE);
                    stream.write_bytes_async.begin(bytes, Priority.DEFAULT, null, (obj, res) => {
                        try {
                            stream.write_bytes_async.end(res);
                            stream.close();
                        } catch (Error e) {
                            warning("Failed to write data for : %s :: %i : %s", filename, e.code, e.message);
                            retval = false;
                            return;
                        }
                    });
                } catch (Error e) {
                    warning("Failed to write data for : %s :: %i : %s", filename, e.code, e.message);
                    retval = false;
                    return;
                }

            });
            Idle.add(download_font_files.callback);
            yield;
        }
        return retval;
    }

    public class Family : Object {

        public string family { get; set; }
        public string category { get; set; }
        public GenericArray <Font> variants { get; set; }
        public StringSet subsets { get; set; }
        public int count { get; private set; default = 0; }
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
                count++;
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
                var status = variants[i].get_installation_status();
                if (status != FileStatus.NOT_INSTALLED)
                    return status;
            }
            return FileStatus.NOT_INSTALLED;
        }

    }

    public class Font : Object {

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

        public FileStatus get_installation_status () {
            string dir = get_font_directory();
            string filepath = Path.build_filename(dir, family, get_filename());
            File font = File.new_for_path(filepath);
            if (font.query_exists())
                return FileStatus.INSTALLED;
            File font_dir = File.new_for_path(Path.build_filename(dir, family));
            if (font_dir.query_exists()) {
                string ext = get_file_extension(url);
                string style = to_description().replace(" ", "_");
                string family = family.replace(" ", "_");
                string filename =  "%s_%s.%i.%s".printf(family, style, version - 1, ext);
                File outdated = font_dir.get_child(filename);
                if (outdated.query_exists())
                    return FileStatus.REQUIRES_UPDATE;
            }
            return FileStatus.NOT_INSTALLED;
        }

    }

}

#endif /* HAVE_WEBKIT */
