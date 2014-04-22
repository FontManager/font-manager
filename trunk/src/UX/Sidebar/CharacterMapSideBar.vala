/* CharacterMapSideBar.vala
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

    public enum CharacterMapSideBarMode {
        SCRIPT,
        BLOCK,
        N_MODES
    }

    public class CharacterMapSideBar : Gtk.Box {

        public signal void mode_set (CharacterMapSideBarMode mode);
        public signal void selection_changed (Gucharmap.CodepointList codepoint_list);

        public CharacterMapSideBarMode mode {
            get {
                return (CharacterMapSideBarMode) selector.mode;
            }
            set {
                selector.mode = (int) value;
            }
        }

        public string? selected_script { get; set; default = null; }
        public string? selected_block { get; set; default = null; }

        Gtk.TreeView view;
        ModeSelector selector;
        Gucharmap.ScriptChaptersModel scripts;
        Gucharmap.BlockChaptersModel blocks;
        Gee.HashMap <string, int> num_chars;

        public CharacterMapSideBar () {
            orientation = Gtk.Orientation.VERTICAL;
            num_chars = new Gee.HashMap <string, int> ();
            selector = new ModeSelector();
            scripts = new Gucharmap.ScriptChaptersModel();
            blocks = new Gucharmap.BlockChaptersModel();
            view = new Gtk.TreeView();
            view.set_model(scripts);
            view.headers_visible = false;
            Gtk.TreeSelection selection = view.get_selection();
            selection.set_mode(Gtk.SelectionMode.SINGLE);
            var render = new Gtk.CellRendererText();
            var count = new CellRendererCount();
            count.type_name = null;
            count.type_name_plural = null;
            count.xalign = 1.0f;
            render.ellipsize = Pango.EllipsizeMode.END;
            view.insert_column_with_attributes(0, null, render, "text", 0, null);
            view.insert_column_with_data_func(1, "", count, count_cell_data_func);
            view.get_column(0).expand = true;
            view.get_column(1).expand = false;
            selector.add_mode(new Gtk.Label("Script"));
            selector.add_mode(new Gtk.Label("Block"));
            var blend = new Gtk.EventBox();
            selector.border_width = 4;
            blend.add(selector);
            pack_end(blend, false, true, 0);
            add_separator(this, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            var scroll = new Gtk.ScrolledWindow(null, null);
            scroll.add(view);
            pack_start(scroll, true, true, 0);
            view.show();
            scroll.show();
            selector.show();
            blend.show();
            connect_signals();
        }

        public void set_initial_selection (string script_path, string block_path) {
            Gtk.TreeIter _iter;
            if (mode == CharacterMapSideBarMode.SCRIPT)
                scripts.get_iter_from_string(out _iter, script_path);
            else
                blocks.get_iter_from_string(out _iter, block_path);
            view.get_selection().select_iter(_iter);
            view.scroll_to_cell(view.get_model().get_path(_iter), null, true, 0.5f, 0.5f);
            return;
        }

        internal void connect_signals () {
            view.get_selection().changed.connect((s) => {
                Gtk.TreeIter? _iter = null;
                bool selected = s.get_selected(null, out _iter);
                var model = (Gucharmap.ChaptersModel) view.get_model();
                if (selected) {
                    selection_changed(model.get_codepoint_list(_iter));
                    if (mode == CharacterMapSideBarMode.SCRIPT)
                        selected_script = ((Gtk.TreeModel) model).get_string_from_iter(_iter);
                    else
                        selected_block = ((Gtk.TreeModel) model).get_string_from_iter(_iter);
                }
            });

            selector.selection_changed.connect((i) => {
                Gtk.TreeIter? _iter_ = null;
                if ((CharacterMapSideBarMode) i == CharacterMapSideBarMode.SCRIPT) {
                    view.set_model(scripts);
                    if (selected_script == null)
                        scripts.id_to_iter("Latin", out _iter_);
                    else
                        scripts.get_iter_from_string(out _iter_, selected_script);
                    mode = CharacterMapSideBarMode.SCRIPT;
                } else {
                    view.set_model(blocks);
                    if (selected_block == null)
                        blocks.id_to_iter("Basic Latin", out _iter_);
                    else
                        blocks.get_iter_from_string(out _iter_, selected_block);
                    mode = CharacterMapSideBarMode.BLOCK;
                }
                view.get_selection().select_iter(_iter_);
                view.scroll_to_cell(view.get_model().get_path(_iter_), null, true, 0.5f, 0.5f);
                mode_set(mode);
            });
            return;
        }

        void count_cell_data_func (Gtk.CellLayout layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, 0, out val);
            var name = (string) val;
            if (!num_chars.has_key(name))
                num_chars[name] = ((Gucharmap.ChaptersModel) model).get_codepoint_list(treeiter).get_last_index();
            cell.set_property("count", num_chars[name]);
            val.unset();
            return;
        }

    }

}
