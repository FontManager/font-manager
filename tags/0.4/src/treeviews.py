"""
This module handles everything related to the two main treeviews.
.
"""
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009 Jerry Casiano
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
import operator

import xmlutils
import fontload

from common import match, search

family_ls = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
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
    def __init__(self, parent=None, builder=None):
        if builder is None:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder
        self.selected_rows = []
        self.parent = parent
        self.category_tv = self.builder.get_object('collections_tree')
        self.collection_tv = self.builder.get_object('user_collections_tree')
        self.family_tv = self.builder.get_object('families_tree')
        self.new_collection = self.builder.get_object('new_collection')
        self.remove_collection = self.builder.get_object('remove_collection')
        self.enable_collection = self.builder.get_object('enable_collection')
        self.disable_collection = self.builder.get_object('disable_collection')
        self.rename_collection = self.builder.get_object('rename_collection')
        self.remove_font = self.builder.get_object('remove_font')
        self.enable_font = self.builder.get_object('enable_font')
        self.disable_font = self.builder.get_object('disable_font')
        self.find_button = self.builder.get_object('find_font')
        self.find_entry = self.builder.get_object('find_entry')
        self.init_treeviews()
        self.connect_handlers()
        self.init_select()
        return

    def init_treeviews(self):
        self.category_tv.set_model(fontload.category_ls)
        self.category_tv.get_selection().connect('changed',
                                                self._category_changed)
        column = gtk.TreeViewColumn(_('Category'),
                                    gtk.CellRendererText(), markup=0)
        self.category_tv.append_column(column)
        
        self.collection_tv.set_model(fontload.collection_ls)
        self.collection_tv.get_selection().connect('changed',
                                                self._collection_changed)
        self.collection_tv.connect('drag-data-received',
                                                self._drag_data_received)
        self.collection_tv.connect('row-activated',
                                    self._collection_activated)
        self.collection_tv.enable_model_drag_dest(self.DRAG_TARGETS,
                                                    self.DRAG_ACTIONS)
        self.collection_tv.enable_model_drag_source(gtk.gdk.BUTTON1_MASK
         | gtk.gdk.RELEASE_MASK, self.DRAG_TARGETS, self.DRAG_ACTIONS)
        column = gtk.TreeViewColumn(_('Collection'),
                                    gtk.CellRendererText(), markup=0)
        column.set_sort_column_id(2)
        self.collection_tv.append_column(column)

        self.family_tv.set_model(family_ls)
        self.family_tv.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        self.family_tv.connect_object('button-press-event',
                                    self._button_press, self)
        self.family_tv.connect_object('button-release-event',
                                    self._button_release, self)
        self.family_tv.connect_after('drag-begin', _begin_drag)
        self.family_tv.connect("row-activated", self._font_activated)
        self.family_tv.enable_model_drag_source(gtk.gdk.BUTTON1_MASK,
                                self.DRAG_TARGETS, self.DRAG_ACTIONS)
        self.fonts_column = gtk.TreeViewColumn(_('Font'),
                                    gtk.CellRendererText(), markup=0)
        self.fonts_column.set_sort_column_id(2)
        self.family_tv.append_column(self.fonts_column)
        
        
    def init_select(self):
        # select the first option in each column
        self.category_tv.get_selection().select_path(1)
        self.family_tv.get_selection().select_path(0)
        return

    def connect_handlers(self):
        self.new_collection.connect('clicked', self._on_new_collection)
        self.remove_collection.connect('clicked', self._on_remove_collection)
        self.enable_collection.connect('clicked', self._on_enable_collection)
        self.disable_collection.connect('clicked', self._on_disable_collection)
        self.rename_collection.connect('clicked', self._on_rename_collection)
        self.remove_font.connect('clicked', self._on_remove_font)
        self.enable_font.connect('clicked', self._on_enable_font)
        self.disable_font.connect('clicked', self._on_disable_font)
        self.find_button.connect('clicked', self._on_find_font)
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
            fonts = self.family_tv.get_selection().get_selected_rows()
            fmodel, fpaths = fonts
            cmodel = treeview.get_model()
            citer = cmodel.get_iter(cpath)
            collection = cmodel[cpath][1]
        else:
            return
        if not fpaths:
            collection_tv = self.collection_tv.get_selection()
            unused_model, selected_iter = collection_tv.get_selected()
            sc0 = cmodel.get_value(selected_iter, 0)
            sc1 = cmodel.get_value(selected_iter, 1)
            sc2 = cmodel.get_value(selected_iter, 2)
            row_data = (sc0, sc1, sc2)
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
        return

    def _on_new_collection(self, widget):
        new_name = _("New Collection")
        default_names = _('All Fonts'), _('System'), _('User'), _('Orphans')
        while True:
            new_name = self._get_new_collection_name(widget, new_name)
            if not new_name:
                return
            if not self._collection_name_exists(new_name) \
            and new_name != None \
            and new_name not in default_names:
                break
        collection = fontload.Collection(new_name)
        collection.builtin = False
        fontload.FontLoad.add_collection(collection)
        xmlutils.BlackList(parent=self.parent, 
                            fc_fonts=fontload.fc_fonts).save()

    def _get_new_collection_name(self, unused_widget, old_name):
        dialog = gtk.Dialog(_("Enter Collection Name"),
                self.parent, gtk.DIALOG_MODAL,
                (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                    gtk.STOCK_OK, gtk.RESPONSE_OK))
        dialog.set_default_size(325, 50)
        dialog.set_default_response(gtk.RESPONSE_OK)
        text = gtk.Entry()
        if old_name:
            text.set_text(old_name)
        text.set_property("activates-default", True)
        dialog.vbox.set_spacing(5)
        dialog.vbox.pack_start(text)
        text.show()
        ret = dialog.run()
        dialog.destroy()
        if ret == gtk.RESPONSE_OK:
            return text.get_text().strip()
        return None

    def _on_remove_collection(self, unused_widget):
        collection = self.current_collection
        if not collection:
            return
        if len(collection.fonts) <= 1:
            fontload.collections.remove(collection)
            self.category_tv.get_selection().select_path(0)
            self.family_tv.get_selection().select_path(0)
        elif self._confirm_remove_collection(collection):
            fontload.collections.remove(collection)
            self.category_tv.get_selection().select_path(0)
            self.family_tv.get_selection().select_path(0)
        self.update_views()
        return

    def _confirm_remove_collection(self, collection):
        dialog = gtk.Dialog(_("Confirm Action"),
        self.parent, gtk.DIALOG_MODAL,
        (gtk.STOCK_NO, gtk.RESPONSE_NO, gtk.STOCK_YES, gtk.RESPONSE_YES))
        dialog.set_default_response(gtk.RESPONSE_CANCEL)
        message = _("""
Deleted collections cannot be recovered.

Really delete \"%s\"?
        """) % collection.name
        text = gtk.Label()
        text.set_padding(15, 0)
        text.set_text(message)
        dialog.vbox.pack_start(text, padding=10)
        text.show()
        ret = dialog.run()
        dialog.destroy()
        return (ret == gtk.RESPONSE_YES)

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

    def _on_rename_collection(self, unused_widget):
        collection = self.current_collection
        default_names = _('All Fonts'), _('System'), _('User'), _('Orphans')
        if not collection:
            return
        name = collection.name
        while True:
            name = self._get_new_collection_name(self, name)
            if not self._collection_name_exists(name) and \
            name != None and name not in default_names:
                self._rename_collection(name)
                collection.name = name
                break
            elif not name or collection.name == name:
                return
        self.update_views()

    def _rename_collection(self, new_name):
        sel = self.collection_tv.get_selection()
        model, treeiter = sel.get_selected()
        if not treeiter:
            return
        model.set(treeiter, 2, new_name)

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
        if selected_fonts < 1:
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
        if widget.get_active():
            #self.find_entry.set_text('')
            self.find_entry.show()
            self.find_entry.grab_focus()
            widget.set_label(_('Hide search box'))
        else:
            self.find_entry.hide()
            widget.set_label(_('Search Fonts'))
            if self.family_tv.get_selection().count_selected_rows() == 0 \
            or self.find_entry.get_text() == '':
                self.family_tv.scroll_to_point(0, 0)

    def _on_find_entry_icon(self, unused_widget, unused_x, unused_y):
        self.find_entry.set_text('')
        self.family_tv.scroll_to_point(0, 0)

    def _collection_activated(self, unused_treeview, unused_path, unused_col):
        """
        Handles collection treeview events -- double clicks, enter key
        """
        self._enable_collection(not self.current_collection.enabled)
        return

    def update_sensitivity(self, treeview):
        """
        Controls UI sensitivity
        """
        block = _('All Fonts'), _('System'), _('Orphans')
        collection = self.current_collection.get_name()
        if collection in block:
            self.remove_collection.set_sensitive(False)
            self.disable_collection.set_sensitive(False)
            self.rename_collection.set_sensitive(False)
            self.remove_font.set_sensitive(False)
        elif collection == _('User'):
            self.remove_collection.set_sensitive(False)
            self.disable_collection.set_sensitive(True)
            self.rename_collection.set_sensitive(False)
            self.remove_font.set_sensitive(False)
        else:
            self.remove_collection.set_sensitive(True)
            self.disable_collection.set_sensitive(True)
            self.rename_collection.set_sensitive(True)
            self.remove_font.set_sensitive(True)
        if treeview == self.category_tv:
            self.collection_tv.get_selection().unselect_all()
        else:
            self.category_tv.get_selection().unselect_all()
        return
        
    def _category_changed(self, tree_selection):
        """
        Sets current collection
        """
        while gtk.events_pending():
            gtk.main_iteration()
        try:
            model, treeiter = tree_selection.get_selected()
            self.current_collection = model.get_value(treeiter, 1)
            self._show_collection()
            treeview = tree_selection.get_tree_view()
            self.update_sensitivity(treeview)
        # This happens when we unselect all in the sister view
        except TypeError:
            pass
        return
            
    def _collection_changed(self, tree_selection):
        """
        Sets current collection
        """
        try:
            model, treeiter = tree_selection.get_selected()
            self.current_collection = model.get_value(treeiter, 1)
            self._show_collection()
            treeview = tree_selection.get_tree_view()
            self.update_sensitivity(treeview)
        # This happens when we unselect all in the sister view
        except TypeError:
            pass
        return
    
    @staticmethod
    def _collection_name_exists(name):
        for collection in fontload.collections:
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
        # This function gets triggered during a reset
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
            treeiter = lstore.append()
            lstore.set(treeiter, 0, font.get_label())
            lstore.set(treeiter, 1, font)
            lstore.set(treeiter, 2, font.family)
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
    def _update_categories_view(model):
        for collection in fontload.categories:
            collection.set_enabled_from_fonts()
        treeiter = model.get_iter_first()
        while treeiter:
            label, obj = model.get(treeiter, 0, 1)
            if obj in fontload.categories:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(treeiter, 0, new_label)
                treeiter = model.iter_next(treeiter)
            else:
                if not model.remove(treeiter):
                    return
        return
    
    @staticmethod
    def _update_collection_view(model):
        for collection in fontload.collections:
            collection.set_enabled_from_fonts()
        treeiter = model.get_iter_first()
        while treeiter:
            label, obj = model.get(treeiter, 0, 1)
            if obj in fontload.collections:
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
        self._update_categories_view(fontload.category_ls)
        self._update_collection_view(fontload.collection_ls)
        self._update_font_view(self.family_tv)
        self._show_collection()
        self.parent.queue_draw()
        
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
    context.set_icon_stock(gtk.STOCK_ADD, 22, 22)
    return
