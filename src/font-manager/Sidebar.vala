/* Sidebar.vala
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-sidebar.ui")]
    public class Sidebar : Gtk.Stack {

        public string mode {
            get {
                return get_visible_child_name();
            }
            set {
                set_visible_child_name(value);
            }
        }

        public StandardSidebar? standard {
            get {
                return (StandardSidebar) get_child_by_name("Standard");
            }
        }

        public OrthographyList? orthographies {
            get {
                return (OrthographyList) get_child_by_name("Orthographies");
            }
        }

        public override void constructed () {
            add_view(new FontManager.StandardSidebar(), "Standard");
            add_view(new FontManager.OrthographyList(), "Orthographies");
            notify["visible-child-name"].connect(() => {
                if (get_visible_child_name() == "Standard")
                    set_transition_type(Gtk.StackTransitionType.UNDER_LEFT);
                else
                    set_transition_type(Gtk.StackTransitionType.OVER_RIGHT);
            });
            standard.category_tree.notify["language-filter"].connect((o, p) => {
                add_view(standard.category_tree.language_filter.settings, "LanguageFilterSettings");
            });
            base.constructed();
            return;
        }

        public void add_view (Gtk.Widget sidebar_view, string name) {
            add_named(sidebar_view, name);
            sidebar_view.show();
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-standard-sidebar.ui")]
    public class StandardSidebar : Gtk.Box {

        public signal void selection_changed (Filter? filter);

        [GtkChild] public unowned CategoryTree category_tree { get; }
        [GtkChild] public unowned CollectionTree collection_tree { get; }
        [GtkChild] public unowned Gtk.Expander collection_expander { get; }

        [GtkChild] unowned Gtk.Button add_button;
        [GtkChild] unowned Gtk.Button edit_button;
        [GtkChild] unowned Gtk.Button remove_button;
        [GtkChild] unowned Gtk.ScrolledWindow sidebar_scroll;

        public void on_tree_selection_changed (BaseTreeView tree, Filter? filter) {
            if (filter == null)
                return;
            Gtk.TreeView sibling = (tree is CollectionTree) ? (Gtk.TreeView) category_tree :
                                                              (Gtk.TreeView) collection_tree;
            Gtk.TreeSelection selection = sibling.get_selection();
            selection.unselect_all();
            selection_changed(filter);
            return;
        }

        public override void constructed () {

            category_tree.selection_changed.connect((f) => {
                on_tree_selection_changed(category_tree, f);
                bool is_lang_filter = (f != null && f.index == CategoryIndex.LANGUAGE);
                set_control_sensitivity(edit_button, is_lang_filter);
                if (is_lang_filter) {
                    edit_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    edit_button.set_relief(Gtk.ReliefStyle.NORMAL);
                } else {
                    edit_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    edit_button.set_relief(Gtk.ReliefStyle.NONE);
                }
            });
            collection_tree.selection_changed.connect((f) => {
                on_tree_selection_changed(collection_tree, f);
                set_control_sensitivity(remove_button, f != null);
            });

            add_button.clicked.connect(() => {
                collection_tree.on_add_collection();
                add_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                add_button.set_relief(Gtk.ReliefStyle.NONE);
            });

            edit_button.clicked.connect(() => {
                get_default_application().main_window.sidebar.mode = "LanguageFilterSettings";
            });

            remove_button.clicked.connect(() => {
                collection_tree.on_remove_collection();
                if (collection_tree.model.iter_n_children(null) < 1) {
                    add_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    add_button.set_relief(Gtk.ReliefStyle.NORMAL);
                }
            });

            collection_expander.notify["expanded"].connect_after((o, p) => {
                bool expanded = collection_expander.get_expanded();
                set_control_sensitivity(add_button, expanded);
                if (!expanded && collection_tree.selected_filter != null)
                    category_tree.select_first_row();
                if (expanded && collection_tree.model.iter_n_children(null) < 1) {
                    add_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    add_button.set_relief(Gtk.ReliefStyle.NORMAL);
                } else {
                    add_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    add_button.set_relief(Gtk.ReliefStyle.NONE);
                }
            });

            collection_tree.collection_added.connect(() => {
                Idle.add(() => {
                    sidebar_scroll.vadjustment.set_value(sidebar_scroll.vadjustment.get_upper());
                    return GLib.Source.REMOVE;
                });
            });

            base.constructed();
            return;
        }

    }

}

