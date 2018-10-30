
namespace FontManager {

    public class Database : GLib.Object {
        public Sqlite.Database db;
        public Sqlite.Statement stmt;
    }

    public class DatabaseIterator : GLib.Object {
        public unowned Sqlite.Statement get ();
    }

    public class CodepointList : GLib.Object, Unicode.CodepointList {
    }

    public class AliasElement : GLib.Object {
        public unowned StringHashset get (string priority);
    }

    public class Selections : StringHashset {
        [NoWrapper]
        public virtual unowned Xml.Node? get_selections (Xml.Doc *doc);
    }

}
