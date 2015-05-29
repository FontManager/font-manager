#!/usr/bin/env python
#
#
# Copyright 2009 Jerry Casiano
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
import libxml2
import logging
import ConfigParser

from os.path import exists

from config import HOME, DIRS_CONF, DIRS_CONF_BACKUP, INI

directories = []
start_dirs = []


class Preferences:
	
	def __init__(self, parent=None):
		from ui import app_prefs_ui as ui
		self.builder = gtk.Builder()
		self.builder.add_from_string(ui)
		self.builder.connect_signals(self)
		self.parent = parent
		self.window = self.builder.get_object('window')
		self.window.connect('destroy', self.quit)
		self.window.set_size_request(375, 425)
		self.window.set_title(_('Preferences'))
		if self.parent:
			self.window.set_transient_for(self.parent)
		self.tv = self.builder.get_object('user_dir_treeview')
		self.dir_model = gtk.ListStore(gobject.TYPE_STRING)
		self.tv.set_model(self.dir_model)
		column = gtk.TreeViewColumn(_('Folders'), gtk.CellRendererText(), markup=0)
		self.tv.append_column(column)
		self.tv.get_selection().set_mode(gtk.SELECTION_SINGLE)
		self.tv.get_selection().connect('changed', self.selection_changed)
		self.dir_combo_box = self.builder.get_object('default_folder_box')
		self.dir_combo = gtk.ComboBox()
		self.dir_combo.set_model(self.dir_model)
		cell = gtk.CellRendererText()
		self.dir_combo.pack_start(cell, True)
		self.dir_combo.add_attribute(cell, 'text', 0)
		self.dir_combo_box.pack_start(self.dir_combo, False, True, 5)
		self.arch_box = self.builder.get_object('arch_box')
		self.arch_combo = gtk.combo_box_new_text()
		self.arch_box.pack_start(self.arch_combo, False, True, 5)
		self.arch_box.reorder_child(self.arch_combo, 1)
		self.arch_combo.append_text('zip')
		self.arch_combo.append_text('tar.bz2')
		self.arch_combo.append_text('tar.gz')
		self.show_orphans = self.builder.get_object('show_orphans')
		self.show_orphaned = False
		self.load_directories()
		# count now, so we know if anything changed and need to restart
		for dir in directories:
			start_dirs.append(dir)
		# always have the default folder in list at the top
		store = self.dir_model
		iter = store.prepend()
		default_dir = os.path.join(HOME, '.fonts')
		store.set(iter, 0, default_dir)
		directories.insert(0, default_dir)
		self.tv.get_selection().select_path(0)
		self.load_config()
		
	def on_apply(self, widget):
		self.save_settings(widget)
		if sorted(set(start_dirs)) != sorted(set(directories)):
			self.restart_required(widget)
		self.quit(widget)
	
	def restart_required(self, widget):
		dialog = gtk.Dialog(_('Restart Required'), self.window, 
							gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
									(gtk.STOCK_OK, gtk.RESPONSE_OK),)

		dialog.set_default_response(gtk.RESPONSE_OK)
		box = dialog.get_content_area()
		label = gtk.Label\
(_('\tChanges will not take effect until Font Manager is restarted\t\t'))
		box.pack_start(label, True, True, 15)
		box.show_all()
		response = dialog.run()
		if response == gtk.RESPONSE_OK:
			self.quit(widget)
			dialog.destroy()	
		elif response == gtk.RESPONSE_DELETE_EVENT:
			dialog.destroy()
				
	def on_add_dir(self, widget):
		dir = self.get_new_dir()
		if dir:
			for d in directories:
				if dir == d:
					return
			self.add_directory(dir)
		
	def on_del_dir(self, widget):
		self.remove_directory()
	
	def load_config(self):

		config = ConfigParser.ConfigParser()
		config.read(INI)
		try:
			dir =  config.get('Font Folder', 'default')
			dir_iter = self.search(self.dir_model, self.dir_model.iter_children(None),
									self.match, (0, dir))
			try:
				if self.dir_model.iter_is_valid(dir_iter):
					self.dir_combo.set_active_iter(dir_iter)
			except TypeError:
				self.dir_combo.set_active(0)
		except ConfigParser.NoSectionError:
			self.dir_combo.set_active(0)
		
		try:
			arch_type = config.get('Archive Type', 'default')
			if arch_type == 'zip':
				self.arch_combo.set_active(0)
			elif arch_type == 'tar.bz2':
				self.arch_combo.set_active(1)
			elif arch_type == 'tar.gz':
				self.arch_combo.set_active(2)
		except ConfigParser.NoSectionError:
			self.arch_combo.set_active(0)
			
		try:
			self.show_orphaned = config.get('Orphans', 'show')
		except ConfigParser.NoSectionError:
			pass
			
		if self.show_orphaned == 'True':
			self.show_orphans.set_active(True)
		else:
			self.show_orphans.set_active(False)
		
	def load_backup(self):
		if exists(DIRS_CONF_BACKUP):
			logging.info('Found backup file... attempting to load')
			os.rename(DIRS_CONF_BACKUP, DIRS_CONF)
			self.load_directories()
		else:
			logging.warn('Could not find a valid configuration to load')
			os.unlink(DIRS_CONF)
			self.load_directories()
		
	def load_directories(self):
		
		if not exists(DIRS_CONF) and not exists(DIRS_CONF_BACKUP):
			return
		try:
			doc = libxml2.parseFile(DIRS_CONF)
		except libxml2.parserError:
			logging.warn("Failed to parse user directories configuration!")
			self.load_backup()
			return

		dirs = doc.xpathEval('//dir')
		if len(dirs) < 1:
			doc.freeDoc()
			return
		for dir in dirs:
			content = dir.getContent()
			if os.path.isdir(content):
				logging.info('Found user specified directory %s' % content)
				self.add_directory(content)
			else:
				logging.warn\
				('User specified directory %s not found on disk' % content)
				logging.info('Skipping...')
		doc.freeDoc()
	
	def add_directory(self, dir):
		lstore = self.dir_model
		iter = lstore.append()
		lstore.set(iter, 0, dir)
		directories.append(dir)		

	def remove_directory(self):
		iter, dir = self.get_selected_dir()
		for i in directories:
			if i == dir:
				directories.remove(i)
				self.dir_model.remove(iter)

	def get_new_dir(self):
		dialog = gtk.FileChooserDialog(_('Select Directory'), self.window,
										gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER,
										(gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
											gtk.STOCK_OK, gtk.RESPONSE_OK))
		dialog.set_default_response(gtk.RESPONSE_CANCEL)
		dialog.set_current_folder(HOME)
		response = dialog.run()
		if response == gtk.RESPONSE_OK:
			dir = dialog.get_filename()
			dialog.destroy()
			return dir
		dialog.destroy()
		
	def get_selected_dir(self):
		sel = self.tv.get_selection()
		m, iter = sel.get_selected()
		if not iter:
			return
		return iter, m.get(iter, 0)[0]
		
	def match(self, model, iter, data):
		column, key = data
		value = model.get_value(iter, column)
		return value == key
		
	def search(self, model, iter, func, data):
		while iter:
			if func(model, iter, data):
				return iter
			result = self.search(model, model.iter_children(iter), func, data)
			if result: return result
			iter = model.iter_next(iter)
		return None

	def save_directories(self):
		
		if exists(DIRS_CONF):
			if exists(DIRS_CONF_BACKUP):
				os.unlink(DIRS_CONF_BACKUP)
			os.rename(DIRS_CONF, DIRS_CONF_BACKUP)
			
		doc = libxml2.newDoc("1.0")
		root = doc.newChild(None, "fontconfig", None)
		# don't save, it's always added
		directories.remove(os.path.join(HOME, '.fonts'))
		if len(set(directories)) < 1:
			doc.saveFormatFile(DIRS_CONF, format=1)
			doc.freeDoc()
			return
		for path in set(directories):
			root.newChild(None, 'dir', path)
		doc.saveFormatFile(DIRS_CONF, format=1)
		doc.freeDoc()
		logging.info("Changes applied")
		
	def save_config(self, widget):

		config = ConfigParser.ConfigParser()
		config.read(INI)
		try:
			previous = config.get('Orphans', 'show')
		except ConfigParser.NoSectionError:
			previous = 'False'
		
		iter = self.dir_combo.get_active_iter()
		if iter:
			font_folder = self.dir_model.get_value(iter, 0)
			
		arch_type = self.arch_combo.get_active_text()
		
		config = ConfigParser.RawConfigParser()
		if font_folder:
			config.add_section('Font Folder')
			config.set('Font Folder', 'default', font_folder)
		if arch_type:
			config.add_section('Archive Type')
			config.set('Archive Type', 'default', arch_type)
		if self.show_orphans.get_active() == True:
			actual = 'True'
			config.add_section('Orphans')
			config.set('Orphans', 'show', 'True')
		elif self.show_orphans.get_active() == False:
			actual = 'False'
			config.add_section('Orphans')
			config.set('Orphans', 'show', 'False')
		with open (INI, 'wb') as ini:
			config.write(ini)

		if actual != previous:
			self.restart_required(widget)
			
	def save_settings(self, widget):
		self.save_directories()
		self.save_config(widget)

	def selection_changed(self, widget):
		sel = self.tv.get_selection().path_is_selected(0)
		rem = self.builder.get_object('del_dir')
		# don't allow removal of default folder
		if sel:
			rem.set_sensitive(False)
		else:
			rem.set_sensitive(True)
		
	def reset_directories(self):
		directories = []
		start_dirs = []
					
	def run(self):
		logging.info('Loading preferences dialog')
		self.window.show_all()
		
	def quit(self, widget):
		self.reset_directories()
		self.window.hide()
