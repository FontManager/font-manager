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
import glib
import gobject
import pango
import cPickle
import shelve
import UserDict

from os.path import exists, join

from core.fonts import PangoFamily
from constants import FC_CHECKBUTTONS, COMMON_FONTS, FC_DEFAULTS, \
                DEFAULT_STYLES, FC_WIDGETMAP, USER_FONT_CONFIG_DIR, \
                CACHE_DIR, FC_SCALES, FC_SCALE_LABELS, FC_SENSITIVITY, \
                FC_SCALE_SENSITIVITY, FC_BUTTONORDER
from utils.common import correct_slider_behavior, natural_sort, touch
from utils.xmlutils import save_alias_settings, save_fontconfig_settings, \
                            load_alias_settings


CACHE = None
CACHED_SETTINGS = 'fontconfig.cache'
FAMILIES = None


class AliasEdit(gtk.Window):
    """
    Dialog to allow easy editing of fontconfig aliases.
    """
    def __init__(self, objects):
        gtk.Window.__init__(self)
        self.objects = objects
        self.set_transient_for(objects['Main'].main_window)
        self.set_position(gtk.WIN_POS_CENTER_ON_PARENT)
        self.set_destroy_with_parent(True)
        self.set_title(_('Alias Editor'))
        self.connect('delete-event', self._on_quit)
        self.update_required = False
        self.aliases = None
        self.widgets = {}
        self.system_families = objects['FontManager'].list_families()
        self.all_families = \
        [f for f in sorted(set(COMMON_FONTS + tuple(self.system_families)))]
        self.all_store = gtk.ListStore(gobject.TYPE_STRING)
        for family in natural_sort(self.all_families):
            self.all_store.append([family])
        self.system_store = gtk.ListStore(gobject.TYPE_STRING)
        for family in natural_sort(self.system_families):
            self.system_store.append([family])
        self.set_size_request(425, 350)
        self.set_resizable(False)
        self.set_border_width(10)
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
        self.show_all()

    def _do_edit(self, renderer, path, new_text):
        """
        Set actual value in model to that typed in by user.
        """
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
        for label in _('Add Alias'), _('Remove Alias'), _('Add Substitute'), \
                    _('Remove Substitute'), _('Write configuration'):
            button = gtk.Button(label)
            button.connect('clicked', buttons[label])
            if label == _('Write configuration'):
                box.pack_end(button, False, True, 0)
            else:
                box.pack_start(button, False, True, 0)
            self.widgets[widgets[label]] = button
        return box

    def _on_quit(self, unused_widget, unused_event):
        self.destroy()
        if self.update_required:
            self.objects.reload()
        return

    def _start_edit(self, renderer, editable, path):
        """
        Add appropriate completion support to selected entry.
        """
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
        """
        Enable or disable widgets based on selection.
        """
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
        """
        Add a new alias.
        """
        model = self.alias_tree.get_model()
        treeiter = model.append(None, [_('Family')])
        path = model.get_path(treeiter)
        column = self.alias_tree.get_column(0)
        self.alias_tree.scroll_to_cell(path, column)
        self.alias_tree.set_cursor(path, column, start_editing=True)
        return

    def add_sub(self, unused_widget):
        """
        Add a substitution for the currently selected alias.
        """
        selection = self.alias_tree.get_selection()
        model, treeiter = selection.get_selected()
        treeiter = model.append(treeiter, [_('Substitute')])
        path = model.get_path(treeiter)
        column = self.alias_tree.get_column(0)
        self.alias_tree.expand_to_path(path)
        self.alias_tree.scroll_to_cell(path, column)
        self.alias_tree.set_cursor(path, column, start_editing=True)
        return

    def del_entry(self, unused_widget):
        """
        Delete currently selected alias or substitution.
        """
        selection = self.alias_tree.get_selection()
        model, treeiter = selection.get_selected()
        old_path = model.get_path(treeiter)
        model.remove(treeiter)
        still_valid = model.iter_is_valid(treeiter)
        if still_valid:
            new_path = model.get_path(treeiter)
            if (new_path[0] >= 0):
                selection.select_path(new_path)
        else:
            if len(old_path) == 2:
                treeiter = model.get_iter(old_path[0])
                path_to_select = model.iter_n_children(treeiter) - 1
                new_path = (old_path[0], path_to_select)
                if (path_to_select >= 0):
                    selection.select_path(new_path)
                else:
                    selection.select_path(old_path[0])
            else:
                path_to_select = model.iter_n_children(None) - 1
                if (path_to_select >= 0):
                    selection.select_path(path_to_select)
        return

    def load_config(self):
        """
        Load saved settings from file.
        """
        settings = load_alias_settings()
        if settings:
            for family in settings:
                model = self.alias_tree.get_model()
                treeiter = model.append(None, [family])
                for sub in settings[family]:
                    model.append(treeiter, [sub])
        return

    def save_config(self, unused_widget):
        """
        Save settings to an xml file.
        """
        save_alias_settings(self.alias_tree)
        self.load_config()
        self.alias_tree.expand_all()
        self.update_required = True
        return


class ConfigEdit(gtk.Window):
    """
    Dialog to allow easy editing of fontconfig preferences for individual
    families and styles.
    """
    def __init__(self, objects):
        gtk.Window.__init__(self)
        self.set_size_request(475, -1)
        self.set_resizable(False)
        self.set_border_width(5)
        self.connect('delete-event', self._on_quit)
        self.set_title(_("Advanced Settings"))
        self.selected_family = None
        self.current_book = None
        self.objects = objects
        self.set_transient_for(self.parent)
        global CACHE, FAMILIES
        CACHE = self.cache = SettingsCache()
        FAMILIES = objects['FontManager'].list_families()
        SettingsBook.objects = objects
        self._load_cache()
        main_box = gtk.VBox()
        main_box.set_spacing(5)
        self.container = gtk.VBox()
        main_box.pack_start(self.container, True, True, 0)
        self.set_position(gtk.WIN_POS_CENTER)
        buttons = self._build_button_box()
        main_box.pack_end(buttons, False, True, 0)
        selection = self.objects['FamilyTree'].get_selection()
        selection.connect_after("changed", self._on_selection_changed)
        self.objects['StyleCombo'].connect_after('changed',
                                                        self._on_style_changed)
        self._on_selection_changed(None)
        self.add(main_box)
        self.show_all()

    def _build_button_box(self):
        box = gtk.HBox()
        box.set_spacing(5)
        box.set_border_width(5)
        do_reset = gtk.Button(_('Full Reset'))
        do_reset.connect('clicked', self.reset_all)
        do_reset.set_property('can-focus', False)
        box.pack_start(do_reset, False, True, 0)
        save_config = gtk.Button(_('Write configuration'))
        save_config.connect('clicked', self.save_settings)
        save_config.set_property('can-focus', False)
        box.pack_end(save_config, False, True, 0)
        discard_config = gtk.Button(_('Discard configuration'))
        discard_config.connect('clicked', self.discard_settings)
        discard_config.set_property('can-focus', False)
        box.pack_end(discard_config, False, True, 0)
        return box

    def _load_cache(self):
        cache = shelve.open(join(CACHE_DIR, CACHED_SETTINGS),
                                            protocol=cPickle.HIGHEST_PROTOCOL)
        families = self.objects['FontManager'].list_families()
        for family in cache:
            if family in families:
                try:
                    self.cache[family] = cache[family]
                except Exception:
                    pass
        cache.close()
        return

    def _on_quit(self, unused_widget, unused_event):
        self.save_cache()
        self.destroy()
        return

    def _on_selection_changed(self, unused_treeselection):
        self.selected_family = family = \
        self.objects['Previews'].current_family.pango_family
        name = family.get_name()
        if not name in self.cache:
            book = SettingsBook(family)
            self.cache.add(name, book)
        else:
            book = self.cache[name]
        try:
            old_child = self.container.get_children()[0]
            self.container.remove(old_child)
        except IndexError:
            pass
        self.container.add(book)
        book.pick_page()
        self.current_book = book
        self.container.show_all()
        return

    def _on_style_changed(self, widget):
        self.current_book.pick_page(widget.get_active_text())
        return

    def discard_settings(self, unused_widget):
        """
        Clear settings for selected family.
        """
        discard_fontconfig_settings(self.cache[self.selected_family.get_name()])
        self.save_settings(None)
        return

    def reset_all(self, unused_widget):
        """
        Clear everything.
        """
        for name in self.cache.iterkeys():
            discard_fontconfig_settings(self.cache[name])
            self.save_settings(None)
        os.unlink(join(CACHE_DIR, CACHED_SETTINGS))
        os.unlink(join(USER_FONT_CONFIG_DIR,
                        '25-{0}.conf'.format(self.selected_family.get_name())))
        return

    def save_cache(self):
        """
        Save dialog state to file.
        """
        cache = shelve.open(join(CACHE_DIR, CACHED_SETTINGS),
                                            protocol=cPickle.HIGHEST_PROTOCOL)
        families = self.objects['FontManager'].list_families()
        for family in self.cache.iterkeys():
            if family in families:
                cache[family] = self.cache[family]
        cache.close()
        return

    def save_settings(self, unused_widget):
        """
        Write settings for the selected family to an xml file.
        """
        save_fontconfig_settings(self.cache[self.selected_family.get_name()])
        glib.timeout_add_seconds(3, touch, USER_FONT_CONFIG_DIR)
        return


class SettingsBook(gtk.Notebook):
    """
    This class is a notebook containing a page for each style in a family.
    """
    families = None
    objects = None
    preview = None
    def __init__(self, family):
        gtk.Notebook.__init__(self)
        self.families = FAMILIES
        if isinstance(family, str):
            self.family = self.objects['FontManager'][family].pango_family
        elif isinstance(family, pango.FontFamily) \
        or isinstance(family, PangoFamily):
            self.family = family
        else:
            raise TypeError(
                        'Expected name or pango family, got {0}'.format(family))
        self.faces = {}
        for face in self.family.list_faces():
            settings = SettingsPage()
            page = settings.get_page()
            tab_label = gtk.Label(face.get_face_name())
            self.append_page(page, tab_label)
            settings.descr = face.describe()
            self.faces[face.get_face_name()] = settings
        self.set_scrollable(True)
        self.set_show_tabs(False)
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
        self.families = FAMILIES
        for family in self.families:
            if family == state['family']:
                self.family = self.objects['FontManager'][family].pango_family
                break
        self.faces = {}
        for face in self.family.list_faces():
            name = face.get_face_name()
            settings = state['faces'][name]
            page = settings.get_page()
            tab_label = gtk.Label(name)
            page.unparent()
            self.append_page(page, tab_label)
            settings.descr = face.describe()
            self.faces[name] = settings
        self.set_scrollable(True)
        self.set_show_tabs(False)
        return

    def pick_page(self, style = None):
        """
        Try to select the "right" page based on known styles.
        For example, select "Regular" instead "Bold Italic".
        """
        self.set_current_page(0)
        have_known_style = False
        for i in range(self.get_n_pages()):
            page = self.get_nth_page(i)
            label = self.get_tab_label(page)
            if style is not None and label.get_text() == style:
                have_known_style = True
                known_style = i
                break
            elif style is None and label.get_text() in DEFAULT_STYLES:
                have_known_style = True
                known_style = i
                break
        if have_known_style:
            self.set_current_page(known_style)
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
        for attribute, val in FC_DEFAULTS.iteritems():
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
                state[attribute] = getattr(self, attribute, FC_DEFAULTS[attribute])
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
        page.set_border_width(5)
        page.set_spacing(10)
        for name in FC_BUTTONORDER:
            label = FC_CHECKBUTTONS[name]
            if name == 'Smaller than' or name == 'Larger than':
                continue
            buttonbox = self._get_new_checkbutton(name, label)
            page.pack_start(buttonbox, False, True, 0)
            if name in FC_SCALES:
                scale = self._get_new_scale(FC_SCALES[name])
                buttonbox.pack_start(scale, True, True, 0)
        page.pack_start(self._get_rangebox(), False, True, 0)
        page.show_all()
        return page

    @staticmethod
    def _format_value(unused_scale, val, name):
        """
        Return a descriptive label to display instead of a numeric value.
        """
        # Kind of ugly but prevents KeyError
        return FC_SCALE_LABELS[name][float('0.' + str(val).split('.')[1][:1])]

    def _get_new_checkbutton(self, name, label):
        buttonbox = gtk.VBox()
        checkbutton = gtk.CheckButton(label)
        checkbutton.set_name(name)
        checkbutton.set_active(FC_DEFAULTS[FC_WIDGETMAP[name]])
        buttonbox.pack_start(checkbutton, False, True, 0)
        checkbutton.connect('toggled', self._update_sensitivity, name)
        checkbutton.set_property('can-focus', False)
        self.widgets[name] = checkbutton
        return buttonbox

    def _get_new_scale(self, name):
        align = gtk.Alignment(1, 1, 1, 1)
        align.set_padding(5, 5, 25, 25)
        adjustment = gtk.Adjustment(0.0, 0.0, 0.3, 0.1, 0.1, 0)
        scale = gtk.HScale(adjustment)
        scale.set_draw_value(True)
        scale.set_value_pos(gtk.POS_TOP)
        scale.connect('format-value', self._format_value, name)
        scale.connect('scroll-event', correct_slider_behavior)
        scale.connect('value-changed', self._scale_changed)
        align.add(scale)
        scale.set_sensitive(False)
        self.widgets['scale'][name] = scale
        return align

    def _get_new_spinbutton(self, name):
        adjustment = gtk.Adjustment(0.0, 0.0, 96.0, 1.0, 1.0, 0)
        spinbutton = gtk.SpinButton(adjustment)
        self.widgets[name] = spinbutton
        spinbutton.set_sensitive(False)
        return spinbutton

    def _get_rangebox(self):
        rangebox = gtk.HBox()
        rangebox.set_spacing(25)
        less_eq = self._get_new_checkbutton('Smaller than', _('Smaller than'))
        more_eq =  self._get_new_checkbutton('Larger than', _('Larger than'))
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

    def _update_sensitivity(self, widget, name):
        widgets = self.widgets
        reverse = 'Auto-Hint', 'Hinting'
        if name in FC_SENSITIVITY:
            if widgets[name].get_active():
                if name in reverse:
                    widgets[FC_SENSITIVITY[name]].set_active(False)
                else:
                    widgets[FC_SENSITIVITY[name]].set_sensitive(True)
            else:
                if name not in reverse:
                    widgets[FC_SENSITIVITY[name]].set_sensitive(False)
        if isinstance(widget, gtk.CheckButton):
            setattr(self, FC_WIDGETMAP[name], widget.get_active())
        for scale, attribute in FC_SCALE_SENSITIVITY.iteritems():
            val = getattr(self, attribute, FC_DEFAULTS[attribute])
            widgets['scale'][scale].set_sensitive(val)
        return

    def _update_state(self):
        widgets = self.widgets
        for widget in FC_CHECKBUTTONS.keys():
            attribute = FC_WIDGETMAP[widget]
            state = getattr(self, attribute, FC_DEFAULTS[attribute])
            widgets[widget].set_active(state)
        for widget in FC_SCALES.itervalues():
            attribute = FC_WIDGETMAP[widget]
            state = getattr(self, attribute, FC_DEFAULTS[attribute])
            widgets['scale'][widget].set_value(state)
        for attribute in 'min_size', 'max_size':
            widgets[attribute].set_value(getattr(self, attribute,
                                                    FC_DEFAULTS[attribute]))
        return

    def reset(self):
        """
        Reset all values to default.
        """
        for attribute, val in FC_DEFAULTS.iteritems():
            setattr(self, attribute, val)
        self._update_state()
        return


def discard_fontconfig_settings(settings):
    """
    Delete configuration file and reset page values.
    """
    config_file = join(USER_FONT_CONFIG_DIR,
                        '25-{0}.conf'.format(settings.family.get_name()))
    not exists(config_file) or os.unlink(config_file)
    for page in settings.faces:
        settings.faces[page].reset()
    return
