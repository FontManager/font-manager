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

# Suppress warnings related to unused arguments
# pylint: disable-msg=W0613
# Suppress warnings related to unused variables
# pylint: disable-msg=W0612


import gtk
import pango

import xmlutils
import fontload

class Trees:
    """
    Set up both the collections treeview and the fonts treeview.

    Connect any related handlers, treemodels, etc.
    """
    DRAG_TARGETS = [("reorder collections", gtk.TARGET_SAME_WIDGET, 0),
                        ("move 2 collections", gtk.TARGET_SAME_APP, 0)]
    DRAG_ACTIONS = (gtk.gdk.ACTION_DEFAULT |
                    gtk.gdk.ACTION_MOVE | gtk.gdk.ACTION_LINK)

    pending_event = None
    Collection = fontload.Collection
    collection_ls = fontload.collection_ls
    family_ls = fontload.family_ls

    def __init__(self, fontload, parent=None, builder=None):

        if builder is None:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder

        self.collections = fontload.collections
        self.fc_fonts = fontload.fc_fonts

        self.parent = parent

        self.collection_tv = self.builder.get_object('collections_tree')
        self.family_tv = self.builder.get_object('families_tree')

        self.new_collection = self.builder.get_object('new_collection')
        self.remove_collection = self.builder.get_object('remove_collection')
        self.enable_collection = self.builder.get_object('enable_collection')
        self.disable_collection = self.builder.get_object('disable_collection')
        self.rename_collection = self.builder.get_object('rename_collection')

        self.remove_font = self.builder.get_object('remove_font')
        self.enable_font = self.builder.get_object('enable_font')
        self.disable_font = self.builder.get_object('disable_font')

        self.find_box = self.builder.get_object("find_box")
        self.find_button = self.builder.get_object('find_button')
        self.find_entry = self.builder.get_object('find_entry')
        self.close_find = self.builder.get_object('close_find')

        self.init_treeviews()
        self.connect_handlers()
        self._init_select()
        return

    def init_treeviews(self):
        self.collection_tv.set_model(self.collection_ls)
        self.collection_tv.get_selection().connect('changed',
                                                self._collection_changed)
        self.collection_tv.connect('drag-data-received',
                                                self._drag_data_received)
        self.collection_tv.connect('row-activated',
                                    self._collection_activated)
        self.collection_tv.set_row_separator_func(_is_row_separator)
        self.collection_tv.enable_model_drag_dest(self.DRAG_TARGETS,
                                                    self.DRAG_ACTIONS)
        self.collection_tv.enable_model_drag_source(gtk.gdk.BUTTON1_MASK
         | gtk.gdk.RELEASE_MASK, self.DRAG_TARGETS, self.DRAG_ACTIONS)
        column = gtk.TreeViewColumn(_('Collection'),
                                    gtk.CellRendererText(), markup=0)
        self.collection_tv.append_column(column)

        self.family_tv.set_model(self.family_ls)
        self.family_tv.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        self.family_tv.connect_object('button-press-event',
                                    self._button_press, self)
        self.family_tv.connect_object('button-release-event',
                                    self._button_release, self)
        self.family_tv.connect_after('drag-begin', _begin_drag)
        self.family_tv.connect("row-activated", self._font_activated)
        self.family_tv.enable_model_drag_source(gtk.gdk.BUTTON1_MASK,
                                self.DRAG_TARGETS, self.DRAG_ACTIONS)
        cell_render = gtk.CellRendererText()
        cell_render.set_property('width-chars', 30)
        cell_render.set_property('ellipsize', pango.ELLIPSIZE_END)
        column = gtk.TreeViewColumn(_('Font'),
                                    cell_render, markup=0)
        column.set_sort_column_id(2)
        self.family_tv.append_column(column)
        self.family_tv.set_search_entry(self.find_entry)

    def _init_select(self):
        # select the first option in each column
        self.collection_tv.get_selection().select_path(0)
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

        self.find_button.connect('clicked', self._on_find_button)
        self.find_entry.connect('icon-press', self._on_find_entry_icon)
        self.close_find.connect('clicked', self._on_close_find)
        return

    ###############################################################

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
        ctree = treeview.get_selection()
        cmodel, citer = ctree.get_selected()
        sc0 = cmodel.get_value(citer, 0)
        sc1 = cmodel.get_value(citer, 1)
        sc2 = cmodel.get_value(citer, 2)
        try:
            sc3 = cmodel.get_value(citer, 3)
        except AttributeError:
            sc3 = None
        scx = (sc0, sc1, sc2, sc3)
        fonts = self.family_tv.get_selection().get_selected_rows()
        fmodel, fpaths = fonts
        if drop_info:
            cpath, cpos = drop_info
            collection = cmodel[cpath][1]
        else:
            return

        orphans = self.collection_ls[3][1]

        block = 'All Fonts', 'System', 'User', 'Orphans', 0, 1, 2, 3

        if sc3 not in block and fpaths == []:
            try:
                if cpath[1] == None:
                    return
            except IndexError:
                pass
            if cpath[0] not in block :
                treeiter = cmodel.get_iter(cpath)
                if (cpos == gtk.TREE_VIEW_DROP_BEFORE
                    or cpos == gtk.TREE_VIEW_DROP_INTO_OR_BEFORE):
                    cmodel.insert_before(treeiter, scx)
                else:
                    cmodel.insert_after(treeiter, scx)
            else:
                if cpath[0] not in block:
                    cmodel.append(scx)
            if cpath[0] not in block and \
            context.action == gtk.gdk.ACTION_MOVE:
                context.finish(True, True, timestamp)
            self.collection_tv.get_selection().select_path(cpath)
            self.update_views()
        elif fpaths != []:
            if cpath[0] not in block:
                for path in fpaths:
                    obj = fmodel[path][1]
                    collection.add(obj)
                    try:
                        orphans.remove(obj)
                    except:
                        pass
                self.collection_tv.get_selection().select_path(cpath)
                self.update_views()
        else:
            print 'Built-in collections cannot be modified'

        return

    ###############################################################

    def _on_new_collection(self, widget):
        new_name = _("New Collection")
        while True:
            new_name = self._get_new_collection_name(widget, new_name)
            if not new_name:
                return
            if not self._collection_name_exists(new_name) and new_name != None:
                break
        collection = fontload.Collection(new_name)
        collection.builtin = False
        fontload.FontLoad().add_collection(collection)
        xmlutils.BlackList(self.fc_fonts).save()

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
        collection = self.get_current_collection()
        if not collection:
            return
        ctree = self.collection_tv.get_selection()
        cmodel, citer = ctree.get_selected()
        try:
            sc3 = cmodel.get_value(citer, 3)
        except AttributeError:
            sc3 = None
        if sc3 == 'Orphans':
            dialog = gtk.MessageDialog(self.parent,
            gtk.DIALOG_MODAL, gtk.MESSAGE_INFO,
            gtk.BUTTONS_CLOSE,
_("\n Please use the preferences dialog to disable this collection  \n"))
            dialog.run()
            dialog.destroy()
            return
        elif len(collection.fonts) < 1:
            self.collections.remove(collection)
            self.collection_tv.get_selection().select_path(0)
            self.family_tv.get_selection().select_path(0)
        elif self._confirm_remove_collection(collection):
            self.collections.remove(collection)
            self.collection_tv.get_selection().select_path(0)
            self.family_tv.get_selection().select_path(0)
        self.collection_tv.columns_autosize()
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
        text.set_padding(15,0)
        text.set_text(message)
        dialog.vbox.pack_start(text, padding=10)
        text.show()
        ret = dialog.run()
        dialog.destroy()
        return (ret == gtk.RESPONSE_YES)

    def _on_enable_collection(self, unused_widget):
        collection = self.get_current_collection()
        if not collection:
            return
        self._enable_collection(True)

    def _on_disable_collection(self, unused_widget):
        collection = self.get_current_collection()
        if not collection:
            return
        how_many = 0
        for unused_font in collection.fonts:
            how_many += 1
        if how_many > 1000 and self._disable_mad_fonts(how_many):
            self._enable_collection(False)
        elif how_many < 1000:
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
        collection = self.get_current_collection()
        if collection == None:
            return
        name = collection.name
        while True:
            name = self._get_new_collection_name(self, name)
            if not self._collection_name_exists(name) and name != None:
                self._rename_collection(name)
                collection.name = name
                self.collection_tv.columns_autosize()
                self.update_views()
                xmlutils.BlackList(self.fc_fonts).save()
                break
            elif not name or collection.name == name:
                return

    def _rename_collection(self, new_name):
        sel = self.collection_tv.get_selection()
        unused_model, treeiter = sel.get_selected()
        if not treeiter:
            return
        self.collection_ls.set(treeiter, 2, new_name)

    def _on_remove_font(self, unused_widget):
        collection = self.get_current_collection()
        for font in self._iter_selected_fonts():
            collection.remove(font)
        self.update_views()

    def _on_enable_font(self, unused_widget):
        how_many = 0
        for font in self._iter_selected_fonts():
            if not font.enabled:
                how_many += 1
        if how_many < 1:
            return
        else:
            for font in self._iter_selected_fonts():
                if not font.enabled:
                    font.enabled = True
            self.update_views()
            xmlutils.BlackList(self.fc_fonts).save()

    def _on_disable_font(self, unused_widget):
        how_many = 0
        for font in self._iter_selected_fonts():
            if font.enabled:
                how_many += 1
        if how_many < 1:
            return
        elif how_many < 1000:
            for font in self._iter_selected_fonts():
                if font.enabled:
                    font.enabled = False
            self.update_views()
            xmlutils.BlackList(self.fc_fonts).save()
        elif how_many > 1000 and self._disable_mad_fonts(how_many):
            for font in self._iter_selected_fonts():
                if font.enabled:
                    font.enabled = False
            self.update_views()
            xmlutils.BlackList(self.fc_fonts).save()

    def _on_find_button(self, unused_widget):
        self.find_entry.set_text('')
        self.find_box.show()
        self.find_entry.grab_focus()

    def _on_find_entry_icon(self, unused_widget, unused_x, unused_y):
        self.find_entry.set_text('')
        self.family_tv.scroll_to_point(0, 0)

    def _on_close_find(self, unused_widget):
        self.find_box.hide()
        if self.family_tv.get_selection().count_selected_rows() == 0 \
        or self.find_entry.get_text() == '':
            self.family_tv.scroll_to_point(0, 0)


    def _collection_activated(self, unused_tree, path, unused_col):
        """
        Handles collection treeview events -- double clicks, enter key
        """
        block = (0,), (1,), (3,)
        if path in block:
            return
        collection = self.get_current_collection()
        self._enable_collection(not collection.enabled)
        return

    def _collection_changed(self, unused_sel):
        """
        Controls UI sensitivity, displays selected collection
        """
        collection = self.get_current_collection()
        ctree = self.collection_tv.get_selection()
        cmodel, citer = ctree.get_selected()
        try:
            sc3 = cmodel.get_value(citer, 3)
        except AttributeError:
            sc3 = None
        if collection:
            block = 'All Fonts', 'System'
            if sc3 in block:
                self.rename_collection.set_sensitive(False)
                self.remove_collection.set_sensitive(False)
                self.disable_collection.set_sensitive(False)
            elif sc3 == 'User':
                self.rename_collection.set_sensitive(False)
                self.remove_collection.set_sensitive(False)
                self.disable_collection.set_sensitive(True)
            elif sc3 == 'Orphans':
                self.rename_collection.set_sensitive(False)
                self.remove_collection.set_sensitive(True)
                self.disable_collection.set_sensitive(False)
            else:
                self.rename_collection.set_sensitive(True)
                self.remove_collection.set_sensitive(True)
                self.disable_collection.set_sensitive(True)
        else:
            self._show_collection(None)
        self._show_collection(collection)
        return

    def _collection_name_exists(self, name):
        for collection in self.collections:
            if collection.name == name:
                return True
        return False

    def _enable_collection(self, enabled):
        collection = self.get_current_collection()
        if enabled:
            collection.set_enabled(enabled)
            self.update_views()
            xmlutils.BlackList(self.fc_fonts).save()
        else:
            collection.set_enabled(enabled)
            self.update_views()
            xmlutils.BlackList(self.fc_fonts).save()

    def _font_activated(self, unused_tree, unused_path, unused_col):
        """
        Handles family treeview events -- double clicks, enter key
        """
        for font in self._iter_selected_fonts():
            font.enabled = (not font.enabled)
        self.update_views()

    def get_current_collection(self):
        sel = self.collection_tv.get_selection()
        model, treeiter = sel.get_selected()
        if not treeiter:
            return
        return model.get(treeiter, 1)[0]

    def _iter_selected_fonts(self):
        selected_fonts = \
        self.family_tv.get_selection().get_selected_rows()
        model, path_list = selected_fonts
        for path in path_list:
            obj = model[path][1]
            yield obj

    def _show_collection(self, collection):
        lstore = self.family_tv.get_model()
        lstore.clear()
        if not collection:
            return
        for font in collection.fonts:
            treeiter = lstore.append()
            lstore.set(treeiter, 0, font.get_label())
            lstore.set(treeiter, 1, font)
            lstore.set(treeiter, 2, font.family)
        return

    def _update_collection_view(self):
        for collection in self.collections:
            collection.set_enabled_from_fonts()
        model = self.collection_tv.get_model()
        treeiter = model.get_iter_first()
        while treeiter:
            label, obj = model.get(treeiter, 0, 1)
            if not obj:
                treeiter = model.iter_next(treeiter)
                continue
            if obj in self.collections:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(treeiter, 0, new_label)
                treeiter = model.iter_next(treeiter)
            else:
                if not model.remove(treeiter):
                    return

    def _update_font_view(self):
        collection = self.get_current_collection()
        model = self.family_tv.get_model()
        treeiter = model.get_iter_first()
        while treeiter:
            label, obj = model.get(treeiter, 0, 1)
            if obj in collection.fonts:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(treeiter, 0, new_label)
                treeiter = model.iter_next(treeiter)
            else:
                if not model.remove(treeiter):
                    return
        return

    def save(self):
        """
        Saves user collections to an xml file
        """
        xmlutils.Groups(self.collections, self.collection_ls,
        self.Collection, self.fc_fonts).save(self.collection_tv)

    def update_views(self):
        """
        Refresh both the collection and fonts treeviews.
        """
        self._update_collection_view()
        self._update_font_view()


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

def _is_row_separator(model, treeiter):
    obj = model.get(treeiter, 1)[0]
    return (obj is None)

