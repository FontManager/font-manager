
namespace FontManager {

    public class Database : GLib.Object {
        public Sqlite.Database db;
        public Sqlite.Statement stmt;
    }

    public class DatabaseIterator : GLib.Object {
        public unowned Sqlite.Statement get ();
    }

    public class AliasElement : GLib.Object {
        public unowned StringSet get (string priority);
    }

    public class Selections : StringSet {
        [NoWrapper]
        public virtual unowned Xml.Node? get_selections (Xml.Doc *doc);
    }

    public enum fsType {
        [CCode (cname = "font_manager_fsType_to_string")]
        public unowned string? to_string ();
    }

}

