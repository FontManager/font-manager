/* Utils.vala
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

namespace FontManager {

    public enum SortType {
        AGE,
        NAME,
        SIZE,
        NONE
    }

    internal const string SELECT_NON_LATIN_FONTS = """
    SELECT DISTINCT description, Orthography.sample FROM Fonts
    JOIN Orthography USING (filepath, findex)
    WHERE Orthography.sample IS NOT NULL;
    """;

    public HashTable get_non_latin_samples () {
        var result = new HashTable <string, string> (str_hash, str_equal);
        try {
            Database db = Database.get_default(DatabaseType.BASE);
            db.execute_query(SELECT_NON_LATIN_FONTS);
            foreach (unowned Sqlite.Statement row in db)
                result.insert(row.column_text(0), row.column_text(1));
        } catch (DatabaseError e) {
            message(e.message);
        }
        return result;
    }

    public void update_item_preview_text (Json.Array available_fonts) {
        HashTable <string, string> samples = get_non_latin_samples();
        available_fonts.foreach_element((array, index, node) => {
            Json.Object item = node.get_object();
            string description = item.get_string_member("description");
            if (samples.contains(description))
                item.set_string_member("preview-text", samples.lookup(description));
            Json.Array variants = item.get_array_member("variations");
            variants.foreach_element((a, i, n) => {
                Json.Object v = n.get_object();
                description = v.get_string_member("description");
                if (samples.contains(description))
                    v.set_string_member("preview-text", samples.lookup(description));
            });
        });
        return;
    }

    public Gtk.Image inline_help_widget (string message) {
        var help = new Gtk.Image.from_icon_name("dialog-question-symbolic")
        {
            pixel_size = 24,
            opacity = 0.333,
            hexpand = true,
            halign = Gtk.Align.END,
            margin_start = DEFAULT_MARGIN,
            margin_end = DEFAULT_MARGIN,
            tooltip_text = message
        };
        return help;
    }

    public Gtk.Window? get_parent_window (Gtk.Widget widget) {
        Gtk.Widget? ancestor = widget.get_ancestor(typeof(Gtk.Window));
        return ancestor != null ? (Gtk.Window) ancestor : null;
    }

    public void set_control_sensitivity(Gtk.Widget? widget, bool sensitive) {
        if (widget == null || !(widget is Gtk.Widget))
            return;
        widget.sensitive = sensitive;
        widget.opacity = sensitive ? 0.9 : 0.45;
        widget.has_tooltip = sensitive;
        return;
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-list-item-row.ui")]
    public class ListItemRow : Gtk.Box {

        public Object? item { get; set; default = null; }

        [GtkChild] public unowned Gtk.Label item_label { get; }
        [GtkChild] public unowned Gtk.Label item_count { get; }
        [GtkChild] public unowned Gtk.Image item_icon { get; }
        [GtkChild] public unowned Gtk.CheckButton item_state { get; }
        [GtkChild] public unowned Gtk.Inscription item_preview { get; }
        // [GtkChild] public unowned Gtk.EditableLabel edit_label { get; }
        [GtkChild] public unowned Gtk.Box drag_area { get; }
        [GtkChild] public unowned Gtk.Image drag_handle { get; }

        construct {
            notify["item"].connect((pspec) => { on_item_set(); });
        }

        protected virtual void on_item_set () {}
        public virtual void reset () {}

    }

    public class TreeListItemRow : ListItemRow {

        public Gtk.TreeExpander? expander { get; set; default = null; }
        public Gtk.SelectionModel? selection { get; set; default = null; }

        protected virtual void show_context_menu (Gdk.Event event ,double x, double y) {}

        construct {
            var click = new Gtk.GestureClick();
            add_controller(click);
            click.pressed.connect(on_click);
        }

        void on_click (Gtk.GestureClick click, int n_press, double x, double y) {
            if (expander == null || selection == null)
                return;
            Gtk.TreeListRow? row = expander.get_list_row();
            if (row == null)
                return;
            uint position = row.get_position();
            if (selection.is_selected(position)) {
                Gdk.Event event = click.get_current_event();
                if (event == null)
                    return;
                if (event.triggers_context_menu()) {
                    show_context_menu(event, x, y);
                    return;
                }
                bool expanded = row.expanded;
                Idle.add(() => {
                    if (row.expandable)
                        row.expanded = !expanded;
                    return GLib.Source.REMOVE;
                });
            }
            return;
        }

    }

}

