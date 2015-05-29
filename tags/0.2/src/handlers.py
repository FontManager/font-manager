# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2008 Karl Pickett <http://fontmanager.blogspot.com/>
# Copyright (C) 2009 Jerry Casiano
#
license = _("""
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.
""")

import os
import gtk
import logging
import subprocess

from os.path import exists

import xmlconf
from config import *
from fm_collections import *

C = Collections()

def on_about_button(self, widget):
	d = gtk.AboutDialog()
	d.set_name(PACKAGE)
	d.set_comments(_("Font management for the GNOME Desktop"))
	d.set_copyright(u"Copyright \u00A9 2008 Karl Pickett\nCopyright \u00A9 2009 Jerry Casiano")
	d.set_license(license)
	d.run()
	d.destroy()
	
def on_help(self, widget):
	help_files = "'%s/doc/en/Font Manager.html'" % PACKAGE_DIR
	if exists("/usr/bin/xdg-open") or exists("/usr/local/bin/xdg-open"):
		xdgopen = "xdg-open "
		cmd = xdgopen + help_files
		try:
			logging.info("Launching Help browser")
			subprocess.call(cmd, shell=True)
		except OSError, e:
			logging.error("Error: %s" % e)
	else:
		logging.warn("Could not find xdg-open")
			
def on_export(self, widget):
	from export_collection import export
	c = C.get_current_collection()
	if len(c.fonts) < 1:
		md = gtk.MessageDialog(self, 
		gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR, 
		gtk.BUTTONS_CLOSE, _('Please add fonts to the collection'))
		md.set_title(_("Attempt to export empty collection"))
		md.set_size_request(350, 125)
		md.run()
		md.destroy()
		return
	if len(c.fonts) > 500:
		md = gtk.MessageDialog(self, 
		gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_INFO, 
		gtk.BUTTONS_OK_CANCEL, 
		_('''Exporting a large number of fonts can take some time'''))
		md.set_default_response(gtk.RESPONSE_OK)
		md.set_title(_('Please be patient'))
		response = md.run()
		if response == gtk.RESPONSE_OK:
			pass
		else:
			md.destroy()
			return
		md.destroy()
	export()

def on_app_prefs(self, widget):
	from app_prefs import Preferences
	p = Preferences()
	p.run()
	
def on_disable_font(self, widget):
	how_many = 0
	for f in self.iter_selected_fonts():
		if f.enabled:
			how_many +=1
	if how_many < 1:
		return
	elif how_many < 1000:
		for f in self.iter_selected_fonts():
			if f.enabled:
				f.enabled = False				
		self.update_views()
		xmlconf.save_blacklist()
	elif how_many > 1000 and disable_mad_fonts(how_many):
		for f in self.iter_selected_fonts():
			if f.enabled:
				f.enabled = False
		self.update_views()
		xmlconf.save_blacklist()

def on_enable_font(self, widget):
	how_many = 0
	for f in self.iter_selected_fonts():
		if not f.enabled:
			how_many +=1
	if how_many < 1:
		return
	else:
		for f in self.iter_selected_fonts():
			if not f.enabled:
				f.enabled = True
		self.update_views()
		xmlconf.save_blacklist()

def disable_mad_fonts(how_many):
	d = gtk.Dialog(_("Confirm Action"), 
	None, gtk.DIALOG_MODAL, 
	(gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL, gtk.STOCK_YES, gtk.RESPONSE_YES))
	d.set_default_response(gtk.RESPONSE_CANCEL)
	str = _("""
	Disabling large amounts of fonts at once can have quite an impact on the desktop.	
	If you choose to continue, it is suggested that you close all open applications
	and be patient should your desktop become unresponsive for a bit.	

	Really disable %s fonts?		
	""") % how_many
	text = gtk.Label()
	text.set_text(str)
	d.vbox.pack_start(text, padding=10)
	text.show()
	ret = d.run()
	d.destroy()
	return (ret == gtk.RESPONSE_YES)
	
def on_remove_font(self, widget):
	c = C.get_current_collection()
	for f in self.iter_selected_fonts():
		c.remove(f)
	self.update_views()

# XXX for now just open the default file browser 
# to the users font dir so they can drag and drop fonts       
def on_manage_fonts(self, widget):

	if not exists(USER_FONT_DIR):
		logging.warn("No font directory found for " + USER)
		logging.info("Creating font directory")
		os.mkdir(USER_FONT_DIR, 0775)
	else: logging.info("Found font directory for " + USER)
	
	import ConfigParser
	config = ConfigParser.ConfigParser()
	config.read(INI)
	try:
		dir =  config.get('Font Folder', 'default')
		FONT_DIR = dir
	except ConfigParser.NoSectionError:
		FONT_DIR = USER_FONT_DIR

	if exists("/usr/bin/nautilus") or exists("/usr/local/bin/nautilus"):
		logging.info("Found Nautilus File Browser")
		file_browser = "nautilus"
	elif exists("/usr/bin/thunar") or exists("/usr/local/bin/thunar"):
		logging.info("Found Thunar File Browser")
		file_browser = "thunar"	
	elif exists("/usr/bin/dolphin") or exists("/usr/local/bin/dolphin"):
		logging.info("Found Dolphin File Browser")
		file_browser = "dolphin"
	elif exists("/usr/bin/konqueror") or exists("/usr/local/bin/konqueror"):
		logging.info("Found Konqueror File Browser")
		file_browser = "konqueror"	
	else: 
		logging.info("Could not find a supported File Browser")
		file_browser = 0

	if file_browser == 0:
		md = gtk.MessageDialog(self, 
		gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR, 
		gtk.BUTTONS_CLOSE, 
_("""Supported file browsers include : 

- Nautilus 
- Thunar 
- Dolphin
- Konqueror
		
If a supported file browser is installed, 
please file a bug against Font Manager"""))
		md.set_title(_("Please install a supported file browser"))
		md.run()
		md.destroy()
		return
		
	if file_browser == "nautilus":
		try:
			logging.info("Launching Nautilus")
			subprocess.call([file_browser, "--no-desktop", FONT_DIR])
		except OSError, e:
			logging.error("Error: %s" % e)
	elif file_browser == "thunar":
		try:
			logging.info("Launching Thunar")
			subprocess.call([file_browser, FONT_DIR])
		except OSError, e:
			logging.error("Error: %s" % e)
	elif file_browser == "dolphin":
		try:
			logging.info("Launching Dolphin")
			subprocess.call([file_browser, FONT_DIR])
		except OSError, e:
			logging.error("Error: %s" % e)
	elif file_browser == "konqueror":
		try:
			logging.info("Launching Konqueror")
			subprocess.call([file_browser, FONT_DIR])
		except OSError, e:
			logging.error("Error: %s" % e)
			
def on_font_preferences(self, widget):
	try:
		cmd = "gnome-appearance-properties --show-page=fonts &"
		logging.info("Launching font preferences dialog")
		subprocess.call(cmd, shell=True)
	except OSError, e:
		logging.error("Error: %s" % e)

def on_disable_collection(self, widget):
	c = C.get_current_collection()
	if not c:
		return 
	how_many = 0
	for font in c.fonts:
		how_many +=1
	#if c.builtin:
		#C.enable_collection(False)
	if how_many > 1000 and disable_mad_fonts(how_many):
		C.enable_collection(False)
	elif how_many < 1000:
		C.enable_collection(False)
	
def on_enable_collection(self, widget):
	c = C.get_current_collection()
	if not c:
		return
	C.enable_collection(True)
	
def on_new_collection(self, widget):
	C.add_new_collection(self)
	xmlconf.save_blacklist()
	
def on_remove_collection(self, widget):
	c = C.get_current_collection()
	if not c:
		return 
	str = c.name
	if str == "All Fonts" or str == "System" or str == "User":
		md = gtk.MessageDialog(self, 
		gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_WARNING, 
		gtk.BUTTONS_CLOSE, 
		_("\n Sorry, built-in collections cannot be removed at this time  \n"))
		md.run()
		md.destroy()
		return
	elif str == 'Orphans':
		md = gtk.MessageDialog(self, 
		gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_INFO, 
		gtk.BUTTONS_CLOSE, 
		_("\n Please use the preferences dialog to disable this collection  \n"))
		md.run()
		md.destroy()
		return		
	elif confirm_remove_collection():
		C.delete_collection()
		collection_tv.get_selection().select_path(0)
		family_tv.get_selection().select_path(0)
		collection_tv.columns_autosize()
		xmlconf.save_blacklist()

# XXX this should really check to see if the collection is empty
# if it is then just delete it and don't ask stupid questions
def confirm_remove_collection():
	d = gtk.Dialog(_("Confirm Action"), 
	None, gtk.DIALOG_MODAL, 
	(gtk.STOCK_NO, gtk.RESPONSE_NO, gtk.STOCK_YES, gtk.RESPONSE_YES))
	d.set_default_response(gtk.RESPONSE_CANCEL)
	c = C.get_current_collection()
	str = _("""
	Deleted collections cannot be recovered.	

	Really delete \"%s\"?		
	""") % c.name
	text = gtk.Label()
	text.set_text(str)
	d.vbox.pack_start(text, padding=10)
	text.show()
	ret = d.run()
	d.destroy()
	return (ret == gtk.RESPONSE_YES)

def on_rename_collection(self, widget):
	c = C.get_current_collection()
	if c == None:
		return 
	str = c.name
	if str == "All Fonts" or str == "System" or str == "User":
		md = gtk.MessageDialog(self, 
		gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_WARNING, 
		gtk.BUTTONS_CLOSE, 
		_("\n Sorry, built-in collections cannot be renamed at this time  \n"))
		md.run()
		md.destroy()
		return
	while True:
		str = C.get_new_collection_name(self, str)
		# no empty collection names
		if not C.collection_name_exists(str) and str != None:
			rename_collection(str)
			c.name = str
			collection_tv.columns_autosize()
			self.update_views()
			xmlconf.save_blacklist()
			break
		elif not str or c.name == str:
			return

def rename_collection(new_name):
	sel = collection_tv.get_selection()
	m, iter = sel.get_selected()
	if not iter:
		return
	collection_ls.set(iter, 2, new_name)
			
def on_size_adjustment_value_changed(self, widget):
	self.size = widget.get_value()
	self.style_changed(None)
	
def on_find_button(self, widget):
	self.find_entry.set_text('')
	self.find_box.show()
	self.find_entry.grab_focus()
	
def on_close_find(self, widget):
	self.find_box.hide()
	if family_tv.get_selection().count_selected_rows() == 0 or \
	self.find_entry.get_text() == '':
		family_tv.scroll_to_point(0, 0)
		
def on_find_entry_icon(self, widget, x, y):
	self.find_entry.set_text('')
	family_tv.scroll_to_point(0, 0)
		
def on_custom_text(self, widget):
	# Sample Text = 0
	# Custom Text = 1
	# Font Info = 2
	if self.custom_text_toggle.get_active():
		self.preview_mode_changed(None, 1)
		self.custom_text_toggle.set_label(_("Sample Text"))
	else: 
		self.preview_mode_changed(None, 0)
		self.custom_text_toggle.set_label(_("Custom Text"))
	
def on_font_info(self, widget):
	model, sel = family_tv.get_selection().get_selected_rows()
	selected = len(sel)
	if selected == 0 or selected > 1:
		logging.info("For detailed info please select one font at a time")
		return 
	get_extended_font_details(self.current_font)
            
def get_extended_font_details(font):
	
	from fontload import g_font_files
	
	filelist = g_font_files.get(font.family, None)
		
	if not filelist:
		filelist = []
		font = font.family
		try:
			# can't find path... :-?
			# f it, try to guess for now
			import re
			if re.search(',', font):
				font, scrap = font.split(',')
			cmd = "fc-list : file family"
			for l in os.popen(cmd).readlines():
				file, family = l.split(":", 1)
				if re.search(font, family):
					if font == 'Sans' \
					or font == 'Serif' \
					or font == 'Monospace':
						raise NameError('Common name')
					path = file
					filelist.append(path)
		except:
			md = gtk.MessageDialog(None, 
			gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR, 
		gtk.BUTTONS_CLOSE, _("Sorry could not load information for selected font"))
			md.set_title(_("Unavailable"))
			md.run()
			md.destroy()
			return
	
	filelist.sort()
	try:
		cmd = "gnome-font-viewer '%s' &\n" % filelist[0]
		#cmd = ""
		#for f in filelist:
			#cmd += "gnome-font-viewer '%s' &\n" % f
		subprocess.call(cmd, shell=True)
	except IndexError:
		md = gtk.MessageDialog(None, 
		gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR, 
	gtk.BUTTONS_CLOSE, _("Sorry could not load information for selected font"))
		md.set_title(_("Unavailable"))
		md.run()
		md.destroy()
		return
	except OSError, e:
		logging.error("Error opening font file: %s" % e)
