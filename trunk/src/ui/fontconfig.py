"""
This module provides a GUI which allows users to manipulate FontConfig settings
for individual families and styles. It also allows defining aliases.
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

# Disable warnings related to gettext
# pylint: disable-msg=E0602
# Disable warnings related to missing docstrings, for now...
# pylint: disable-msg=C0111

import os
import gtk
import gobject
import pango
import cPickle
import shelve
import UserDict

from os.path import exists, join

from constants import CHECKBUTTONS, CONSTS, CONSTS_MAP, DEFAULTS, SKIP, \
                        SLANT, WEIGHT, FC_WIDGETMAP, WIDTH, USER_FONT_CONFIG_DIR
from utils.common import natural_sort
from utils.xmlutils import save_alias_settings, save_fontconfig_settings, \
                            load_alias_settings


CACHE = None

CACHED_SETTINGS = 'settings.cache'

# Most common fonts found on Microsoft and Apple systems,
# at least according to http://www.codestyle.org/
COMMON_FONTS = ('American Typewriter', 'Andale Mono', 'Apple Chancery', 'Arial',
'Arial Black', 'Arial Narrow', 'Arial Rounded MT Bold', 'Arial Unicode MS',
'Baskerville', 'Big Caslon', 'Book Antiqua', 'Bookman Old Style',
'Bradley Hand ITC', 'Brush Script MT', 'Century Gothic', 'Comic Sans MS',
'Copperplate', 'Courier', 'Courier New', 'Didot', 'Estrangelo Edessa',
'Franklin Gothic Medium', 'French Script MT', 'Futura', 'Garamond', 'Gautami',
'Geneva', 'Georgia', 'Gill Sans', 'Haettenschweiler', 'Helvetica',
'Helvetica Neue', 'Herculanum', 'Hiragino Kaku Gothic ProN',
'Hiragino Mincho ProN', 'Hoefler Text', 'Impact', 'Kartika', 'Kristen ITC',
'Latha', 'Lucida Bright', 'Lucida Console', 'Lucida Grande',
'Lucida Sans Unicode', 'MS Reference Sans Serif', 'MV Boli', 'Mangal',
'Marker Felt', 'Microsoft Sans Serif', 'Monaco', 'Monotype Corsiva', 'Optima',
'Palatino', 'Palatino Linotype', 'Papyrus', 'Raavi', 'Shruti', 'Skia',
'Sylfaen', 'Tahoma', 'Tempus Sans ITC', 'Times', 'Times New Roman',
'Trebuchet MS', 'Tunga', 'Verdana', 'Vrinda', 'Zapfino')

DEFAULT_STYLES  =  ['Regular', 'Roman', 'Medium', 'Normal', 'Book']

PREVIEW_TEXT = _("""
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed in enim eros, fringilla volutpat orci. Integer in diam vel lacus posuere rutrum. Aliquam tempor, nunc quis volutpat sodales, elit lorem ultricies quam, nec imperdiet ipsum nisi vel leo. Aenean a venenatis ipsum. Pellentesque fermentum, ligula fringilla tempus facilisis, neque libero tincidunt massa, id lacinia urna erat non enim. Cras a sem purus. Nam sit amet pellentesque lectus. In mattis tortor eget turpis pellentesque et adipiscing ante rhoncus. Phasellus commodo tempor diam, suscipit fringilla orci aliquet id. Ut diam nunc, suscipit eu ultricies a, congue ac erat. Mauris vestibulum, nibh quis tincidunt iaculis, mi magna fermentum urna, vitae aliquet neque libero a eros. Donec at risus eros, sed egestas justo. Morbi placerat, justo eget vulputate blandit, eros ligula vehicula velit, vitae volutpat risus massa quis orci. 
""")

REVERSE = _('Auto-Hint'), _('Hinting')

SCALES = {
            _('Hinting')           :   'HintScale',
            _('LCD Filter')        :   'FilterScale',
            _('Force Spacing')     :   'SpacingScale'
            }

SCALE_LABELS = {
                'HintScale'         :   {
                                        0.0   :   'None',
                                        0.1   :   'Slight',
                                        0.2   :   'Medium',
                                        0.3   :   'Full'
                                        },
                'FilterScale'       :   {
                                        0.0   :   'None',
                                        0.1   :   'Default',
                                        0.2   :   'Light',
                                        0.3   :   'Legacy'
                                        },
                'SpacingScale'      :   {
                                        0.0   :   'Proportional',
                                        0.1   :   'Dual',
                                        0.2   :   'Mono',
                                        0.3   :   'Charcell'
                                        }
                                        }

SCALE_SENSITIVITY = {
                    'HintScale'         :   'hinting',
                    'FilterScale'       :   'lcdfiltering',
                    'SpacingScale'      :   'forcespacing'
                    }

SENSITIVITY = {
                _('Auto-Hint')     :   _('Hinting'),
                _('Hinting')       :   _('Auto-Hint'),
                _('Larger than')   :   'max_size',
                _('Smaller than')  :   'min_size'
                }


class AliasEdit(gtk.Window):
    def __init__(self, parent = None):
        gtk.Window.__init__(self)
        if parent:
            self.set_transient_for(parent)
            self.set_position(gtk.WIN_POS_CENTER_ON_PARENT)
            self.set_destroy_with_parent(True)
        self.set_title(_('Alias Editor'))
        self.aliases = None
        self.widgets = {}
        self.system_families = [f.get_name() for f in CACHE['pango_families']]
        self.all_families = \
        [f for f in sorted(set(COMMON_FONTS + tuple(self.system_families)))]
        self.all_store = gtk.ListStore(gobject.TYPE_STRING)
        for family in natural_sort(self.all_families):
            self.all_store.append([family])
        self.system_store = gtk.ListStore(gobject.TYPE_STRING)
        for family in natural_sort(self.system_families):
            self.system_store.append([family])
        self.set_size_request(500, 350)
        self.set_border_width(12)
        self.alias_tree = self._get_alias_tree()
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        sw.add(self.alias_tree)
        main_box = gtk.HBox()
        main_box.set_spacing(10)
        main_box.pack_start(sw, True, True, 0)
        buttons = self._get_buttons()
        main_box.pack_start(buttons, False, True, 0)
        self.add(main_box)
        self._update_sensitivity(self.alias_tree.get_selection())
        self.load_config()
        self.alias_tree.expand_all()

    def _do_edit(self, renderer, path, new_text):
        model = self.alias_tree.get_model()
        model.set_value(model.get_iter(path), 0, new_text)
        return

    def _get_alias_tree(self):
        store = gtk.TreeStore(gobject.TYPE_STRING)
        tree = gtk.TreeView(store)
        tree.set_headers_visible(False)
        renderer = gtk.CellRendererText()
        renderer.set_property('editable', True)
        renderer.connect('editing-started', self._start_edit)
        renderer.connect('edited', self._do_edit)
        column = gtk.TreeViewColumn('Aliases', renderer, text = 0)
        tree.append_column(column)
        tree.get_selection().connect('changed', self._update_sensitivity)
        return tree

    def _get_buttons(self):
        buttons = {
                    _('Add Alias')          :   self.add_alias,
                    _('Remove Alias')       :   self.del_entry,
                    _('Add Substitute')     :   self.add_sub,
                    _('Remove Substitute')  :   self.del_entry,
                    _('Write configuration'):   self.save_config
                    }
        widgets = {
                    _('Add Alias')          :   'add_alias',
                    _('Remove Alias')       :   'del_alias',
                    _('Add Substitute')     :   'add_sub',
                    _('Remove Substitute')  :   'del_sub',
                    _('Write configuration'):   'save_config'
                    }
        box = gtk.VBox()
        box.set_spacing(10)
        box.set_border_width(10)
        for label in _('Add Alias'), _('Remove Alias'), _('Add Substitute'), \
                    _('Remove Substitute'), _('Write configuration'):
            button = gtk.Button(label)
            button.connect('clicked', buttons[label])
            box.pack_start(button, False, True, 0)
            self.widgets[widgets[label]] = button
        return box

    def _start_edit(self, renderer, editable, path):
        try:
            if isinstance(editable, gtk.Entry):
                completion = gtk.EntryCompletion()
                editable.set_completion(completion)
                if len(path) < 2:
                    completion.set_model(self.all_store)
                else:
                    completion.set_model(self.system_store)
                completion.set_text_column(0)
            return
        except AttributeError:
            return

    def _update_sensitivity(self, treeselection):
        model, treeiter = treeselection.get_selected()
        self.widgets['del_alias'].set_sensitive(False)
        self.widgets['add_sub'].set_sensitive(False)
        self.widgets['del_sub'].set_sensitive(False)
        if treeiter is None:
            return
        path = model.get_path(treeiter)
        if len(path) < 2:
            self.widgets['del_alias'].set_sensitive(True)
            self.widgets['add_sub'].set_sensitive(True)
        else:
            self.widgets['del_sub'].set_sensitive(True)
        return

    def add_alias(self, unused_widget):
        model = self.alias_tree.get_model()
        treeiter = model.append(None, ['Family'])
        path = model.get_path(treeiter)
        column = self.alias_tree.get_column(0)
        self.alias_tree.scroll_to_cell(path, column)
        self.alias_tree.set_cursor(path, column, start_editing=True)
        return

    def add_sub(self, unused_widget):
        selection = self.alias_tree.get_selection()
        model, treeiter = selection.get_selected()
        treeiter = model.append(treeiter, ['Substitute'])
        path = model.get_path(treeiter)
        column = self.alias_tree.get_column(0)
        self.alias_tree.expand_to_path(path)
        self.alias_tree.scroll_to_cell(path, column)
        self.alias_tree.set_cursor(path, column, start_editing=True)
        return

    def del_entry(self, unused_widget):
        selection = self.alias_tree.get_selection()
        model, treeiter = selection.get_selected()
        model.remove(treeiter)
        return

    def load_config(self):
        settings = load_alias_settings()
        if settings:
            for family in settings:
                model = self.alias_tree.get_model()
                treeiter = model.append(None, [family])
                for sub in settings[family]:
                    model.append(treeiter, [sub])
        return

    def save_config(self, unused_widget):
        save_alias_settings(self.alias_tree)
        self.load_config()
        self.alias_tree.expand_all()
        return


class ConfigEdit(gtk.Window): 
    def __init__(self, parent = None):
        gtk.Window.__init__(self)
        self.set_size_request(725, -1)
        self.set_border_width(12)
        self.connect('destroy', self._on_quit)
        self.set_title(_("Advanced Configuration"))
        self.selected_family = None
        self.parent_window = parent
        global CACHE
        CACHE = self.cache = SettingsCache()
        ctx = self.create_pango_context()
        self.cache['pango_families'] = ctx.list_families()
        self._load_cache()
        self.container = gtk.HBox()
        self.preview = SettingsPreview(self)
        self.alias = AliasEdit(self)
        self.alias.connect('delete-event', self._on_quit_aliases)
        self.edit_aliases = None
        SettingsBook.preview = self.preview
        self.preview_toggle = None
        self.preview.connect('delete-event', self._on_quit_preview)
        self.family_tree = self._build_family_tree()
        self._show_self()

    def _build_button_box(self):
        frame = gtk.Notebook()
        frame.set_show_tabs(False)
        box = gtk.HBox()
        box.set_spacing(5)
        box.set_border_width(5)
        self.preview_toggle = gtk.CheckButton(_('Display preview window'))
        self.preview_toggle.connect('clicked', self._preview_toggled)
        self.preview_toggle.set_property('can-focus', False)
        box.pack_start(self.preview_toggle, False, True, 0)
        save_config = gtk.Button(_('Write configuration'))
        save_config.connect('clicked', self.save_settings)
        save_config.set_property('can-focus', False)
        box.pack_end(save_config, False, True, 0)
        discard_config = gtk.Button(_('Discard configuration'))
        discard_config.connect('clicked', self.discard_settings)
        discard_config.set_property('can-focus', False)
        box.pack_end(discard_config, False, True, 0)
        frame.add(box)
        return frame

    def _build_family_tree(self):
        tree = gtk.TreeView()
        model = gtk.ListStore(gobject.TYPE_PYOBJECT, gobject.TYPE_STRING)
        families = CACHE['pango_families']
        for family in families:
            model.append([family,
                        '<span weight="heavy">%s</span>' % family.get_name()])
        tree.set_model(model)
        column = gtk.TreeViewColumn(None, gtk.CellRendererText(), markup=1)
        tree.append_column(column)
        tree.set_headers_visible(False)
        tree.columns_autosize()
        column.set_sort_column_id(1)
        column.clicked()
        tree.set_size_request(200, -1)
        selection = tree.get_selection()
        selection.connect('changed', self._selection_changed)
        selection.select_path(0)
        return tree

    def _edit_aliases(self, unused_widget):
        if self.alias is None:
            self.alias = AliasEdit(self)
            self.alias.connect('delete-event', self._on_quit_aliases)
        if self.alias.get_property('visible'):
            self.alias.destroy()
            self.alias = None
        else:
            self.alias.show_all()
        return

    def _load_cache(self):
        cache = shelve.open(join(USER_FONT_CONFIG_DIR, CACHED_SETTINGS),
                                            protocol=cPickle.HIGHEST_PROTOCOL)
        for family in cache:
            self.cache[family] = cache[family]
        cache.close()
        return

    def _on_quit(self, unused_arg):
        self.save_cache()
        if self.parent_window:
            if self.alias is not None:
                self.alias.destroy()
            self.preview.destroy()
            self.destroy()
            self.parent_window.reload(None)
        else:
            gtk.main_quit()
        return

    def _on_quit_aliases(self, unused_widget, unused_event):
        self.edit_aliases.clicked()
        return

    def _on_quit_preview(self, unused_widget, unused_event):
        self.preview_toggle.set_active(not self.preview_toggle.get_active())
        return True

    def _preview_toggled(self, widget):
        if widget.get_active():
            self.preview.show_all()
        else:
            self.preview.hide()
        return

    def _selection_changed(self, treeselection):
        model, treeiter = treeselection.get_selected()
        family = model.get_value(treeiter, 0)
        family_name = family.get_name()
        self.selected_family = family_name
        if not family_name in self.cache:
            book = SettingsBook(family)
            self.cache.add(family_name, book)
        else:
            book = self.cache[family_name]
        try:
            old_child = self.container.get_children()[0]
            self.container.remove(old_child)
        except IndexError:
            pass
        self.container.add(book)
        book.pick_page()
        self.container.show_all()
        return

    def _show_self(self):
        sidebox = gtk.VBox()
        sidebox.set_spacing(5)
        box = gtk.VBox()
        box.set_spacing(5)
        pane = gtk.HPaned()
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        sidebox.pack_start(sw, True, True, 0)
        self.edit_aliases = gtk.Button(_('Alias Editor'))
        self.edit_aliases.connect('clicked', self._edit_aliases)
        sidebox.pack_start(self.edit_aliases, False, True, 0)
        pane.add1(sidebox)
        pane.add2(box)
        box.pack_start(self.container, True, True, 0)
        sw.add(self.family_tree)
        buttonbox = self._build_button_box()
        box.pack_end(buttonbox, False, True, 0)
        self.add(pane)
        self.set_position(gtk.WIN_POS_CENTER)
        self.show_all()
        return

    def discard_settings(self, unused_widget):
        discard_fontconfig_settings(self.cache[self.selected_family])
        return

    def save_cache(self):
        cache = shelve.open(join(USER_FONT_CONFIG_DIR, CACHED_SETTINGS),
                                            protocol=cPickle.HIGHEST_PROTOCOL)
        for family in self.cache.iterkeys():
            if family == 'pango_families':
                continue
            cache[family] = self.cache[family]
        cache.close()
        return

    def save_settings(self, unused_widget):
        save_fontconfig_settings(self.cache[self.selected_family])
        return


class SettingsBook(gtk.Notebook):
    families = None
    preview = None
    def __init__(self, family):
        gtk.Notebook.__init__(self)
        if not self.families:
            self.families = CACHE['pango_families']
        if isinstance(family, str):
            self.family = self.families[family]
        elif isinstance(family, pango.FontFamily):
            self.family = family
        else:
            raise TypeError('Expected name or pango family, got %s' % family)
        self.faces = {}
        for face in sorted(family.list_faces(),
                cmp = lambda x, y: cmp(x.get_face_name(), y.get_face_name())):
            settings = SettingsPage()
            page = settings.get_page()
            tab_label = gtk.Label(face.get_face_name())
            self.append_page(page, tab_label)
            settings.descr = face.describe()
            self.faces[face.get_face_name()] = settings
        self.set_scrollable(True)
        self.connect('switch-page', self._update_preview)
        self.pick_page()

    def __getstate__(self):
        """
        Save our current state.
        """
        state = {}
        state['family'] = self.family.get_name()
        state['faces'] = {}
        for face in self.faces:
            state['faces'][face] = self.faces[face]
        return state

    def __setstate__(self, state):
        """
        Restore our saved state.
        """
        gtk.Notebook.__init__(self)
        if not self.families:
            self.families = CACHE['pango_families']
        for family in self.families:
            if family.get_name() == state['family']:
                self.family = family
                break
        self.faces = {}
        for face in sorted(self.family.list_faces(),
                cmp = lambda x, y: cmp(x.get_face_name(), y.get_face_name())):
            name = face.get_face_name()
            settings = state['faces'][name]
            page = settings.get_page()
            tab_label = gtk.Label(name)
            page.unparent()
            self.append_page(page, tab_label)
            settings.descr = face.describe()
            self.faces[name] = settings
        self.set_scrollable(True)
        self.connect('switch-page', self._update_preview)
        return

    def pick_page(self):
        old_page = self.get_current_page()
        self.set_current_page(0)
        have_known_style = False
        for i in range(self.get_n_pages()):
            page = self.get_nth_page(i)
            label = self.get_tab_label(page)
            if label.get_text() in DEFAULT_STYLES:
                have_known_style = True
                known_style = i
                break
        if have_known_style:
            self.set_current_page(known_style)
        if old_page == self.get_current_page():
            self._update_preview(self, None, old_page)
        return

    def _update_preview(self, unused_book, unusable_pointer, page_num):
        page = self.get_nth_page(page_num)
        label = self.get_tab_label(page)
        if label and self.preview:
            self.preview.update(None, descr=self.faces[label.get_text()].descr)
        return


class SettingsCache(UserDict.UserDict):
    def __init__(self):
        UserDict.UserDict.__init__(self)
        self.data = {}

    def add(self, family, book):
        self.data[family] = book
        return

    def remove(self, family):
        if family in self.data:
            del self.data[family]
        return


class SettingsPage(object):
    def __init__(self, settings = None):
        for attribute, val in DEFAULTS.iteritems():
            setattr(self, attribute, val)
        if isinstance(settings, dict):
            for attribute, val in settings.iteritems():
                setattr(self, attribute, val)
        self.widgets = {}
        self.widgets['scale'] = {}
        self.page = self._build_page()
        self.descr = None

    def __getstate__(self):
        """
        Save our current state.
        """
        state = {}
        for attribute in self.__dict__.iterkeys():
            ignore = 'widgets', 'page', 'descr'
            if attribute in ignore:
                continue
            else:
                state[attribute] = getattr(self, attribute, DEFAULTS[attribute])
        return state

    def __setstate__(self, state):
        """
        Restore our saved state.
        """
        self.__init__()
        for attribute, val in state.iteritems():
            setattr(self, attribute, val)
        self._update_state()
        return

    def _build_page(self):
        page = gtk.VBox()
        page.set_border_width(20)
        page.set_spacing(10)
        for label in CHECKBUTTONS:
            if label == _('Smaller than') or label == _('Larger than'):
                continue
            buttonbox = self._get_new_checkbutton(label)
            page.pack_start(buttonbox, False, True, 0)
            if label in SCALES:
                scale = self._get_new_scale(SCALES[label])
                buttonbox.pack_start(scale, True, True, 0)
        page.pack_start(self._get_rangebox(), False, True, 0)
        page.show_all()
        return page

    @staticmethod
    def _format_value(unused_scale, val, label):
        return SCALE_LABELS[label][float('0.' + str(val).split('.')[1][:1])]

    def _get_new_checkbutton(self, label):
        buttonbox = gtk.VBox()
        checkbutton = gtk.CheckButton(label)
        checkbutton.set_active(DEFAULTS[FC_WIDGETMAP[label]])
        buttonbox.pack_start(checkbutton, False, True, 0)
        checkbutton.connect('toggled', self._update_sensitivity, label)
        checkbutton.set_property('can-focus', False)
        self.widgets[label] = checkbutton
        return buttonbox

    def _get_new_scale(self, label):
        align = gtk.Alignment(1, 1, 1, 1)
        align.set_padding(5, 5, 25, 25)
        adjustment = gtk.Adjustment(0.0, 0.0, 0.3, 0.1, 0.1, 0)
        scale = gtk.HScale(adjustment)
        scale.set_draw_value(True)
        scale.set_value_pos(gtk.POS_TOP)
        scale.connect('format-value', self._format_value, label)
        scale.connect('scroll-event', self._scroll_scale)
        scale.connect('value-changed', self._scale_changed)
        align.add(scale)
        scale.set_sensitive(False)
        self.widgets['scale'][label] = scale
        return align

    def _get_new_spinbutton(self, label):
        adjustment = gtk.Adjustment(0.0, 0.0, 96.0, 1.0, 1.0, 0)
        spinbutton = gtk.SpinButton(adjustment)
        self.widgets[label] = spinbutton
        spinbutton.set_sensitive(False)
        return spinbutton

    def _get_rangebox(self):
        rangebox = gtk.HBox()
        rangebox.set_spacing(25)
        less_eq = self._get_new_checkbutton(_('Smaller than'))
        more_eq =  self._get_new_checkbutton(_('Larger than'))
        rangebox.pack_start(less_eq, False, True, 0)
        spin1 = self._get_new_spinbutton('min_size')
        spin1.connect('value-changed', self._set_min_size)
        rangebox.pack_start(spin1, False, True, 0)
        rangebox.pack_start(more_eq, False, True, 0)
        spin2 = self._get_new_spinbutton('max_size')
        spin2.connect('value-changed', self._set_max_size)
        rangebox.pack_start(spin2, False, True, 0)
        return rangebox

    def get_page(self):
        return self.page

    def _scale_changed(self, scale):
        for name, widget in self.widgets['scale'].iteritems():
            if scale == widget:
                setattr(self, FC_WIDGETMAP[name], scale.get_value())
        return

    def _set_min_size(self, widget):
        setattr(self, 'min_size', widget.get_value())
        return

    def _set_max_size(self, widget):
        setattr(self, 'max_size', widget.get_value())
        return

    @staticmethod
    def _scroll_scale(widget, event):
        old_val = widget.get_value()
        if event.direction == gtk.gdk.SCROLL_UP:
            new_val = old_val + 0.1
        else:
            new_val = old_val - 0.1
        widget.set_value(new_val)
        return True

    def _update_sensitivity(self, widget, label):
        widgets = self.widgets
        if label in SENSITIVITY:
            if widgets[label].get_active():
                if label in REVERSE:
                    widgets[SENSITIVITY[label]].set_active(False)
                else:
                    widgets[SENSITIVITY[label]].set_sensitive(True)
            else:
                if label not in REVERSE:
                    widgets[SENSITIVITY[label]].set_sensitive(False)
        if isinstance(widget, gtk.CheckButton):
            setattr(self, FC_WIDGETMAP[label], widget.get_active())
        for scale, attribute in SCALE_SENSITIVITY.iteritems():
            val = getattr(self, attribute, DEFAULTS[attribute])
            widgets['scale'][scale].set_sensitive(val)
        return

    def _update_state(self):
        widgets = self.widgets
        for widget in CHECKBUTTONS:
            attribute = FC_WIDGETMAP[widget]
            state = getattr(self, attribute, DEFAULTS[attribute])
            widgets[widget].set_active(state)
        for widget in SCALES.itervalues():
            attribute = FC_WIDGETMAP[widget]
            state = getattr(self, attribute, DEFAULTS[attribute])
            widgets['scale'][widget].set_value(state)
        for attribute in 'min_size', 'max_size':
            widgets[attribute].set_value(getattr(self, attribute,
                                                    DEFAULTS[attribute]))
        return

    def reset(self):
        for attribute, val in DEFAULTS.iteritems():
            setattr(self, attribute, val)
        self._update_state()
        return


class SettingsPreview(gtk.Window):
    def __init__(self, parent = None):
        gtk.Window.__init__(self)
        self.set_size_request(550, 400)
        self.set_title(_('Preview'))
        if parent:
            self.set_transient_for(parent)
            self.set_destroy_with_parent(True)
        main_box = gtk.VBox()
        main_box.set_border_width(15)
        main_box.set_spacing(5)
        self.size = 10
        self.descr = None
        sw = gtk.ScrolledWindow()
        sw.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        self.preview = self._get_textview()
        sw.add(self.preview)
        size_box = self._get_size_box()
        main_box.pack_start(sw, True, True, 0)
        main_box.pack_start(size_box, False, True, 0)
        self.add(main_box)
        self.update()

    def _get_size_box(self):
        frame = gtk.Notebook()
        frame.set_show_tabs(False)
        box = gtk.HBox()
        box.set_spacing(10)
        box.set_border_width(5)
        adjustment = gtk.Adjustment(0.0, 2.0, 96.0, 1.0, 2.0, 0)
        adjustment.set_value(self.size)
        spinbutton = gtk.SpinButton(adjustment)
        slider = gtk.HScale(adjustment)
        spinbutton.connect('value-changed', self.update)
        slider.connect('value-changed', self.update)
        slider.set_draw_value(False)
        box.pack_start(slider, True, True, 0)
        box.pack_end(spinbutton, False, True, 0)
        frame.add(box)
        return frame

    @staticmethod
    def _get_textview():
        tv = gtk.TextView()
        tv.set_property('wrap-mode', gtk.WRAP_WORD)
        tv.set_property('left-margin', 10)
        tv.set_property('right-margin', 10)
        tv.set_property('pixels-above-lines', 2)
        tv.set_property('cursor-visible', False)
        return tv

    def update(self, widget = None, descr = None):
        if widget:
            self.size = widget.get_value()
        t_buffer = self.preview.get_buffer()
        t_buffer.set_text(PREVIEW_TEXT)
        if not self.descr:
            self.descr = self.get_style().font_desc
        if descr is not None:
            self.descr = descr
        tag = t_buffer.create_tag(None, font_desc = self.descr,
                                            size_points = self.size)
        bounds = t_buffer.get_bounds()
        t_buffer.apply_tag(tag, bounds[0], bounds[1])
        return


def discard_fontconfig_settings(settings):
    config_file = join(USER_FONT_CONFIG_DIR,
                        '25-%s.conf' % settings.family.get_name())
    if exists(config_file):
        os.unlink(config_file)
    for page in settings.faces:
        settings.faces[page].reset()
    return
