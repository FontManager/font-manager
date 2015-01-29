/* JsonWriter.vala
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

class JsonWriter : Json.Generator {

    public bool compress { get; set; default = false; }

    public JsonWriter (Json.Node root) {
        Object( indent: 4, pretty: true, root: root);
    }

    public new bool to_file (string filepath, bool use_backup = false) {
        try {
            File file = File.new_for_path(filepath);
            FileOutputStream stream = file.replace(
                                         null,
                                         use_backup,
                                         FileCreateFlags.REPLACE_DESTINATION,
                                         null);
            File parent = file.get_parent();
            if (!parent.query_exists())
                parent.make_directory_with_parents();
            if (compress) {
                var compressor = new ZlibCompressor(ZlibCompressorFormat.ZLIB);
                var compressed_stream = new ConverterOutputStream (stream, compressor);
                to_stream(compressed_stream, null);
            } else
                to_stream(stream, null);
            return true;
        } catch (Error e) {
            warning(e.message);
            return false;
        }
    }

}

private bool write_json_file (Json.Node root,
                        string filepath,
                        bool compress = false,
                        bool backup = false) {
    var writer = new JsonWriter(root);
    writer.compress = compress;
    return writer.to_file(filepath, backup);
}

private Json.Node? load_json_file (string filepath, bool compressed = false) {
    try {
        var parser = new Json.Parser();
        if (compressed) {
            var stream = File.new_for_path(filepath).read();
            var decompressor = new ZlibDecompressor(ZlibCompressorFormat.ZLIB);
            var uncompressed_stream = new ConverterInputStream(stream, decompressor);
            parser.load_from_stream(uncompressed_stream);
        } else
            parser.load_from_file(filepath);
        return parser.get_root();
    } catch (Error e) {
        warning("\nFailed to load cache file : %s\n%s : skipping...", filepath, e.message);
    }
    return null;
}
