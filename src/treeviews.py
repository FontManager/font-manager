"""
This module handles everything related to the two main treeviews.
.
"""
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009, 2010 Jerry Casiano
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to:
#
# Free Software Foundation, Inc.
# 51 Franklin Street, Fifth Floor
# Boston, MA  02110-1301, USA.
#
# Suppress errors related to gettext
# pylint: disable-msg=E0602
# Suppress messages related to missing docstrings
# pylint: disable-msg=C0111

import gtk
import gobject

import xmlutils
import fontload

from common import match, search


FAMILY_LS = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
                                                    gobject.TYPE_STRING)


class Trees:
    """
    Set up treeviews.

    Connect any related handlers, treemodels, etc.
    """
    DRAG_TARGETS = [("reorder collections", gtk.TARGET_SAME_WIDGET, 0),
                        ("move 2 collections", gtk.TARGET_SAME_APP, 0)]
    DRAG_ACTIONS = (gtk.gdk.ACTION_DEFAULT |
                    gtk.gdk.ACTION_MOVE | gtk.gdk.ACTION_LINK)
    pending_event = None
    current_collection = None
    fonts_column = None
    def __init__(self, parent, builder):
        self.builder = builder
        self.selected_rows = []
        self.parent = parent
        get = self.builder.get_object
        self.category_tv = get('collections_tree')
        self.collection_tv = get('user_collections_tree')
        self.family_tv = get('families_tree')
        self.new_collection = get('new_collection')
        self.remove_collection = get('remove_collection')
        self.enable_collection = get('enable_collection')
        self.disable_collection = get('disable_collection')
        self.remove_font = get('remove_font')
        self.enable_font = get('enable_font')
        self.disable_font = get('disable_font')
        self.find_button = get('find_font')
        self.find_entry = get('find_entry')
        self.export = get("export")
        self.vpane = get('vpane')
        self.hpane = get('hpane')
        self.vpane.connect_after('event', self.pane_resized)
        self.hpane.connect_after('event', self.pane_resized)
        self.init_treeviews()
        self.connect_handlers()
        # select a row in each column
        self.category_tv.get_selection().select_path(1)
        self.family_tv.get_selection().select_path(0)
        return

    def init_treeviews(self):
        self.category_tv.set_model(fontload.category_ls)
        self.category_tv.get_selection().connect('changed', self._collection_changed)
        column = gtk.TreeViewColumn(_('Category'), gtk.CellRendererText(), markup=0)
        self.category_tv.append_column(column)

        self.collection_tv.set_model(fontload.collection_ls)
        self.collection_tv.get_selection().connect('changed', self._collection_changed)
        self.collection_tv.connect('drag-data-received', self._drag_data_received)
        self.collection_tv.enable_model_drag_dest(self.DRAG_TARGETS, self.DRAG_ACTIONS)
        self.collection_tv.enable_model_drag_source(gtk.gdk.BUTTON1_MASK
         | gtk.gdk.RELEASE_MASK, self.DRAG_TARGETS, self.DRAG_ACTIONS)
        renderer = gtk.CellRendererText()
        renderer.set_property('editable', True)
        renderer.connect('edited', self._set_collection_name)
        self.collection_column = gtk.TreeViewColumn(_('Collection'), renderer, markup=0)
        self.collection_column.set_sort_column_id(2)
        self.collection_tv.append_column(self.collection_column)

        self.family_tv.set_model(FAMILY_LS)
        self.family_tv.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        self.family_tv.connect_object('button-press-event', self._button_press, self)
        self.family_tv.connect_object('button-release-event', self._button_release, self)
        self.family_tv.connect_after('drag-begin', _begin_drag)
        self.family_tv.connect("row-activated", self._font_activated)
        self.family_tv.enable_model_drag_source(gtk.gdk.BUTTON1_MASK,
                                self.DRAG_TARGETS, self.DRAG_ACTIONS)
        self.fonts_column = gtk.TreeViewColumn(_('Font'), gtk.CellRendererText(), markup=0)
        self.fonts_column.set_sort_column_id(2)
        self.family_tv.append_column(self.fonts_column)

    def connect_handlers(self):
        handlers = {
        self.new_collection : self._on_new_collection,
        self.remove_collection : self._on_remove_collection,
        self.enable_collection : self._on_enable_collection,
        self.disable_collection : self._on_disable_collection,
        self.remove_font : self._on_remove_font,
        self.enable_font : self._on_enable_font,
        self.disable_font : self._on_disable_font,
        self.find_button : self._on_find_font
        }
        for widget, function in handlers.iteritems():
            widget.connect('clicked', function)
        self.find_entry.connect('icon-press', self._on_find_entry_icon)
        return

    def _button_press(self, unused_inst, event):
        """
        Intercept left mouse click
        """
        if event.button == 1:
            return self._block_selection(event)

    def _block_selection(self, event):
        """
        If more than one item is selected, block first release.

        Set pending event.
        """
        x, y = map(int, [event.x, event.y])
        try:
            path, unused_col, unused_cellx, unused_celly = \
            self.family_tv.get_path_at_pos(x, y)
        except TypeError:
            return True
        self.family_tv.grab_focus()
        selection = self.family_tv.get_selection()
        selected_rows = selection.get_selected_rows()
        unused_store, obj = selected_rows
        if len(obj) < 2:
            self.pending_event = None
            selection.set_select_function(lambda *args: True)
        elif ((selection.path_is_selected(path)
            and not (event.state & \
            (gtk.gdk.CONTROL_MASK|gtk.gdk.SHIFT_MASK)))):
            self.pending_event = [x, y]
            selection.set_select_function(lambda *args: False)
        elif event.type == gtk.gdk.BUTTON_PRESS:
            self.pending_event = None
            selection.set_select_function(lambda *args: True)
        return

    def _button_release(self, unused_inst, event):
        """
        Reset pending event, release block.
        """
        if self.pending_event:
            selection = self.family_tv.get_selection()
            selection.set_select_function(lambda *args: True)
            oldevent = self.pending_event
            self.pending_event = None
            if oldevent != [event.x, event.y]:
                return True
            x, y = map(int, [event.x, event.y])
            try:
                path, col, unused_cellx, unused_celly = \
                self.family_tv.get_path_at_pos(x, y)
            except TypeError:
                return True
            self.family_tv.set_cursor(path, col, 0)
        return

    def _drag_data_received(self, treeview, context, x, y,
                                unused_selection, unused_info, timestamp):
        """
        Controls re-ordering for the collections treeview and handles
        drops from fonts treeview.
        """
        drop_info = treeview.get_dest_row_at_pos(x, y)
        if drop_info:
            cpath, cpos = drop_info
            fmodel, fpaths = self.family_tv.get_selection().get_selected_rows()
            cmodel = treeview.get_model()
            citer = cmodel.get_iter(cpath)
            collection = cmodel[cpath][1]
        else:
            return
        if not fpaths:
            collection_tv = self.collection_tv.get_selection()
            unused_model, selected_iter = collection_tv.get_selected()
            row_data = (cmodel.get_value(selected_iter, 0),
                        cmodel.get_value(selected_iter, 1),
                        cmodel.get_value(selected_iter, 2))
            if (cpos == gtk.TREE_VIEW_DROP_BEFORE
                or cpos == gtk.TREE_VIEW_DROP_INTO_OR_BEFORE):
                cmodel.insert_before(citer, row_data)
            else:
                cmodel.insert_after(citer, row_data)
            if context.action == gtk.gdk.ACTION_MOVE:
                context.finish(True, True, timestamp)
        else:
            try:
                orphans = fontload.category_ls[3][1]
                update_orphans = True
            except IndexError:
                update_orphans = False
            for path in fpaths:
                obj = fmodel[path][1]
                collection.add(obj)
                if update_orphans:
                    try:
                        orphans.remove(obj)
                    except:
                        pass
        treeview.get_selection().select_path(cpath)
        self.update_views()
        font_tree = self.family_tv
        if font_tree.get_model().get_iter_first() is not None:
            font_tree.get_selection().select_path(0)
        return

    def _on_new_collection(self, unused_widget):
        new_name = _('New Collection')
        alt = 0
        while self._collection_exists(new_name):
            alt += 1
            new_name =  _('New Collection %s' % alt)
        collection = fontload.Collection(new_name)
        collection.builtin = False
        fontload.FontLoad.add_collection(collection)
        xmlutils.BlackList(parent=self.parent, fc_fonts=fontload.fc_fonts).save()
        model = self.collection_tv.get_model()
        path = model.iter_n_children(None) - 1
        self.collection_tv.scroll_to_cell(path, self.collection_column,
                            use_align=True, row_align=0.25, col_align=0.0)
        self.collection_tv.set_cursor(path, self.collection_column,
                                                start_editing=True)

    def _on_remove_collection(self, unused_widget):
        collection = self.current_collection
        name = collection.name
        tree = self.collection_tv
        model = tree.get_model()
        treeiter = search(model, model.iter_children(None), match, (2, name))
        try:
            path = model.get_path(treeiter)
            fontload.collections.remove(collection)
            self._update_collection_view(fontload.collection_ls)
        except (ValueError, TypeError):
            # Nothing selected, nothing to do...
            return
        try:
            model.get_iter(path)
            self.update_views()
            while gtk.events_pending():
                gtk.main_iteration()
            tree.get_selection().select_path(path)
        except ValueError:
            path_to_select = model.iter_n_children(None) - 1
            if (path_to_select >= 0):
                self.update_views()
                while gtk.events_pending():
                    gtk.main_iteration()
                tree.get_selection().select_path(path_to_select)
        return

    def _on_enable_collection(self, unused_widget):
        self._enable_collection(True)

    def _on_disable_collection(self, unused_widget):
        collection = self.current_collection
        if not collection:
            return
        if len(collection.fonts) < 1000:
            self._enable_collection(False)
        elif len(collection.fonts) > 1000 and \
        self._disable_mad_fonts(len(collection.fonts)):
            self._enable_collection(False)

    def _disable_mad_fonts(self, how_many):
        dialog = gtk.Dialog(_("Confirm Action"),
                            self.parent, gtk.DIALOG_MODAL,
                            (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                                gtk.STOCK_YES, gtk.RESPONSE_YES))
        dialog.set_default_response(gtk.RESPONSE_CANCEL)
        message = _("""
Disabling large amounts of fonts at once can have quite an impact on the desktop.
If you choose to continue, it is suggested that you close all open applications
and be patient should your desktop become unresponsive for a bit.

Really disable %s fonts?
        """) % how_many
        text = gtk.Label()
        text.set_padding(15, 0)
        text.set_text(message)
        dialog.vbox.pack_start(text, padding=10)
        text.show()
        ret = dialog.run()
        dialog.destroy()
        return (ret == gtk.RESPONSE_YES)

    def _set_collection_name(self, unused_widget, path, new_name):
        model = self.collection_tv.get_model()
        treeiter = model.get_iter(path)
        collection = model.get_value(treeiter, 1)
        if not self._collection_exists(new_name) and new_name.strip() != "":
            model.set(treeiter, 2, new_name)
            collection.name = new_name
        self.update_views()

    def _on_remove_font(self, unused_widget):
        collection = self.current_collection
        for font in self._iter_selected_fonts():
            collection.remove(font)
        self.update_views()

    def _on_enable_font(self, unused_widget):
        selected_fonts = self.family_tv.get_selection().count_selected_rows()
        if selected_fonts > 0:
            for font in self._iter_selected_fonts():
                if not font.enabled:
                    font.enabled = True
        else:
            return
        self.update_views()
        xmlutils.BlackList(parent=self.parent,
                            fc_fonts=fontload.fc_fonts).save()

    def _on_disable_font(self, unused_widget):
        selected_fonts = self.family_tv.get_selection().count_selected_rows()
        if not selected_fonts:
            return
        elif selected_fonts < 1000:
            for font in self._iter_selected_fonts():
                if font.enabled:
                    font.enabled = False
        elif selected_fonts > 1000 and \
        self._disable_mad_fonts(selected_fonts):
            for font in self._iter_selected_fonts():
                if font.enabled:
                    font.enabled = False
        self.update_views()
        xmlutils.BlackList(parent=self.parent,
                            fc_fonts=fontload.fc_fonts).save()

    def _on_find_font(self, widget):
        box_height = self.find_entry.size_request()[1]
        vpane_pos = self.vpane.get_position()
        if widget.get_active():
            if vpane_pos > 0:
                self.vpane.set_position(vpane_pos + box_height)
            self.find_entry.show()
            self.find_entry.grab_focus()
            widget.set_label(_('Hide search box'))
        else:
            if vpane_pos > 0:
                self.vpane.set_position(vpane_pos - box_height)
            self.find_entry.hide()
            widget.set_label(_('Search Fonts'))
            if self.family_tv.get_selection().count_selected_rows() == 0 \
            or self.find_entry.get_text() == '':
                self.family_tv.scroll_to_point(0, 0)

    def _on_find_entry_icon(self, unused_widget, unused_x, unused_y):
        self.find_entry.set_text('')
        self.family_tv.scroll_to_point(0, 0)

    def update_sensitivity(self, treeview):
        """
        Controls UI sensitivity
        """
        block = _('All Fonts'), _('System'), _('Orphans')
        widgets = self.remove_collection, self.disable_collection, self.remove_font
        fonts = self.current_collection.fonts
        collection = self.current_collection.get_name()
        for widget in widgets:
            if collection in block:
                widget.set_sensitive(False)
            elif collection == _('User'):
                widget.set_sensitive(False)
                if widget == widgets[1]:
                    widget.set_sensitive(True)
            else:
                widget.set_sensitive(True)
        if not len(fonts) > 0:
            self.export.set_sensitive(False)
        else:
            self.export.set_sensitive(True)
        if treeview == self.category_tv:
            self.collection_tv.get_selection().unselect_all()
        else:
            self.category_tv.get_selection().unselect_all()
        return

    def _collection_changed(self, tree_selection):
        """
        Sets current collection
        """
        try:
            model, treeiter = tree_selection.get_selected()
            self.current_collection = model.get_value(treeiter, 1)
            self._show_collection()
            font_tree = self.family_tv
            if font_tree.get_model().get_iter_first() is not None:
                font_tree.get_selection().select_path(0)
            treeview = tree_selection.get_tree_view()
            self.update_sensitivity(treeview)
        # This happens when we unselect all in the sister view
        except TypeError:
            pass
        return

    @staticmethod
    def _collection_exists(name):
        for collection in fontload.collections:
            if collection.name == name:
                return True
        for collection in fontload.categories:
            if collection.name == name:
                return True
        return False

    def _enable_collection(self, enabled):
        collection = self.current_collection
        if not collection:
            return
        collection.set_enabled(enabled)
        self.update_views()
        xmlutils.BlackList(parent=self.parent,
                            fc_fonts=fontload.fc_fonts).save()
        self._show_collection()

    def _font_activated(self, unused_tree, unused_path, unused_col):
        """
        Handles family treeview events -- double clicks, enter key
        """
        for font in self._iter_selected_fonts():
            font.enabled = (not font.enabled)
        self.update_views()
        xmlutils.BlackList(parent=self.parent,
                            fc_fonts=fontload.fc_fonts).save()

    def _iter_selected_fonts(self):
        selected_fonts = \
        self.family_tv.get_selection().get_selected_rows()
        model, path_list = selected_fonts
        for path in path_list:
            self.selected_rows.append(path)
            obj = model[path][1]
            yield obj

    def _show_collection(self):
        collection = self.current_collection
        tree = self.family_tv
        lstore = tree.get_model()
        if not collection:
            return
        # lstore can be None during a reset
        if lstore:
            scroll = self.builder.get_object('families_scroll')
            scroll.set_sensitive(False)
            while gtk.events_pending():
                gtk.main_iteration()
            tree.freeze_child_notify()
            tree.set_model(None)
            lstore.clear()
        else:
            return
        fontlist = sorted(collection.fonts,
                        cmp=lambda x, y: cmp(x.family, y.family))
        # Create a new liststore on every call to this function since
        # re-using an already sorted liststore can cause MAJOR slowdown.
        lstore = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
                                                    gobject.TYPE_STRING)
        for font in fontlist:
            lstore.append([font.get_label(), font, font.family])
        tree.set_model(lstore)
        tree.thaw_child_notify()
        scroll.set_sensitive(True)
        # Fixes http://code.google.com/p/font-manager/issues/detail?id=2
        # by simulating a user click on the column header, sorting column
        self.fonts_column.clicked()
        # I guess this setting gets thrown out with the old model
        tree.set_search_column(2)
        tree.set_search_entry(self.find_entry)
        # In case update was triggered by enabling/disabling fonts prevent
        # list from shifting too much and confusing or annoying the user
        if len(collection.fonts) > 0 and len(self.selected_rows) > 0:
            self.selected_rows.sort()
            path = self.selected_rows[0]
            tree.get_selection().select_path(path)
            tree.scroll_to_cell(path, self.fonts_column,
                                use_align=True, row_align=0.25, col_align=0.0)
            self.selected_rows = []
        return

    @staticmethod
    def _update_collection_view(model, collections=fontload.collections):
        for collection in collections:
            collection.set_enabled_from_fonts()
        treeiter = model.get_iter_first()
        while treeiter:
            label, obj = model.get(treeiter, 0, 1)
            if obj in collections:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(treeiter, 0, new_label)
                treeiter = model.iter_next(treeiter)
            else:
                if not model.remove(treeiter):
                    return
        return

    @staticmethod
    def _update_font_view(tree):
        model = tree.get_model()
        treeiter = model.get_iter_first()
        while treeiter:
            label, obj = model.get(treeiter, 0, 1)
            new_label = obj.get_label()
            if label != new_label:
                model.set(treeiter, 0, new_label)
                treeiter = model.iter_next(treeiter)
            else:
                if not model.remove(treeiter):
                    return
        return

    @staticmethod
    def save():
        """
        Saves user collections to an xml file
        """
        xmlutils.Groups(fontload.collections, fontload.collection_ls,
                        fontload.Collection, fontload.fc_fonts).save()

    def update_views(self):
        """
        Refresh both the collection and fonts treeviews.
        """
        self._update_collection_view(fontload.category_ls, collections=fontload.categories)
        self._update_collection_view(fontload.collection_ls)
        self._update_font_view(self.family_tv)
        self._show_collection()
        self.parent.queue_draw()

    def pane_resized(self, unused_widget, event):
        if event.type == gtk.gdk.BUTTON_RELEASE:
            self.parent.queue_resize()


# this is strictly cosmetic
# Todo: make this nice instead of just a stock icon
def _begin_drag(unused_widget, context):
    """
    Set custom drag icon.
    """
    #model, paths = self.family_tv.get_selection().get_selected_rows()
    #max = 1
    # if dragging more than one row, change drag icon
    #if len(paths) > max:
    context.set_icon_stock(gtk.STOCK_ADD, 16, 16)
    return

