#!/usr/bin/env python
import gtk
import gobject
import os
import pango
import subprocess
import libxml2
from os.path import exists

# Font Manager
# (C) 2008 Karl Pickett
# License: GPLv3

# for future I18n
def _(str):
    return unicode(str)

# To install ourselves, we add an include line in the 
# user font config file (default ~/.fonts.conf)
USER_FONT_CONF = "~/.fonts.conf"
USER_FONT_CONF_BACKUP = "~/.fonts.conf.fontmanager.save"

VERSION =       "0.5"
PRODUCT_TITLE = _("Font Manager %s") % VERSION

FM_DIR =                "~/.fontmanager"
FM_BLOCK_CONF =         os.path.join(FM_DIR, "fontmanager.conf")
FM_BLOCK_CONF_TMP =     FM_BLOCK_CONF + ".tmp"
FM_GROUP_CONF =         os.path.join(FM_DIR, "groups.xml")

FC_INCLUDE_LINE = "<include ignore_missing=\"yes\">%s</include>" % \
                        FM_BLOCK_CONF

TEST_TEXT =     _("The Hungry Penguin Ate A Big Fish")
TEST_TEXT +=     _("\nABCDEFGHIJKLMNOPQRSTUVWXYZ")
TEST_TEXT +=     _("\n1234567890")
TEST_TEXT +=     _("\nabcdefghijklmnopqrstuvwxyz")

DEFAULT_CUSTOM_TEXT = _("Enter Your Text Here")

SCALABLE_SIZES = (200, 150, 100, 72, 48, 36, 24, 18, 14, 12, 10)

# What style gets shown first
DEFAULT_STYLES = ["Regular", "Roman", "Medium", "Normal", "Book"]


UI_XML = """
<ui>
<menubar name="MenuBar">
    <menu action="File">
      <menuitem action="Save"/>
      <separator/>
      <menuitem action="Quit"/>
    </menu>
    <menu action="Collection">
      <menuitem action="NewCollection"/>
      <menuitem action="RenameCollection"/>
      <separator/>
      <menuitem action="DeleteCollection"/>
      <separator/>
      <menuitem action="TurnOnCollection"/>
      <menuitem action="TurnOffCollection"/>
    </menu>
    <menu action="Font">
      <menuitem action="Copy"/>
      <menuitem action="Cut"/>
      <menuitem action="Paste"/>
      <menuitem action="Remove"/>
      <separator/>
      <menuitem action="TurnOn"/>
      <menuitem action="TurnOff"/>
    </menu>
    <menu action="View">
      <menuitem action="ViewSample"/>
      <menuitem action="ViewCustom"/>
      <separator/>
      <menuitem action="ViewDetails"/>
    </menu>
    <menu action="Help">
      <menuitem action="About"/>
    </menu>
</menubar>
</ui>
"""

# Some globals
# Names of system font families as reported by fc-list
g_system_families = {}
# map of family to list of filenames
g_font_files = {}
# map of namily name to Family object
g_fonts = {}


class Pattern(object):
    __slots__ = ("family", "style")

    def __init__(self):
        self.family = self.style = None

class Collection (object):
    __slots__ = ("name", "fonts", "builtin", "enabled")

    def __init__(self, name):
        self.name = name
        self.fonts = []
        self.builtin = True
        self.enabled = True

    def get_label(self):
        if self.enabled:
            return on(self.name)
        else:
            return off(self.name)

    def obj_exists(self, obj):
        for f in self.fonts:
            if f is obj:
                return True
        return False
        
    def add(self, obj):
        # check duplicate reference
        if self.obj_exists(obj):
            return
        self.fonts.append(obj)

    def get_text(self):
        return self.name

    def num_fonts_enabled(self):
        ret = 0
        for f in self.fonts:
            if f.enabled:
                ret += 1
        return ret

    def set_enabled(self, enabled):
        for f in self.fonts:
            f.enabled = enabled

    def set_enabled_from_fonts(self):
        self.enabled = (self.num_fonts_enabled() > 0)

    def remove(self, font):
        self.fonts.remove(font)


class Family(object):
    __slots__ = ("family", "user", "enabled", "pango_family")

    def __init__(self, family):
        self.family = family
        self.user = False
        self.enabled = True
        self.pango_family = None

    def get_label(self):
        if self.enabled:
            return on(self.family)
        else:
            return off(self.family)

    def cmp_family(lhs, rhs):
        return cmp(lhs.family, rhs.family)


# XML Helpers
def add_patelt_node(parent, type, val):
    pi = parent.newChild(None, "patelt", None)
    pi.setProp("name", type)
    str = pi.newChild(None, "string", val)

def get_fontconfig_patterns(node, patterns):
    for n in node.xpathEval('pattern'):
        p = Pattern()
        for c in n.xpathEval('patelt'):
            name = c.prop("name")
            if name == "family":
                p.family = c.xpathEval('string')[0].content
        if p.family:
            patterns.append(p)



def gtk_markup_escape(str):
    str = str.replace("&", "&amp;")
    str = str.replace("<", "&lt;")
    str = str.replace(">", "&gt;")
    return str

def on(str):
    str = gtk_markup_escape(str)
    return "<span weight='heavy'>%s</span>" % str

def off(str):
    str = gtk_markup_escape(str)
    return "<span weight='ultralight'>%s Off</span>" % str



# Font loading
def strip_fontconfig_family(family):
    # remove alt name
    n = family.find(',')
    if n > 0:
        family = family[:n]
    family = family.replace("\\-", "-")
    family = family.strip()
    return family

def load_fontconfig_files():
    cmd = "fc-list : file family"
    for l in os.popen(cmd).readlines():
        l = l.strip()
        if l.find(":") < 0:
            continue
        file, family = l.split(":")
        family = strip_fontconfig_family(family)
        list = g_font_files.get(family, None)
        if not list:
            list = []
            g_font_files[family] = list
        list.append(file)

def load_fontconfig_system_families():
    cmd = "HOME= fc-list : family"
    print "Executing %s..." % cmd
    for l in os.popen(cmd).readlines():
        l = l.strip()
        family = strip_fontconfig_family(l)
        g_system_families[family] = 1


def load_fonts(widget):
    ctx = widget.get_pango_context()
    families = ctx.list_families()
    for f in families:
        obj = Family(f.get_name())
        obj.pango_family = f
        if not g_system_families.has_key(f.get_name()):
            obj.user = True
        g_fonts[f.get_name()] = obj

def find_font(family):
    return g_fonts.get(family, None)
    

# Blacklist Code
def save_blacklist():
    doc = libxml2.newDoc("1.0")
    root = doc.newChild(None, "fontconfig", None)
    n = root.newChild(None, "selectfont", None)
    n = n.newChild(None, "rejectfont", None)

    for font in g_fonts.itervalues():
        if not font.enabled: 
            p = n.newChild(None, "pattern", None)
            add_patelt_node(p, "family", font.family)

    print "Writing to %s" % FM_BLOCK_CONF
    doc.saveFormatFile(FM_BLOCK_CONF, format=1)


def load_blacklist(filename):
    if not exists(filename):
        return 

    patterns = []
    doc = libxml2.parseFile(filename)
    rejects = doc.xpathEval('//rejectfont')
    for a in rejects:
        get_fontconfig_patterns(a, patterns)
    doc.freeDoc()

    for p in patterns:
        set_blacklist(p)

def set_blacklist(pattern):
    font = find_font(pattern.family)
    if font:
        font.enabled = False

def enable_blacklist():
    if exists(FM_BLOCK_CONF_TMP):
        if exists(FM_BLOCK_CONF):
            os.unlink(FM_BLOCK_CONF)
        os.rename(FM_BLOCK_CONF_TMP, FM_BLOCK_CONF)

def disable_blacklist():
    if exists(FM_BLOCK_CONF):
        if exists(FM_BLOCK_CONF_TMP):
            os.unlink(FM_BLOCK_CONF_TMP)
        os.rename(FM_BLOCK_CONF, FM_BLOCK_CONF_TMP)

def get_filenames(family):
    ret = []
    try:
        pipe = subprocess.Popen(["fc-list", family, "file"],
                stdout=subprocess.PIPE).stdout
        for line in pipe:
            ret.append(line.split(':')[0].strip())
    except Exception, e:
        print e
    return ret

# Details dialog
def get_font_details_text(family):
    filenames = g_font_files.get(family, None)
    str = "%s\n\n" % family

    if not filenames:
        str += "No Files Found"
    else:
        for f in filenames:
            st = os.stat(f)
            str += "%s %d KB\n" % (f, st.st_size / 1024)

    return str



#
# Gui Code
#
class FontBook(gtk.Window):
    def __init__(self, parent=None):
        gtk.Window.__init__(self)
        self.connect('destroy', lambda *w: self.action_quit(None))

        self.uimanager = gtk.UIManager()
        accelgroup = self.uimanager.get_accel_group()
        self.add_accel_group(accelgroup)

        self.create_actions()

        vb = gtk.VBox(False, 0)
        vb.pack_start(self.menu_bar, False, False, 0)

        self.DRAG_TARGETS = [("test", gtk.TARGET_SAME_APP, 0)] 
        self.DRAG_ACTIONS = gtk.gdk.ACTION_LINK

        self.set_title(PRODUCT_TITLE)
        self.set_default_size(700, 450)
        #self.set_border_width(8)

        hbox = gtk.HBox(False, 3)
        hbox.set_homogeneous(False)

        w = self.init_collections()
        hbox.pack_start(w, False)
        w = self.init_families()
        hbox.pack_start(w, False)
        w = self.init_text_view()
        hbox.pack_start(w)

        self.copy_buffer = []
        self.font_tags = []

        self.custom_text = DEFAULT_CUSTOM_TEXT
        self.preview_mode = 0

        load_fontconfig_system_families()
        load_fontconfig_files()
        load_fonts(self)
        load_blacklist(FM_BLOCK_CONF_TMP)

        vb.pack_start(hbox)
        self.add(vb)
        self.create_collections()
        #self.show_collection(self.collections[0])
        self.collection_tv.get_selection().select_path(0)
        self.family_tv.get_selection().select_path(0)
        self.show_all()


    def init_collections(self):
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)

        model = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT, 
                gobject.TYPE_STRING)

        treeview = gtk.TreeView(model)
        treeview.set_search_column(2)
        treeview.get_selection().connect("changed", self.collection_changed)

        #dnd
        treeview.connect("drag-data-received", self.drag_data_received)
        treeview.enable_model_drag_dest(self.DRAG_TARGETS, self.DRAG_ACTIONS)
        treeview.connect("row-activated", self.collection_activated)
        treeview.set_row_separator_func(self.is_row_separator_collection)

        r = gtk.CellRendererText()
        column = gtk.TreeViewColumn(_('Collection'), r, markup=0)

        #column.set_sort_column_id(0)
        treeview.append_column(column)

        self.collection_tv = treeview
        sw.add(treeview)
        return sw


    def init_families(self):
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)

        model = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT, 
                gobject.TYPE_STRING)

        treeview = gtk.TreeView(model)
        treeview.set_search_column(2)
        treeview.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        treeview.get_selection().connect("changed", self.font_changed)
        treeview.connect("row-activated", self.font_activated)

        # dnd
        #treeview.connect("drag-data-get", self.drag_data_get)
        treeview.enable_model_drag_source(gtk.gdk.BUTTON1_MASK, 
                self.DRAG_TARGETS, self.DRAG_ACTIONS)

        column = gtk.TreeViewColumn(_('Font'), gtk.CellRendererText(), 
                markup=0)
        column.set_sort_column_id(2)
        treeview.append_column(column)

        self.family_tv = treeview
        sw.add(treeview)
        return sw


    def init_text_view(self):
        #self.notebook = gtk.Notebook()

        view = gtk.TextView()
        sw = gtk.ScrolledWindow()
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        self.text_view = view
        self.text_view.set_left_margin(8)
        self.text_view.set_right_margin(8)
        self.text_view.set_wrap_mode(gtk.WRAP_WORD_CHAR)
        sw.add(view)


        #self.font_label = gtk.Label(_("Preview"))
        self.style_combo = gtk.combo_box_new_text()
        self.size_combo = gtk.combo_box_new_text()
        vb = gtk.VBox()
        hb = gtk.HBox()
        vb.pack_start(hb, False)
        vb.pack_start(sw)
        #hb.pack_start(self.font_label, False)
        hb.pack_end(self.style_combo, False)
        hb.pack_end(self.size_combo, False)
        self.set_scalable_sizes()
        self.style_combo.connect("changed", self.style_changed)
        self.size_combo.connect("changed", self.size_changed)

        return vb


    def create_actions(self):
        g = gtk.ActionGroup('global')

        add_action(g, "File", None, "_File", None)
        add_action(g, 'Collection', None, "_Collection", None)
        add_action(g, 'Font', None, "Font", None)
        add_action(g, 'View', None, "_View", None)
        add_action(g, 'Help', None, "_Help", None)

        add_action(g, 'Quit', gtk.STOCK_QUIT, None,
                self.action_quit)
        add_action(g, 'Save', gtk.STOCK_SAVE, None,
            self.action_save)

        add_action(g, 'NewCollection', gtk.STOCK_NEW, "_New Collection",
            self.action_new_collection)

        add_action(g, 'About', gtk.STOCK_ABOUT, None,
            self.action_about)
        self.uimanager.insert_action_group(g, 0)

        # view
        g.add_radio_actions([
            ('ViewSample', None, "_Sample Text", "<Control>1", None, 0),
            ('ViewCustom', None, "_Custom Text", "<Control>2", None, 1),
            ('ViewDetails', None, "_Font Information", "<Control>3", None, 2),
            ], 0, self.preview_mode_changed)


        # any collection selected
        g = gtk.ActionGroup('collection_selected')
        g.set_sensitive(False)
        add_action(g, 'TurnOnCollection', None, "_Enable Collection",
            self.action_turn_on_collection)
        add_action(g, 'TurnOffCollection', None, "_Disable Collection",
            self.action_turn_off_collection)
        self.uimanager.insert_action_group(g, 0)
        self.ag_collection_selected = g


        # user collection selected
        g = gtk.ActionGroup('user-collection_selected')
        g.set_sensitive(False)
        add_action(g, 'DeleteCollection', None, "Delete Collection",
            self.action_delete_collection, "<Ctrl>d")
        add_action(g, 'RenameCollection', None, "Rename Collection",
            self.action_rename_collection, "<Ctrl>r")
        self.uimanager.insert_action_group(g, 0)
        self.ag_user_collection_selected = g

        g = gtk.ActionGroup('ag-paste')
        g.set_sensitive(False)
        add_action(g, 'Paste', gtk.STOCK_PASTE, None,
            self.action_paste)
        self.ag_paste = g
        self.uimanager.insert_action_group(g, 0)

        g = gtk.ActionGroup('ag-cut')
        g.set_sensitive(False)
        add_action(g, 'Cut', gtk.STOCK_CUT, None,
            self.action_cut)
        add_action(g, 'Remove', gtk.STOCK_DELETE, "Remove",
            self.action_remove)
        self.ag_cut = g
        self.uimanager.insert_action_group(g, 0)

        # font selected
        g = gtk.ActionGroup('font_selected')
        g.set_sensitive(False)
        add_action(g, 'TurnOn', None, "_Enable Font(s)",
            self.action_turn_on)
        add_action(g, 'TurnOff', None, "_Disable Font(s)",
            self.action_turn_off)
        add_action(g, 'Copy', gtk.STOCK_COPY, None,
            self.action_copy)
        self.ag_font_selected = g
        self.uimanager.insert_action_group(g, 0)

        self.uimanager.add_ui_from_string(UI_XML)
        self.menu_bar = self.uimanager.get_widget('/MenuBar')



    #
    # Actions
    #
    def action_save(self, a):
        self.save_config()

    def action_quit(self, a):
        self.save_config()
        gtk.main_quit()

    def collection_name_exists(self, name):
        for c in self.collections:
            if c.name == name:
                return True
        return False

    def action_new_collection(self, a):
        str = _("New Collection")
        while True:
            str = self.get_new_collection_name(str)
            if not str:
                return
            if not self.collection_name_exists(str):
                break
        c = Collection(str)
        c.builtin = False
        self.add_collection(c)
        
    def action_delete_collection(self, a):
        c = self.get_current_collection()
        self.ag_paste.set_sensitive(False)
        self.ag_collection_selected.set_sensitive(False)
        self.collections.remove(c)
        self.update_views()

    def action_rename_collection(self, a):
        c = self.get_current_collection()
        str = c.name
        while True:
            str = self.get_new_collection_name(str)
            if not str or c.name == str:
                return
            if not self.collection_name_exists(str):
                c.name = str
                self.update_collection_view()
                return

    def action_about(self, a):
        d = gtk.AboutDialog()
        d.set_name(PRODUCT_TITLE)
        d.set_copyright("2008 Karl Pickett/penguindev")
        d.set_license("GPL3")
        d.set_website("http://fontmanager.blogspot.com/")
        d.run()
        d.destroy()

    def action_turn_on_collection(self, a):
        self.enable_collection(True)

    def action_turn_off_collection(self, a):
        self.enable_collection(False)

    def collection_activated(self, tv, path, col):
        c = self.get_current_collection()
        self.enable_collection(not c.enabled)

    def enable_collection(self, enabled):
        c = self.get_current_collection()
        if c.builtin and not self.confirm_enable_collection(enabled):
            return
        c.set_enabled(enabled)
        self.update_views()

    def confirm_enable_collection(self, enabled):
        d = gtk.Dialog(_("Confirm Action"), 
                self, gtk.DIALOG_MODAL,
                (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                    gtk.STOCK_OK, gtk.RESPONSE_OK))
        d.set_default_response(gtk.RESPONSE_CANCEL)

        c = self.get_current_collection()
        if enabled:
            str = _("Are you sure you want to enable the \"%s\" built in collection?") % c.name
        else:
            str = _("Are you sure you want to disable the \"%s\" built in collection?") % c.name

        text = gtk.Label()
        text.set_text(str)
        d.vbox.pack_start(text, padding=10)
        text.show()

        ret = d.run()
        d.destroy()
        return (ret == gtk.RESPONSE_OK)


    def is_row_separator_collection(self, model, iter):
        obj = model.get(iter, 1)[0]
        #print "is_row_separator_collection", obj, iter
        return (obj is None)


    # Cut and paste
    def action_remove(self, a):
        c = self.get_current_collection()
        for f in self.iter_selected_fonts():
            c.remove(f)
        self.update_views()

    def action_cut(self, a):
        self.do_copy(True)

    def action_copy(self, a):
        self.do_copy(False)

    def action_paste(self, a):
        c = self.get_current_collection()
        for f in self.copy_buffer:
            if not c.obj_exists(f):
                c.add(f)
                self.add_font_to_view(f)
        self.update_views()

    def do_copy(self, cut):
        c = self.get_current_collection()
        self.copy_buffer = []

        for f in self.iter_selected_fonts():
            self.copy_buffer.append(f)
            if cut:
                c.remove(f)

        self.update_views()

        if not c.builtin:
            self.ag_paste.set_sensitive(True)


    def iter_selected_fonts(self):
        sel = self.family_tv.get_selection()
        m, path_list = sel.get_selected_rows()
        for p in path_list:
            obj = m[p][1]
            yield obj

    def action_turn_on(self, a):
        for f in self.iter_selected_fonts():
            f.enabled = True
        self.update_views()

    def action_turn_off(self, a):
        for f in self.iter_selected_fonts():
            f.enabled = False
        self.update_views()

    def font_activated(self, tv, path, col):
        for f in self.iter_selected_fonts():
            f.enabled = (not f.enabled)
        self.update_views()

    #
    # View Updating
    #
    def update_views(self):
        self.update_collection_view()
        self.update_font_view()

    def update_collection_view(self):
        for c in self.collections:
            c.set_enabled_from_fonts()

        model = self.collection_tv.get_model()
        iter = model.get_iter_first()
        while iter:
            label, obj = model.get(iter, 0, 1)
            if not obj:
                iter = model.iter_next(iter)
                continue
            if obj in self.collections:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(iter, 0, new_label)
                iter = model.iter_next(iter)
            else:
                if not model.remove(iter):
                    return

    def update_font_view(self):
        c = self.get_current_collection()
        model = self.family_tv.get_model()
        iter = model.get_iter_first()
        while iter:
            label, obj = model.get(iter, 0, 1)
            if obj in c.fonts:
                new_label = obj.get_label()
                if label != new_label:
                    model.set(iter, 0, new_label)
                iter = model.iter_next(iter)
            else:
                if not model.remove(iter):
                    return

    def preview_mode_changed(self, a, b):
        if self.preview_mode == 1:
            self.custom_text = self.get_current_text()

        self.preview_mode = a.get_current_value()
        combos_visible = (self.preview_mode != 2)
        self.size_combo.set_property("visible", combos_visible)
        self.style_combo.set_property("visible", combos_visible)
        self.set_preview_text(self.current_descr, False)

    def get_current_text(self):
        print "get_current_text"
        b = self.text_view.get_buffer()
        return b.get_text(b.get_start_iter(), b.get_end_iter())


    def get_current_collection(self):
        sel = self.collection_tv.get_selection()
        m, iter = sel.get_selected()
        if not iter:
            return
        return m.get(iter, 1)[0]

    def collection_changed(self, sel):
        c = self.get_current_collection()
        if c:
            print "collection_changed", c.name
            self.ag_user_collection_selected.set_sensitive(not c.builtin)
            self.ag_collection_selected.set_sensitive(True)
            if c.builtin:
                self.ag_paste.set_sensitive(False)
            elif self.copy_buffer:
                self.ag_paste.set_sensitive(True)
            self.show_collection(c)
        else:
            self.ag_user_collection_selected.set_sensitive(False)
            self.ag_collection_selected.set_sensitive(False)

            self.show_collection(None)

    def font_changed(self, sel):
        tv = self.family_tv
        m, path_list = tv.get_selection().get_selected_rows()
        rows = len(path_list)
        if rows == 0:
            self.ag_font_selected.set_sensitive(False)
            self.ag_cut.set_sensitive(False)
            return

        if not self.get_current_collection().builtin:
            self.ag_cut.set_sensitive(True)

        self.ag_font_selected.set_sensitive(True)
        if rows > 1:
            return

        obj = m[path_list[0]][1]
        if isinstance(obj, Family):
            #print "family changed", f.family
            self.change_font(obj)

    def get_new_collection_name(self, old_name):
        d = gtk.Dialog(_("Enter Collection Name"), 
                self, gtk.DIALOG_MODAL,
                (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                    gtk.STOCK_OK, gtk.RESPONSE_OK))
        d.set_default_response(gtk.RESPONSE_OK)

        text = gtk.Entry()
        if old_name:
            text.set_text(old_name)
        text.set_property("activates-default", True)
        d.vbox.pack_start(text)
        text.show()

        ret = d.run()
        d.destroy()
        if ret == gtk.RESPONSE_OK:
            return text.get_text().strip()
        return None


    # DND Stuff
    def drag_data_received(self, treeview, context, x, y, 
                selection, info, timestamp):
        #print "drag_data_received"
        drop_info = treeview.get_dest_row_at_pos(x, y)
        #print drop_info
        if drop_info:
            model = treeview.get_model()
            path, position = drop_info

            collection = model[path][1]
            collection.add(self.get_dragged_font())

        self.update_views()


    # GTK only supports dragging a single row? :(
    def get_dragged_font(self):
        for f in self.iter_selected_fonts():
            return f


    def save_config(self):
        if not is_installed():
            install()
        save_blacklist()
        self.save_collection()

    def save_collection(self):
        doc = libxml2.newDoc("1.0")
        root = doc.newChild(None, "fontmanager", None)
        for c in self.collections:
            if c.builtin:
                continue
            cn = root.newChild(None, "fontcollection", None)
            cn.setProp("name", c.name)
            for f in c.fonts:
                p = cn.newChild(None, "pattern", None)
                add_patelt_node(p, "family", f.family)

        doc.saveFormatFile(FM_GROUP_CONF, format=1)


    def create_collections(self):
        self.collections = []

        c = Collection(_("All Fonts"))
        for f in sorted(g_fonts.itervalues(), Family.cmp_family):
            c.fonts.append(f)
        self.add_collection(c)

        c = Collection(_("System"))
        for f in sorted(g_fonts.itervalues(), Family.cmp_family):
            if not f.user:
                c.fonts.append(f)
        self.add_collection(c)

        c = Collection(_("User"))
        for f in sorted(g_fonts.itervalues(), Family.cmp_family):
            if f.user:
                c.fonts.append(f)
        self.add_collection(c)

        # add separator - hack
        lstore = self.collection_tv.get_model()
        iter = lstore.append()
        lstore.set(iter, 1, None)

        self.load_user_collections()


    def add_collection(self, c):
        c.set_enabled_from_fonts()
        lstore = self.collection_tv.get_model()
        iter = lstore.append()
        lstore.set(iter, 0, c.get_label())
        lstore.set(iter, 1, c)
        lstore.set(iter, 2, c.get_text())
        self.collections.append(c)

    def load_user_collections(self):
        if not exists(FM_GROUP_CONF):
            return
        doc = libxml2.parseFile(FM_GROUP_CONF)
        nodes = doc.xpathEval('//fontcollection')
        for a in nodes:
            patterns = []
            name = a.prop("name")
            get_fontconfig_patterns(a, patterns)

            c = Collection(name)
            c.builtin = False
            for p in patterns:
                font = find_font(p.family)
                if font:
                    c.fonts.append(font)

            self.add_collection(c)
            print "Loaded user collection %s" % name

        doc.freeDoc()

    def size_changed(self, combo):
        if combo.get_active() < 0:
            return
        self.change_font(self.current_font)


    def style_changed(self, combo):
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
        i = self.size_combo.get_active()
        if i < 0:
            return 14
        model = self.size_combo.get_model()
        str = model[i][0]
        return int(str)

    def set_scalable_sizes(self):
        for size in SCALABLE_SIZES:
            self.size_combo.append_text(str(size))
        self.size_combo.set_active(6)

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
        if self.preview_mode == 2:
            size = 14
            tag = b.create_tag(None, size_points=size)
        else:
            size = self.get_current_size()
            tag = b.create_tag(None, font_desc=descr, size_points=size)
        self.font_tags.append(tag)

        if self.preview_mode == 0:
            b.insert_with_tags(b.get_end_iter(), descr.to_string() + "\n", tag)
            b.insert_with_tags(b.get_end_iter(), TEST_TEXT + "\n", tag)
        elif self.preview_mode == 1:
            b.insert_with_tags(b.get_end_iter(), self.custom_text, tag)
        else:
            text = get_font_details_text(self.current_font.family)
            b.insert_with_tags(b.get_end_iter(), text, tag)

        self.current_descr = descr




    def show_collection(self, c):
        lstore = self.family_tv.get_model()
        lstore.clear()

        if not c:
            return

        for f in c.fonts:
            self.add_font_to_view(f)

    def add_font_to_view(self, f):
        lstore = self.family_tv.get_model()
        iter = lstore.append(None)
        lstore.set(iter, 0, f.get_label())
        lstore.set(iter, 1, f) 
        lstore.set(iter, 2, f.family) 


def add_action(g, action, stock, label, cb, accel=None):
    g.add_actions([(action, stock, label, accel, None, cb)])


def is_installed():
    if not exists(USER_FONT_CONF):
        print "User conf file %s does not exist" % USER_FONT_CONF
        return False

    for l in open(USER_FONT_CONF):
        if l.strip() == FC_INCLUDE_LINE:
            print "Include exists in %s" % USER_FONT_CONF 
            return True
    print "Include does not exist in %s" % USER_FONT_CONF
    return False

# put an include into ~/.fonts.conf
def install():
    if not exists(USER_FONT_CONF):
        print "Making empty user conf file %s" % USER_FONT_CONF
        f = open(USER_FONT_CONF, "w")
        f.write("<fontconfig>\n</fontconfig>\n")
        f.close()

    tmpname = USER_FONT_CONF + ".fontmanager.tmp"
    print "Starting install, adding %s to %s" % (FC_INCLUDE_LINE, USER_FONT_CONF)
    print "Backup will be saved as %s" % USER_FONT_CONF_BACKUP
    tmp = open(tmpname, "w")
    for l in open(USER_FONT_CONF):
        if l.strip() == "</fontconfig>":
            tmp.write(FC_INCLUDE_LINE + "\n")
        tmp.write(l)

    print "Saving backup %s" % USER_FONT_CONF_BACKUP
    os.rename(USER_FONT_CONF, USER_FONT_CONF_BACKUP)
    print "Overwriting %s" % USER_FONT_CONF
    os.rename(tmpname, USER_FONT_CONF)



def update_home(path):
    return path.replace("~", os.getenv("HOME"))

def main():
    if not exists(FM_DIR):
        print "Creating %s" % (FM_DIR)
        os.mkdir(FM_DIR)

    print "Disabling blacklist temporarily..."
    disable_blacklist()

    f = FontBook()

    print "Reenabling blacklist"
    enable_blacklist()

    gtk.main()

if __name__ == '__main__':
    FM_DIR = update_home(FM_DIR)
    FM_BLOCK_CONF = update_home(FM_BLOCK_CONF)
    FM_BLOCK_CONF_TMP = update_home(FM_BLOCK_CONF_TMP)
    FM_GROUP_CONF = update_home(FM_GROUP_CONF)

    USER_FONT_CONF = update_home(USER_FONT_CONF)
    USER_FONT_CONF_BACKUP = update_home(USER_FONT_CONF_BACKUP)
    main()
