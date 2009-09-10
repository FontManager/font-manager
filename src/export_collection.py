#!/usr/bin/env python
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
import shutil
import subprocess
import re

from os.path import exists

from config import HOME, INI

font_list = []
file_list = []
# fonts for which filepath is ?
no_info = []
		
class export:
	
	def __init__(self, export_to_archive = 0, export_to_pdf = 0):
		
		from fm_collections import Collections as C
		from fontload import g_font_files
		
		# hardcode for now
		export_to_archive = 1
		export_to_pdf = 0
		self.c = C().get_current_collection()

		file ='%s-MISSING' % self.c.name
		tmpfile = '/tmp/%s' % file
		tmpdir = "/tmp/%s" % self.c.name
		for font in self.c.fonts:
			font_list.append(font.family)
		for font in font_list:
			file_path = g_font_files.get(font, None)
			if file_path:
				for path in file_path:
					if exists(path):
						file_list.append(path)
			else:
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
							if exists(path):
								file_list.append(path)
							else: raise IOError('No such file')
				except: no_info.append(font)
		if len(no_info) > 0:
			# let user know which fonts were not included :-\
			self.show_missing(tmpfile, no_info)
			dialog = gtk.Dialog(_('Missing information'), None, 0,
										(_('Cancel'), gtk.RESPONSE_CANCEL,
										_('Continue'), gtk.RESPONSE_OK),)
			dialog.set_default_response(gtk.RESPONSE_OK)
			dialog.set_size_request(450, 325)
			box = dialog.get_content_area()
			sw = gtk.ScrolledWindow()
			sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
			view = gtk.TextView()
			view.set_left_margin(5)
			view.set_right_margin(5)
			view.set_cursor_visible(False)
			view.set_editable(False)
			buffer = view.get_buffer()
			infile = open(tmpfile, 'r')
			if infile:
				string = infile.read()
				infile.close()
				buffer.set_text(string)
			sw.add(view)
			box.pack_start(sw, True, True, 0)
			box.show_all()
			response = dialog.run()
			if response == gtk.RESPONSE_OK:
				dialog.destroy()
				os.unlink(tmpfile)
			elif response == gtk.RESPONSE_CANCEL:
				os.unlink(tmpfile)
				reset_lists()
				dialog.destroy()
				return
			elif response == gtk.RESPONSE_DELETE_EVENT:
				os.unlink(tmpfile)
				reset_lists()
				dialog.destroy()
				return
		if export_to_archive:
			self.export_to_archive(tmpdir)
		elif export_to_pdf:
			return
		
	def export_to_archive(self, tmpdir):
		import ConfigParser
		config = ConfigParser.ConfigParser()
		config.read(INI)
		try:
			arch_type = config.get('Archive Type' , 'default')
		except ConfigParser.NoSectionError:
			arch_type = 'zip'
		if exists(tmpdir):
			shutil.rmtree(tmpdir)
		os.mkdir(tmpdir)
		while gtk.events_pending():
			gtk.main_iteration(False)
		for path in set(file_list):
			shutil.copy(path, tmpdir)
		while gtk.events_pending():
			gtk.main_iteration(False)	
		os.chdir(os.getenv("HOME") + "/Desktop")
		cmd = "file-roller -a '%s.%s' '%s'" % (self.c.name, arch_type, tmpdir)
		subprocess.call(cmd, shell=True)
		while gtk.events_pending():
			gtk.main_iteration(False)
		shutil.rmtree(tmpdir)
		reset_lists()
	
	def show_missing(self, tmpfile, no_info):
		f = open(tmpfile, 'w')
		f.write(_("\nFilepaths for the following fonts could not be determined.\n"))
		f.write(_("\nThese fonts will not be included :\n\n"))
		for i in set(no_info):
			f.write(i + "\n")
		f.close()

def reset_lists():
	global font_list
	font_list = []
	global file_list
	file_list = []
	global no_info
	no_info = []
