/* CharacterMapSideBar.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
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
                if (stack.get_visible_child_name() == "Scripts")
                    return CharacterMapSideBarMode.SCRIPT;
                else
                    return CharacterMapSideBarMode.BLOCK;
            }
            set {
                if (value == CharacterMapSideBarMode.SCRIPT)
                    stack.set_visible_child_name("Scripts");
                else
                    stack.set_visible_child_name("Blocks");
            }
        }

        public string? selected_script { get; set; default = "49"; }
        public string? selected_block { get; set; default = "1"; }

        private Gtk.TreeView script_view;
        private Gtk.TreeView block_view;
        private Gtk.Stack stack;
        private Gtk.StackSwitcher switcher;
        private Gtk.ScrolledWindow script_scroll;
        private Gtk.ScrolledWindow block_scroll;
        private Gucharmap.ScriptChaptersModel scripts;
        private Gucharmap.BlockChaptersModel blocks;
        private Gee.HashMap <string, int> num_chars;

        public CharacterMapSideBar () {
            orientation = Gtk.Orientation.VERTICAL;
            num_chars = new Gee.HashMap <string, int> ();
            stack = new Gtk.Stack();
            scripts = new Gucharmap.ScriptChaptersModel();
            blocks = new Gucharmap.BlockChaptersModel();
            script_view = new Gtk.TreeView();
            block_view = new Gtk.TreeView();
            script_view.set_model(scripts);
            block_view.set_model(blocks);
            Gtk.TreeView [] views = { script_view, block_view };
            foreach (var view in views) {
                view.headers_visible = false;
                var render = new Gtk.CellRendererText();
                render.ellipsize = Pango.EllipsizeMode.END;
                var count = new CellRendererCount();
                count.type_name = null;
                count.type_name_plural = null;
                count.xalign = 1.0f;
                Gtk.TreeSelection selection = view.get_selection();
                selection.set_mode(Gtk.SelectionMode.SINGLE);
                view.insert_column_with_attributes(0, null, render, "text", 0, null);
                view.insert_column_with_data_func(1, "", count, count_cell_data_func);
                view.get_column(0).expand = true;
                view.get_column(1).expand = false;
            }
            script_scroll = new Gtk.ScrolledWindow(null, null);
            script_scroll.add(script_view);
            block_scroll = new Gtk.ScrolledWindow(null, null);
            block_scroll.add(block_view);
            stack.add_titled(script_scroll, "Scripts", _("Unicode Script"));
            stack.add_titled(block_scroll, "Blocks", _("Unicode Block"));
            switcher = new Gtk.StackSwitcher();
            switcher.set_stack(stack);
            switcher.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            switcher.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            switcher.set_border_width(6);
            switcher.halign = Gtk.Align.CENTER;
            switcher.valign = Gtk.Align.CENTER;
            pack_end(switcher, false, true, 0);
            add_separator(this, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            pack_start(stack, true, true, 0);
            connect_signals();
        }

        public override void show () {
            script_view.show();
            block_view.show();
            stack.show();
            switcher.show();
            script_scroll.show();
            block_scroll.show();
            base.show();
            return;
        }

        public void set_initial_selection (string script_path, string block_path) {
            if (mode == CharacterMapSideBarMode.SCRIPT) {
                select_block_path(block_path);
                select_script_path(script_path);
            } else {
                select_script_path(script_path);
                select_block_path(block_path);
            }
            return;
        }

        private void select_script_path (string script_path) {
            Gtk.TreeIter _iter;
            scripts.get_iter_from_string(out _iter, script_path);
            script_view.get_selection().select_iter(_iter);
            script_view.scroll_to_cell(script_view.get_model().get_path(_iter), null, true, 0.5f, 0.5f);
            return;
        }

        private void select_block_path (string block_path) {
            Gtk.TreeIter _iter;
            blocks.get_iter_from_string(out _iter, block_path);
            block_view.get_selection().select_iter(_iter);
            block_view.scroll_to_cell(block_view.get_model().get_path(_iter), null, true, 0.5f, 0.5f);
            return;
        }

        private void connect_signals () {

            script_view.get_selection().changed.connect((s) => {
                Gtk.TreeIter? _iter = null;
                bool selected = s.get_selected(null, out _iter);
                var model = (Gucharmap.ChaptersModel) script_view.get_model();
                if (selected) {
                    selection_changed(model.get_codepoint_list(_iter));
                    selected_script = ((Gtk.TreeModel) model).get_string_from_iter(_iter);
                }
            });

            block_view.get_selection().changed.connect((s) => {
                Gtk.TreeIter? _iter = null;
                bool selected = s.get_selected(null, out _iter);
                var model = (Gucharmap.ChaptersModel) block_view.get_model();
                if (selected) {
                    selection_changed(model.get_codepoint_list(_iter));
                    selected_block = ((Gtk.TreeModel) model).get_string_from_iter(_iter);
                }
            });

            stack.notify["visible-child-name"].connect(() => {
                Gtk.TreeIter? iter = null;
                Gucharmap.ChaptersModel model;
                if (stack.get_visible_child_name() == "Scripts") {
                    mode = CharacterMapSideBarMode.SCRIPT;
                    model = (Gucharmap.ChaptersModel) script_view.get_model();
                    model.get_iter_from_string(out iter, selected_script);
                } else {
                    mode = CharacterMapSideBarMode.BLOCK;
                    model = (Gucharmap.ChaptersModel) block_view.get_model();
                    model.get_iter_from_string(out iter, selected_block);
                }
                if (iter != null)
                    selection_changed(model.get_codepoint_list(iter));
                mode_set(mode);
            });

            return;
        }

        private void count_cell_data_func (Gtk.TreeViewColumn layout,
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
