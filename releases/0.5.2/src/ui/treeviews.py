"""
This module handles everything related to treeviews.
"""
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009, 2010 Jerry Casiano
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to:
#
#    Free Software Foundation, Inc.
#    51 Franklin Street, Fifth Floor
#    Boston, MA 02110-1301, USA.

import gtk
import glib
import gobject

from os.path import join

from constants import PACKAGE_DATA_DIR
from utils.common import match, search


TARGET_TYPE_COLLECTION_ROW = 10
TARGET_TYPE_FAMILY_ROW = 20

COLLECTION_DRAG_TARGETS = [
                ('reorder', gtk.TARGET_SAME_WIDGET, TARGET_TYPE_COLLECTION_ROW),
                ("receive", gtk.TARGET_SAME_APP, TARGET_TYPE_FAMILY_ROW)
                ]
COLLECTION_DRAG_ACTIONS = (gtk.gdk.ACTION_DEFAULT | gtk.gdk.ACTION_MOVE)


class Treeviews(object):
    _types = {
                'TrueType'      :   'truetype.png',
                'Type 1'        :   'type1.png',
                'BDF'           :   'bitmap.png',
                'PCF'           :   'bitmap.png',
                'Type 42'       :   'type42.png',
                'CID Type 1'    :   'type1.png',
                'CFF'           :   'opentype.png',
                'PFR'           :   'bitmap.png',
                'Windows FNT'   :   'bitmap.png'
                }
    def __init__(self, objects):
        self.objects = objects
        self.manager = self.objects['FontManager']
        self.current_collection = None
        self.pending_event = None
        self.selected_families = []
        self.selected_paths = []
        self.category_tree = self.objects['CategoryTree']
        self.collection_tree = self.objects['CollectionTree']
        self.family_tree = self.objects['FamilyTree']
        self._setup_columns()
        self._connect_handlers()
        self.category_tree.get_selection().select_path((0, 0))
        self.family_tree.get_selection().select_path(0)
        for tree in self.category_tree, self.collection_tree, self.family_tree:
            tree.columns_autosize()
        # Load font type logos
        self.logos = {}
        pixbuf = gtk.gdk.pixbuf_new_from_file
        for typ in self._types.iterkeys():
            self.logos[typ] = pixbuf(join(PACKAGE_DATA_DIR, self._types[typ]))
        self.logos['blank'] = pixbuf(join(PACKAGE_DATA_DIR, 'blank.png'))

    def _connect_handlers(self):
        handlers = {
            self.objects['NewCollection']       :   self._on_new_collection,
            self.objects['RemoveCollection']    :   self._on_remove_collection,
            self.objects['EnableCollection']    :   self._on_enable_collection,
            self.objects['DisableCollection']   :   self._on_disable_collection,
            self.objects['RemoveFamily']        :   self._on_remove_families,
            self.objects['EnableFamily']        :   self._on_enable_families,
            self.objects['DisableFamily']       :   self._on_disable_families,
            }
        for widget, function in handlers.iteritems():
            widget.connect('clicked', function)
        self.objects['VerticalPane'].connect('event', self._on_pane_resize)
        self.objects['HorizontalPane'].connect('event', self._on_pane_resize)
        self.objects['SearchFonts'].connect('toggled', self._on_search)
        self.objects['FamilySearchBox'].connect('icon-press', self._on_entry_icon)
        return

    def _setup_columns(self):
        self._setup_categories()
        self._setup_collections()
        self._setup_families()
        return

    def _setup_categories(self):
        category_model = gtk.TreeStore(gobject.TYPE_STRING,
                                    gobject.TYPE_STRING, gobject.TYPE_STRING)
        cell_renderer = gtk.CellRendererText()
        cell_renderer.set_property('xpad', 5)
        cell_renderer.set_property('ypad', 3)
        category_column = gtk.TreeViewColumn(_('Category'),
                                                cell_renderer, markup = 1)
        self.category_tree.set_model(category_model)
        self.category_tree.append_column(category_column)
        category_treeselect = self.category_tree.get_selection()
        category_treeselect.set_select_function(lambda path: len(path) == 2)
        category_treeselect.connect('changed', self._on_collection_selected)
        if self.objects['Preferences'].tooltips:
            self.category_tree.set_tooltip_column(2)
        self._load_categories()
        return

    def _setup_collections(self):
        collection_model = gtk.TreeStore(gobject.TYPE_STRING,
                                    gobject.TYPE_STRING, gobject.TYPE_STRING)
        editable_cells = gtk.CellRendererText()
        editable_cells.set_property('editable', True)
        editable_cells.set_property('xpad', 5)
        editable_cells.set_property('ypad', 3)
        editable_cells.connect('edited', self._set_collection_name)
        collection_column = gtk.TreeViewColumn(_('Collection'),
                                                    editable_cells, markup = 1)
        self.collection_tree.set_model(collection_model)
        self.collection_tree.append_column(collection_column)
        collection_treeselect = self.collection_tree.get_selection()
        collection_treeselect.set_select_function(lambda path: len(path) == 2)
        collection_treeselect.connect('changed', self._on_collection_selected)
        if self.objects['Preferences'].tooltips:
            self.collection_tree.set_tooltip_column(2)
        self.collection_tree.enable_model_drag_dest(COLLECTION_DRAG_TARGETS,
                                                    COLLECTION_DRAG_ACTIONS)
        self.collection_tree.enable_model_drag_source\
                                (gtk.gdk.BUTTON1_MASK | gtk.gdk.RELEASE_MASK,
                            COLLECTION_DRAG_TARGETS, COLLECTION_DRAG_ACTIONS)
        self.collection_tree.connect('drag-drop', self._on_drag_drop)
        self.collection_tree.connect('drag-data-received',
                                            self._on_drag_data_received)
        self._load_collections()
        return

    def _setup_families(self):
        family_model = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING)
        family_column = gtk.TreeViewColumn(_('Family'),
                                            gtk.CellRendererText(), markup = 1)
        self.family_tree.set_model(family_model)
        family_treeselect = self.family_tree.get_selection()
        family_treeselect.set_mode(gtk.SELECTION_MULTIPLE)
        self.family_tree.connect('button-press-event', self._on_button_press)
        self.family_tree.connect('button-release-event', self._on_button_release)
        self.family_tree.connect_after('drag-begin', _begin_drag)
        self.family_tree.connect('row-activated', self._on_family_activated)
        self.family_tree.connect('query-tooltip', self._on_family_tooltip)
        self.family_tree.append_column(family_column)
        self.family_tree.enable_model_drag_source\
                                (gtk.gdk.BUTTON1_MASK | gtk.gdk.RELEASE_MASK,
                            COLLECTION_DRAG_TARGETS, COLLECTION_DRAG_ACTIONS)
        return

    @staticmethod
    def _on_drag_drop(widget, context, x, y, tstamp):
        try:
            return (len(widget.get_path_at_pos(x, y)[0]) != 2)
        except TypeError:
            return True

    def _on_drag_data_received(self, widget, context, x, y, data, info, tstamp):
        model = widget.get_model()
        root = model.get_iter_root()
        if info == TARGET_TYPE_COLLECTION_ROW:
            treeiter = widget.get_selection().get_selected()[1]
            data = model.get(treeiter, 0, 1, 2)
            drop_info = widget.get_dest_row_at_pos(x, y)
            if drop_info:
                path, position = drop_info
                treeiter = model.get_iter(path)
                if (position == gtk.TREE_VIEW_DROP_BEFORE
                    or position == gtk.TREE_VIEW_DROP_INTO_OR_BEFORE):
                    model.insert_before(root, treeiter, data)
                else:
                    model.insert_after(root, treeiter, data)
            else:
                model.append(root, [data])
            if context.action == gtk.gdk.ACTION_MOVE:
                context.finish(True, True, tstamp)
        elif info == TARGET_TYPE_FAMILY_ROW:
            path = widget.get_path_at_pos(x, y)[0]
            treeiter = model.get_iter(path)
            data = model.get(treeiter, 0, 1)
            families = self._selected_families()
            collection = data[0]
            self.manager.add_families_to(collection, families)
            widget.get_selection().select_path(path)
        self.update_views()
        return

    def _on_button_press(self, widget, event):
        """
        Block first release to allow dragging multiple rows. Set pending event.
        """
        # FIXME
        if event.button == 2:
            # bring up our popup menu
            pass
        cell = widget.get_path_at_pos(int(event.x), int(event.y))
        if cell is None:
            return True
        path = cell[0]
        selection = widget.get_selection()
        if ((selection.path_is_selected(path) and not\
        (event.state & (gtk.gdk.CONTROL_MASK | gtk.gdk.SHIFT_MASK)))):
            self.pending_event = [int(event.x), int(event.y)]
            selection.set_select_function(lambda *args: False)
        else:
            self.pending_event = None
            selection.set_select_function(lambda *args: True)
        return

    def _on_button_release(self, widget, event):
        """
        Reset pending event, release block.
        """
        if self.pending_event is not None:
            selection = widget.get_selection()
            selection.set_select_function(lambda *args: True)
            oldevent = self.pending_event
            self.pending_event = None
            if oldevent != [event.x, event.y]:
                return True
            cell = widget.get_path_at_pos(int(event.x), int(event.y))
            if cell is not None:
                widget.set_cursor(cell[0], cell[1], 0)
        return

    def _on_family_tooltip(self, widget, x, y, unused_kmode, tooltip):
        if not x > (widget.size_request()[0] * 1.5):
            return False
        try:
            model = widget.get_model()
            x, y = widget.convert_widget_to_bin_window_coords(x, y)
            path = widget.get_path_at_pos(x, y)[0]
            treeiter = model.get_iter(path)
            name = model.get_value(treeiter, 0)
            family = self.manager[name].pango_family
            markup = \
            '\n\t<span weight="heavy" size="large">%s</span>\t\t\n\n' % name
            for face in family.list_faces():
                subs = (face.describe(), face.get_face_name())
                markup += '<span font_desc="%s">\t%s\t\t</span>\n' % subs
            tooltip.set_markup(markup)
            icon = self._get_type_icon(name)
            tooltip.set_icon(icon)
            return True
        except (TypeError, ValueError):
            return False

    def _get_type_icon(self, family):
        typ = None
        for k, v in self.manager[family].styles.iteritems():
            typ = self.manager[family].styles[k]['filetype']
            if typ == 'TrueType' and \
            self.manager[family].styles[k]['filepath'].endswith('.otf'):
                typ = 'CFF'
            break
        if not typ:
            typ = 'blank'
        return self.logos[typ]

    def _load_categories(self):
        category_model = self.category_tree.get_model()
        header = category_model.append(None,
                            [_('Category'), get_header(_('Category')), None])
        categories = _('All Fonts'), _('System'), _('User')
        for category in categories:
            obj = self.manager.categories[category]
            category_model.append(header,
                                [obj.get_name(), obj.get_label(), obj.comment])
        if self.objects['Preferences'].orphans:
            obj = self.manager.categories[_('Orphans')]
            category_model.append(header,
                                [obj.get_name(), obj.get_label(), obj.comment])
        self.category_tree.expand_all()
        return

    def _load_collections(self):
        collection_model = self.collection_tree.get_model()
        header = collection_model.append(None,
                        [_('Collection'), get_header(_('Collection')), None])
        if self.manager.initial_collection_order is not None:
            for collection in self.manager.initial_collection_order:
                obj = self.manager.collections[collection]
                collection_model.append(header,
                                [obj.get_name(), obj.get_label(), obj.comment])
        self.collection_tree.expand_all()
        return

    def _set_collection_name(self, unused_renderer, path, new_name):
        model = self.collection_tree.get_model()
        treeiter = model.get_iter(path)
        old_name = model.get_value(treeiter, 0)
        if new_name == old_name:
            return
        collections = self.manager.list_collections()
        if not new_name in collections and new_name.strip != '':
            collections = self.manager.collections
            collections[new_name] = collections[old_name]
            collections[new_name].name = new_name
            del collections[old_name]
            model.set(treeiter, 0, new_name)
            model.set(treeiter, 1, collections[new_name].get_label())
        return

    def _on_collection_selected(self, tree_selection):
        try:
            model, treeiter = tree_selection.get_selected()
            self.current_collection = model.get_value(treeiter, 0)
            self._show_collection()
            path = self.family_tree.get_model().get_iter_first()
            if path is not None:
                self.family_tree.get_selection().select_path(0)
            view = tree_selection.get_tree_view()
            self._update_sensitivity(view)
        # This happens when we unselect all in the sister view
        except TypeError:
            pass
        self.update_views()
        return

    def _on_disable_collection(self, unused_widget):
        selected = len(self.manager.list_families_in(self.current_collection))
        if selected < 1000:
            self.manager.disable_collection(self.current_collection)
        elif self._modify_mad_fonts():
            self.manager.disable_collection(self.current_collection)
        self.update_views()
        return

    def _on_disable_families(self, unused_widget):
        selected = self._selected_families()
        if len(selected) < 1000:
            self.manager.set_disabled(selected)
        elif self._modify_mad_fonts():
            self.manager.set_disabled(selected)
        self.update_views()
        return

    def _on_enable_collection(self, unused_widget):
        selected = len(self.manager.list_families_in(self.current_collection))
        if selected < 1000:
            self.manager.enable_collection(self.current_collection)
        elif self._modify_mad_fonts():
            self.manager.enable_collection(self.current_collection)
        self.update_views()
        return

    def _on_enable_families(self, unused_widget):
        selected = self._selected_families()
        if len(selected) < 1000:
            self.manager.set_enabled(selected)
        elif self._modify_mad_fonts():
            self.manager.set_enabled(selected)
        self.update_views()
        return

    def _on_entry_icon(self, widget, unused_x, unused_y):
        self.objects['FamilySearchBox'].set_text('')
        self.family_tree.get_selection().select_path(0)
        self.family_tree.scroll_to_point(0, 0)
        return

    def _on_family_activated(self, unused_tree, unused_path, unused_column):
        """
        Handle treeview double clicks.
        """
        for family in self._selected_families():
            if self.manager[family].enabled:
                self.manager.set_disabled(family)
            else:
                self.manager.set_enabled(family)
        self.update_views()
        return

    def _on_remove_collection(self, unused_widget):
        model = self.collection_tree.get_model()
        name = self.current_collection
        treeiter = search(model, model.iter_children(None), match, (0, name))
        try:
            path = model.get_path(treeiter)
            self.manager.remove_collection(name)
            self._update_collection_treeview()
            while gtk.events_pending():
                gtk.main_iteration()
        except (ValueError, TypeError):
            # Nothing selected, nothing to do...
            return
        # Select the next available colllection or the first category
        try:
            treeiter = model.get_iter(path)
            self.collection_tree.get_selection().select_path(path)
        except ValueError:
            root_node = model.get_iter_root()
            if model.iter_has_child(root_node):
                path = model.iter_n_children(root_node) - 1
                if (path >= 0):
                    self.collection_tree.get_selection().select_path((0, path))
            else:
                self.category_tree.get_selection().select_path((0, 0))
        return

    def _on_remove_families(self, unused_widget):
        self.manager.remove_families_from(self.current_collection,
                                            self._selected_families())
        self.update_views()
        return

    def _on_search(self, widget):
        search_box = self.objects['FamilySearchBox']
        vpane = self.objects['VerticalPane']
        box_height = search_box.size_request()[1]
        vpane_pos = vpane.get_position()
        if widget.get_active():
            if vpane_pos > 0:
                vpane.set_position(vpane_pos + box_height)
            search_box.show()
            search_box.grab_focus()
            widget.set_label(_('Hide search box'))
        else:
            if vpane_pos > 0:
                vpane.set_position(vpane_pos - box_height)
            search_box.hide()
            widget.set_label(_('Search Fonts'))
            if self.family_tree.get_selection().count_selected_rows() == 0 \
            or search_box.get_text() == '':
                self.family_tree.scroll_to_point(0, 0)

    def _on_pane_resize(self, unused_widget, event):
        if event.type == gtk.gdk.BUTTON_RELEASE:
            self.objects['MainWindow'].queue_resize()

    def _modify_mad_fonts(self):
        dialog = self.objects['MadFontsWarning']
        result = dialog.run()
        dialog.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        return (result == gtk.RESPONSE_OK)

    def _update_sensitivity(self, treeview):
        """
        Controls UI sensitivity
        """
        block = _('All Fonts'), _('System'), _('Orphans')
        widgets = (
                    self.objects['RemoveCollection'],
                    self.objects['DisableCollection'],
                    self.objects['RemoveFamily']
                    )
        families = self.manager.list_families_in(self.current_collection)
        collection = self.current_collection
        for widget in widgets:
            if collection in block:
                widget.set_sensitive(False)
            elif collection == _('User'):
                widget.set_sensitive(False)
                if widget == widgets[1]:
                    widget.set_sensitive(True)
            else:
                widget.set_sensitive(True)
        if not len(families) > 0:
            self.objects['Export'].set_sensitive(False)
        else:
            self.objects['Export'].set_sensitive(True)
        if treeview == self.category_tree:
            self.collection_tree.get_selection().unselect_all()
        else:
            self.category_tree.get_selection().unselect_all()
        return

    def _on_new_collection(self, unused_widget):
        new_name = _('New Collection')
        alt = 0
        while new_name in self.manager.list_collections():
            alt += 1
            new_name =  _('New Collection %s' % alt)
        collection = self.manager.create_collection(new_name)
        obj = self.manager.collections[new_name]
        model = self.collection_tree.get_model()
        header = model.get_iter_first()
        treeiter = model.append(header,
                            [obj.get_name(), obj.get_label(), obj.comment])
        path = model.get_path(treeiter)
        self.collection_tree.expand_all()
        column = self.collection_tree.get_column(0)
        self.collection_tree.scroll_to_cell(path, column,
                            use_align=True, row_align=0.25, col_align=0.0)
        self.collection_tree.set_cursor(path, column, start_editing=True)
        return

    def _selected_paths(self):
        model, path_list = self.family_tree.get_selection().get_selected_rows()
        del self.selected_paths[:]
        for path in path_list:
            self.selected_paths.append(path)
            family = model[path][0]
        return self.selected_paths

    def _selected_families(self):
        model, path_list = self.family_tree.get_selection().get_selected_rows()
        del self.selected_families[:]
        for path in path_list:
            self.selected_families.append(model[path][0])
        return self.selected_families

    def _show_collection(self):
        allcollections = self.manager.list_collections() + self.manager.list_categories()
        if not self.current_collection in allcollections:
            self.current_collection = _('All Fonts')
        model = self.family_tree.get_model()
        # model can be None during a reset
        if model:
            model.clear()
            self.objects['FamilyScroll'].set_sensitive(False)
            while gtk.events_pending():
                gtk.main_iteration()
            self.family_tree.freeze_child_notify()
            self.family_tree.set_model(None)
        else:
            return
        families = self.manager.list_families_in(self.current_collection)
        # Create a new liststore on every call to this function since
        # re-using an already sorted liststore can cause MAJOR slowdown.
        family_model = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING)
        for family in families:
            obj = self.manager[family]
            family_model.append([obj.get_name(), obj.get_label()])
        self.family_tree.set_model(family_model)
        self.family_tree.thaw_child_notify()
        self.objects['FamilyScroll'].set_sensitive(True)
        # These settings are thrown out with the old model
        self.family_tree.set_search_column(0)
        self.family_tree.get_column(0).set_sort_column_id(0)
        self.family_tree.set_enable_search(True)
        self.family_tree.set_search_entry(self.objects['FamilySearchBox'])
        # In case update was triggered by enabling/disabling fonts *try* to
        # prevent list from shifting too much and confusing or annoying the user
        if len(families) > 0 and len(self.selected_paths) > 0:
            path = self.selected_paths[0]
            self.family_tree.get_selection().select_path(path)
            column = self.family_tree.get_column(0)
            self.family_tree.scroll_to_cell(path, column,
                                use_align=True, row_align=0.25, col_align=0.0)
            del self.selected_paths[:]
        return

    def _update_category_treeview(self):
        model = self.category_tree.get_model()
        header = model.get_iter_first()
        treeiter = model.iter_children(header)
        while treeiter:
            name, label = model.get(treeiter, 0, 1)
            try:
                obj = self.manager.categories[name]
            except KeyError:
                if not model.remove(treeiter):
                    return
                continue
            new_label = obj.get_label()
            if label != new_label:
                model.set(treeiter, 1, new_label)
            treeiter = model.iter_next(treeiter)
        return

    def _update_collection_treeview(self):
        model = self.collection_tree.get_model()
        header = model.get_iter_first()
        treeiter = model.iter_children(header)
        while treeiter:
            name, label = model.get(treeiter, 0, 1)
            try:
                obj = self.manager.collections[name]
            except KeyError:
                if not model.remove(treeiter):
                    return
                continue
            new_label = obj.get_label()
            if label != new_label:
                model.set(treeiter, 1, new_label)
            treeiter = model.iter_next(treeiter)
        return

    def _update_family_treeview(self):
        model = self.family_tree.get_model()
        treeiter = model.get_iter_first()
        while treeiter:
            name, label = model.get(treeiter, 0, 1)
            try:
                obj = self.manager[name]
            except KeyError:
                if not model.remove(treeiter):
                    return
                continue
            new_label = obj.get_label()
            if label != new_label:
                model.set(treeiter, 1, new_label)
            treeiter = model.iter_next(treeiter)
        return

    def update_views(self):
        """
        Refresh both the collection and fonts treeviews.
        """
        #available_collections = \
        #self.manager.list_categories() + self.manager.list_collections()
        #if not self.current_collection in available_collections:
            #self.category_tree.get_selection().select_path((0, 0))
            #self.family_tree.get_selection().select_path(0)
        self._selected_paths()
        self.manager.auto_enable_collections()
        self._update_category_treeview()
        self._update_collection_treeview()
        self._update_family_treeview()
        self._show_collection()
        self.objects['MainWindow'].queue_draw()


def get_header(title):
    header = glib.markup_escape_text(title)
    return '<span size="x-large" weight="heavy">%s</span>' % header


# this is strictly cosmetic
# Todo: make this nice instead of just a stock icon
def _begin_drag(widget, context):
    """
    Set custom drag icon.
    """
    paths = widget.get_selection().get_selected_rows()[1]
    if len(paths) > 1:
        context.set_icon_stock(gtk.STOCK_DND_MULTIPLE, 16, 16)
    else:
        context.set_icon_stock(gtk.STOCK_DND, 16, 16)
    return
