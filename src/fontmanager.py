# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2008 Karl Pickett <http://fontmanager.blogspot.com/>
# Copyright (C) 2009 Jerry Casiano
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

import os
import gtk, gobject
import logging

from os.path import exists

import xmlconf
from fontload import FontLoad
from stores import Family
from config import *
from fm_collections import *

C = Collections()

class FontManager(gtk.Window):
    # at this level import * works but throws a warning... :-\
    from handlers import \
    on_about_button, on_help, on_disable_font, on_enable_font, \
    on_manage_fonts, on_disable_collection, on_enable_collection, \
    on_new_collection, on_remove_collection, on_rename_collection, \
    on_size_adjustment_value_changed, on_find_button, on_close_find, \
    on_find_entry_icon, on_custom_text, on_font_info, on_remove_font, \
    on_font_preferences, on_export, on_app_prefs
    
    DRAG_TARGETS = [("reorder collections", gtk.TARGET_SAME_WIDGET, 0),
                        ("move 2 collections", gtk.TARGET_SAME_APP, 0)] 
    DRAG_ACTIONS = \
    (gtk.gdk.ACTION_DEFAULT | gtk.gdk.ACTION_MOVE | gtk.gdk.ACTION_LINK)
    
    preview_mode = 0
    preview_font_size = 11
    font_tags = []
    custom_text = DEFAULT_CUSTOM_TEXT
    
    def __init__(self, parent=None):
        
        logging.info("Disabling blacklist temporarily...")
        xmlconf.disable_blacklist()
        
        # load ui file
        self.builder = gtk.Builder()
        from ui import ui
        self.builder.add_from_string(ui)
        self.builder.connect_signals(self)
        self.style_combo = gtk.combo_box_new_text()
        
        self.MainWindow = self.builder.get_object("window")
        self.MainWindow.connect('destroy', quit)
        self.MainWindow.set_title(PACKAGE)
        self.MainWindow.set_size_request(850, 500)
        
        # find and set up icon for use throughout app windows
        icon_theme = gtk.icon_theme_get_default()
        try:
            app_icon = icon_theme.load_icon("preferences-desktop-font", 48, 0)
        except gobject.GError, exc:
            logging.warn("Could not find preferences-desktop-font icon", exc)
        gtk.window_set_default_icon_list(app_icon)
        
        # get our find box
        self.find_box = self.builder.get_object("find_box")
        # so we can hide it...
        self.find_box.hide()
        self.find_entry = self.builder.get_object("find_entry")
        
        # set up a reference to add/remove fonts
        self.manage_fonts = self.builder.get_object("manage_fonts")
        
        # set up the collections list box
        collections = self.init_collections()
        self.clb = self.builder.get_object("collections_list_box")
        self.clb.pack_start(collections)
        
        # set up the fonts list box
        fonts = self.init_families()
        self.flb = self.builder.get_object("fonts_list_box")
        self.flb.pack_start(fonts)
        
        # set up an adjustment for our size selectors
        self.size_adjustment = self.builder.get_object("size_adjustment")
        # correct value on start
        self.size_adjustment.set_value(self.preview_font_size)
        self.size = self.size_adjustment.get_value()
        # get our slider and spinbutton
        self.slider = self.builder.get_object("font_size_slider")
        self.spinbutton = self.builder.get_object("font_size_spinbutton")
        
        # set up the font preview area
        preview = self.builder.get_object("font_preview")
        preview.set_pixels_above_lines(5)
        self.text_view = preview
        fsb = self.builder.get_object("font_size_box")
        fsb.pack_start(self.style_combo, True, True)
        self.style_combo.connect("changed", self.style_changed)
        self.style_combo.show()
        self.init_preview_choices()
        
        # font preferences, at least for GNOME
        self.font_prefs = self.builder.get_object("font_preferences")
        if exists("/usr/bin/gnome-appearance-properties") or \
        exists("/usr/local/bin/gnome-appearance-properties"):
            self.font_prefs.set_sensitive(True)
        else:
            self.font_prefs.set_sensitive(False)
        
        self.export = self.builder.get_object("export")
        if not exists("/usr/bin/file-roller") and \
        not exists("usr/local/bin/file-roller"):
            self.export.set_sensitive(False)
            
        # fill everything
        FontLoad(self.MainWindow)
        xmlconf.load_blacklist()
        C.create_collections()
        
        # these variables are created by FontLoad
        from fontload import total_fonts
        # and used here for our silly "status" bar
        self.status_bar = self.builder.get_object("total_fonts")
        self.status_bar.set_label(_("  Fonts : %s") % total_fonts)
        
        # showtime
        self.MainWindow.show()
        
        # select the first option in each column
        collection_tv.get_selection().select_path(0)
        family_tv.get_selection().select_path(0)
        # resize columns to contents, at least for the fonts view
        # collections scroll in case someone goes for a really long name
        family_tv.columns_autosize()
        
        logging.info("Re-enabling blacklist")
        xmlconf.enable_blacklist()
        
# Init --------------------------------------------------------------- #


    def init_collections(self):
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        tv = collection_tv
        tv.set_size_request(155, 375)
        tv.set_model(collection_ls)
        tv.set_search_column(2)
        tv.set_reorderable(False)
        tv.get_selection().connect("changed", C.collection_changed)
        tv.connect("drag-data-received", self.drag_data_received)
        tv.enable_model_drag_dest(self.DRAG_TARGETS, self.DRAG_ACTIONS)
        tv.enable_model_drag_source\
        (gtk.gdk.BUTTON1_MASK | gtk.gdk.RELEASE_MASK, self.DRAG_TARGETS, self.DRAG_ACTIONS)
        tv.connect("row-activated", C.collection_activated)
        tv.set_row_separator_func(C.is_row_separator_collection)
        column = gtk.TreeViewColumn(_('Collection'), gtk.CellRendererText(), markup=0)
        tv.append_column(column)
        sw.add(tv)
        sw.show_all()
        return sw

    def init_families(self):
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)
        tv = family_tv
        tv.set_model(family_ls)
        tv.set_search_column(2)
        tv.set_rubber_banding(True)
        tv.connect_object('button-press-event', self.button_press, self)
        tv.connect_object('button-release-event', self.button_release, self)
        tv.connect_after('drag-begin', self.begin_drag)
        self.pending_event = None
        tv.set_search_entry(self.find_entry)
        tv.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        tv.get_selection().connect("changed", self.font_changed)
        tv.connect("row-activated", self.font_activated)
        tv.enable_model_drag_source\
        (gtk.gdk.BUTTON1_MASK, self.DRAG_TARGETS, self.DRAG_ACTIONS)
        column = gtk.TreeViewColumn(_('Font'), gtk.CellRendererText(), markup=0)
        column.set_sort_column_id(2)
        tv.append_column(column)
        sw.add(tv)
        sw.show_all()
        return sw
        
    def init_preview_choices(self):
        # get our radio buttons from ui file
        pob = self.builder.get_object("preview_options_box")
        sr = self.builder.get_object("sample_radio")
        fir = self.builder.get_object("font_info_radio")
        cr = self.builder.get_object("custom_radio")
        # link them
        sr.set_group(None)
        fir.set_group(sr)
        cr.set_group(sr)
        # Sample Text = 0
        # Custom Text = 1
        # Font Info = 2
        sr.connect("toggled", self.preview_mode_changed, 0)
        fir.connect("toggled", self.preview_mode_changed, 2)
        cr.connect("toggled", self.preview_mode_changed, 1)
        
        # XXX right now this only works for GNOME
        # kde, xfce don't seem to have comparable progs?
        # in case gnome-font-viewer is installed
        epob = self.builder.get_object("extended_preview_options_box")
        if exists("/usr/bin/gnome-font-viewer") or \
        exists("/usr/local/bin/gnome-font-viewer"):
            self.custom_text_toggle = self.builder.get_object("custom_text")
            self.font_info = self.builder.get_object("font_info")
            pob.hide()
        else: epob.hide()


# Drag and Drop ----------------------------------------------------- #


# these first three allow multiple DnD from the fonts tree
# by intercepting button 1 events
    def button_press(self, inst, event):
        if event.button == 1: 
            return self.block_selection(event)

    def block_selection(self, event):
        x, y = map(int, [event.x, event.y])
        try: 
            path, col, cellx, celly = family_tv.get_path_at_pos(x, y)
        except TypeError: 
            return True
        family_tv.grab_focus()
        selection = family_tv.get_selection()
        sr = selection.get_selected_rows()
        store, obj = sr
        if len(obj) < 2:
            self.pending_event = None
            selection.set_select_function(lambda *args: True)
        elif ((selection.path_is_selected(path)
            and not (event.state & (gtk.gdk.CONTROL_MASK|gtk.gdk.SHIFT_MASK)))):
            self.pending_event = [x, y]
            selection.set_select_function(lambda *args: False)
        elif event.type == gtk.gdk.BUTTON_PRESS:
            self.pending_event = None
            selection.set_select_function(lambda *args: True)

    def button_release(self, inst, event):
        if self.pending_event:
            selection = family_tv.get_selection()
            selection.set_select_function(lambda *args: True)
            oldevent = self.pending_event
            self.pending_event = None
            if oldevent != [event.x, event.y]: 
                return True
            x, y = map(int, [event.x, event.y])
            try: 
                path, col, cellx, celly = family_tv.get_path_at_pos(x, y)
            except TypeError: 
                return True
            family_tv.set_cursor(path, col, 0)
    
    # this is strictly cosmetic
    # XXX todo --> make this nice instead of just a stock icon
    def begin_drag(self, widget, context):
        #model, paths = family_tv.get_selection().get_selected_rows()
        #max = 1
        # if dragging more than one row, change drag icon
        #if len(paths) > max:
        context.set_icon_stock(gtk.STOCK_ADD, 22, 22)
        

# this one controls re-ordering for the collections tree
# and handles multiple drops from the fonts treeview
    def drag_data_received(self, treeview, context, x, y, 
                selection, info, timestamp):

        drop_info = treeview.get_dest_row_at_pos(x, y)
        # need this path before it changes
        drop_list = (drop_info)
        sf = family_tv.get_selection().get_selected_rows()
        font_model, p = sf
        treeselection = treeview.get_selection()
        model, iter = treeselection.get_selected()
        sc0 = model.get_value(iter, 0)
        sc1 = model.get_value(iter, 1)
        sc2 = model.get_value(iter, 2)
        sc = (sc0, sc1, sc2)
        if drop_info:
            path, position = drop_info
            collection = model[path][1]
            
        orphans = collection_ls[3][1]
            
        try:
            # if user attempts to re-order built-in collections, do nothing 
            if sc2 != 'All Fonts' \
            and sc2 != 'System' \
            and sc2 != 'User' \
            and sc2 != 'Orphans':
                if p == [] and drop_info:
                    path, position = drop_info
                    iter = model.get_iter(path)
                    if path == (0,) \
                    or path == (1,) \
                    or path == (2,) \
                    or path == (3,):
                        return
                    if (position == gtk.TREE_VIEW_DROP_BEFORE
                        or position == gtk.TREE_VIEW_DROP_INTO_OR_BEFORE):
                        model.insert_before(iter, sc)
                    else:
                        model.insert_after(iter, sc)
                else:
                    model.append(sc)
                # no dups
                if context.action == gtk.gdk.ACTION_MOVE:
                    context.finish(True, True, timestamp)
            # handle drops from fonts tree
            if p != [] and drop_info:
                selected_collection, info_we_dont_care_about = drop_list
                path, position = drop_info
                # if user drags fonts into default collections, do nothing
                if selected_collection == (0,) or \
                selected_collection == (1,) or \
                selected_collection == (2,) or \
                selected_collection == (3,):
                    logging.info("Built-in collections cannot be modified")
                    return
                for path in p:
                    object = font_model[path][1]
                    collection.add(object)
                    try:
                        orphans.remove(object)
                    except:
                        pass
                collection_tv.get_selection().select_path(selected_collection)
                self.update_views()
            elif p[0] == (0,) or p[0] == (1,) or p[0] == (2,) or p[0] == (3,):
                logging.info("Built-in collections cannot be modified")
        except:
            pass

    # this function handles treeview events ( double clicks, enter key )
    def font_activated(self, tv, path, col):
        for f in self.iter_selected_fonts():
            f.enabled = (not f.enabled)
        self.update_views()
        
        
# Updates ----------------------------------------------------------- #


    def update_views(self):
        self.update_collection_view()
        self.update_font_view()

    def update_collection_view(self):
        for c in collections:
            c.set_enabled_from_fonts()

        model = collection_tv.get_model()
        iter = model.get_iter_first()
        while iter:
            label, obj = model.get(iter, 0, 1)
            if not obj:
                iter = model.iter_next(iter)
                continue
            if obj in collections:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(iter, 0, new_label)
                iter = model.iter_next(iter)
            else: 
                if not model.remove(iter): return

    def update_font_view(self):
        c = C.get_current_collection()
        model = family_tv.get_model()
        iter = model.get_iter_first()
        while iter:
            label, obj = model.get(iter, 0, 1)
            if obj in c.fonts:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(iter, 0, new_label)
                iter = model.iter_next(iter)
            else: 
                if not model.remove(iter): return

    def set_preview_text(self, descr, update_custom=True):
        if update_custom and self.preview_mode == 1:
            self.custom_text = self.get_current_text()
        self.text_view.set_editable(self.preview_mode == 1)
        b = self.text_view.get_buffer()
        b.set_text("", 0)
        for tag in self.font_tags:
            b.get_tag_table().remove(tag)
        self.font_tags = []
        # create font
        size = self.size
        if self.preview_mode == 2:
            tag = b.create_tag(None, size_points=size)
        else: 
            tag = b.create_tag(None, font_desc=descr, size_points=size)
        self.font_tags.append(tag)
        if self.preview_mode == 0:
            b.insert_with_tags(b.get_end_iter(), descr.to_string() + "\n", tag)
            b.insert_with_tags(b.get_end_iter(), TEST_TEXT + "\n", tag)
            self.style_combo.set_sensitive(True)
        elif self.preview_mode == 1:
            b.insert_with_tags(b.get_end_iter(), self.custom_text, tag)
            self.style_combo.set_sensitive(True)          
        elif self.preview_mode == 2:
            text = self.get_font_details_text(self.current_font.family)
            b.insert_with_tags(b.get_end_iter(), text, tag)
            self.style_combo.set_sensitive(False)
        self.current_descr = descr
        
    def preview_mode_changed(self, widget, b):
        if self.preview_mode == 1:
            self.custom_text = self.get_current_text()
        self.preview_mode = b
        self.set_preview_text(self.current_descr, False)
	
    def get_current_text(self):
        b = self.text_view.get_buffer()
        return b.get_text(b.get_start_iter(), b.get_end_iter())

    def font_changed(self, sel):
        tv = family_tv
        m, path_list = tv.get_selection().get_selected_rows()
        rows = len(path_list)
        if rows == 0:
            self.font_info.set_sensitive(False)
            return
        if rows > 1:
            self.font_info.set_sensitive(False)
            return
        self.font_info.set_sensitive(True)
        obj = m[path_list[0]][1]
        if isinstance(obj, Family):
            self.change_font(obj)

    def style_changed(self, widget):
        combo = self.style_combo
        if combo.get_active() < 0:
            return
        style = combo.get_model()[combo.get_active()][0]
        faces = self.current_font.pango_family.list_faces()
        for face in faces:
            if face.get_face_name() == style:
                descr = face.describe()
                self.set_preview_text(descr)
                return

    def change_font(self, font):
        self.current_font = font
        self.style_combo.get_model().clear()
        faces = font.pango_family.list_faces()
        selected_face = None
        active = -1
        i = 0
        for face in faces:
            name = face.get_face_name()
            self.style_combo.append_text(name)
            if name in DEFAULT_STYLES or not selected_face:
                selected_face = face
                active = i
            i += 1
        self.style_combo.set_active(active)
        self.set_preview_text(selected_face.describe())

    def get_current_size(self):
        i = self.size
        if i <= 0.0: return 12
        else: return i

    def iter_selected_fonts(self):
        selected_fonts = family_tv.get_selection().get_selected_rows()
        model, path_list = selected_fonts
        for path in path_list:
            object = model[path][1]
            yield object

    def get_font_details_text(self, family):
        from fontload import g_font_files
        filenames = g_font_files.get(family, None)
        str = "%s\n\n" % family

        if not filenames: str += _("Could not load Font Information")
        else:
            for f in filenames:
                st = os.stat(f)
                str += "%s %d KB\n" % (f, st.st_size / 1024)
        str += _("""
                
For more detailed font information:

Please install gnome-font-viewer

gnome-font-viewer is part of gnome-control-center

Install it through your distributions software manager

or get it from :

http://ftp.gnome.org/pub/GNOME/sources/fontilus/

""")

        return str


# -------------------------------------------------------------------- #  
    
def quit(widget):
    logging.info("Saving configuration")
    C.save_collection()
    xmlconf.check_libxml2_leak()
    logging.info("Exiting...")
    gtk.main_quit()
