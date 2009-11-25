"""
This module generates a pdf sample page from a directory of fonts.
It supports Truetype and Type 1 fonts. 

At the moment the output is very basic, but more complex styles and 
options will be added over time, hopefully.
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

import os
import gtk
import gobject

from os.path import join

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont, TTFontFile, TTFError
from reportlab.lib.units import inch
from reportlab.lib.fonts import addMapping
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.platypus.flowables import KeepTogether

from common import Throbber, natural_sort


PAGE_HEIGHT = letter[1]
PAGE_WIDTH = letter[0]
TYPE1_EXTS = ('.pfb', '.PFB')
TRUETYPE_EXTS = ('.ttf', '.ttc', '.otf', '.TTF', '.TTC', '.OTF')
# A place for rejected files
SKIP_LS = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING)



class BuildSample:
    """
    Build a sample pdf from given directory
        
    Keyword arguments:
    fontdir -- the directory to scan for font files
    output -- the name of output file - fontdir/filename.pdf
    """    
    def __init__(self, fontdir, output, builder):
        # Need to split these off later so we can offer options
        self.styles = getSampleStyleSheet()
        self.font_size = 20
        self.collection = fontdir.rsplit('/', 1)[1]
        author =  os.getenv('LOGNAME')
        self.author = author.capitalize()
        self.subject = _('Sample of included fonts')        
        #
        self.fontdir = fontdir
        self.output = output
        self.builder = builder
        self.total = 0
        self.failed = {}
        self.body = None
        # UI elements
        self.mainbox = self.builder.get_object('main_box')
        self.options = self.builder.get_object('options_box')
        self.refresh = self.builder.get_object('refresh')
        # Visual feedback
        self.load_label = self.builder.get_object('loading_label')
        self.progress_label = self.builder.get_object('progress_label')
        self.throbber = Throbber(self.builder)
        
    def basic(self):
        """
        Constructs a basic pdf listing the filename followed by a sample 
        rendering of the font. 
        """
        self.insensitive()
        self.throbber.start()
        # Threads would be nice
        # But sprinkling these around works for now
        while gtk.events_pending():
            gtk.main_iteration()
        doc = SimpleDocTemplate(self.output, pagesize=letter, \
        title=self.collection, author=self.author, subject=self.subject, \
        leftMargin=0.75*inch, rightMargin=0.75*inch, \
        topMargin=0.75*inch, bottomMargin=0.75*inch)
        self.body = [ Spacer(1, 0.01*inch) ]
        style = self.styles[ "Normal" ]
        self.load_label.set_text(_('Preparing : '))
        self.load_label.show()
        self.progress_label.show()
        for root, dirs, files in os.walk(self.fontdir):
            files = natural_sort(files)
            for filename in files:
                self.total += 1
                fontfile = filename
                filename = join(root, filename)
                if filename.endswith(TRUETYPE_EXTS):
                    name = self.register_truetype(fontfile, filename)
                    while gtk.events_pending():
                        gtk.main_iteration()
                    if not name:
                        continue
                    # Build our current sample
                    try:
                        sample = []
                        current_file = Paragraph\
                        ('<font size="10">' + fontfile + '</font>', style)
                        sample.append(current_file)
                        sample.append(Spacer(1, 0.1*inch))
                        current_sample = Paragraph\
                        ('<font name="%s" size="%s">' % \
                        (name, self.font_size) + name + '</font>', style)
                        sample.append(current_sample)
                        sample.append(Spacer(1, 0.5*inch))
                        self.body.append(KeepTogether(sample))
                        while gtk.events_pending():
                            gtk.main_iteration()
                    # Triggered by some font psnames?
                    except ValueError, error:
                        self.failed[fontfile] = error
                elif filename.endswith(TYPE1_EXTS):
                    name = self.register_type1(fontfile, filename)
                    while gtk.events_pending():
                        gtk.main_iteration()
                    if not name:
                        continue
                    # Build our current sample
                    try:
                        sample = []
                        current_file = Paragraph\
                        ('<font size="10">' + fontfile + '</font>', style)
                        sample.append(current_file)
                        sample.append(Spacer(1, 0.1*inch))
                        current_sample = Paragraph\
                        ('<font name="%s" size="%s">' % \
                        (name, self.font_size) + name + '</font>', style)
                        sample.append(current_sample)
                        sample.append(Spacer(1, 0.5*inch))
                        self.body.append(KeepTogether(sample))
                        while gtk.events_pending():
                            gtk.main_iteration()
                    except ValueError, error:
                        self.failed[fontfile] = error
        self.load_label.set_text('')
        self.load_label.hide()
        self.progress_label.set_text('')
        self.progress_label.hide()
        self.throbber.stop()
        while gtk.events_pending():
            gtk.main_iteration()
        if not self.prompt_for_failed_fonts():
            self.sensitive()
            while gtk.events_pending():
                gtk.main_iteration()         
            return False
        self.progress_label.set_text(_('Rendering PDF sample sheet...'))
        self.progress_label.show()
        while gtk.events_pending():
            gtk.main_iteration()
        # Render and save pdf
        doc.build(self.body)
        #
        self.progress_label.set_text('')
        self.progress_label.hide()
        self.sensitive()
        while gtk.events_pending():
            gtk.main_iteration()
        return True
        
    def register_truetype(self, fontfile, filename):
        self.progress_label.set_text(fontfile)
        try:
            # Prepare the font for use
            tt_file = TTFontFile(filename)#(filename, charInfo=1, validate=1)
            # Thanks to ttfsampler for this part, seems to only happen 
            # with shoddy font files.
            tt_file.makeSubset(range(128))
            name = tt_file.name
            font = TTFont(name, filename)
            pdfmetrics.registerFont(font)
            # Map the same file to every style
            map_font(name)
            return name
        except (TTFError, IndexError), error:
            self.failed[fontfile] = error
            return False
            
    def register_type1(self, fontfile, filename):
        self.progress_label.set_text(fontfile)
        try:
            # Prepare the font for use
            pfb_file = filename
            if filename.endswith('.pfb'):
                afm_file = filename.replace('.pfb', '.afm')
            elif filename.endswith('.PFB'):
                afm_file = filename.replace('.PFB', '.AFM')
            face = pdfmetrics.EmbeddedType1Face(afm_file, pfb_file)
            name = find_type1_name(afm_file)
            pdfmetrics.registerTypeFace(face)
            font = pdfmetrics.Font(name, name, 'WinAnsiEncoding')
            pdfmetrics.registerFont(font)
            return name
        except (pdfmetrics.FontError, pdfmetrics.FontNotFoundError), error:
            self.failed[fontfile] = error
            return False
        except AssertionError, error:
            self.failed[fontfile] = error
            return False
            
    def prompt_for_failed_fonts(self):
        if len(self.failed) > 0:
            if not self.confirm_action(self.failed):
                SKIP_LS.clear()
                return False
        return True
    
    def confirm_action(self, dic):
        """
        For whatever reason not all fonts will be included, show the user 
        which, why and confirm that they still wants to continue.
        """
        dialog = gtk.Dialog(_('Skipping the following fonts'), None,
                        gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
                                ('Cancel', gtk.RESPONSE_CANCEL,
                                    'Continue', gtk.RESPONSE_OK))
        dialog.set_default_size(550, 225)
        sw = gtk.ScrolledWindow()
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        sw.set_property('shadow-type', gtk.SHADOW_ETCHED_IN)
        tree, column = _build_tree(dic)
        sw.add(tree)
        dialog.vbox.pack_start(sw, True, True, 5)
        status = gtk.Label\
(_('Due to the reasons listed above %s out of %s fonts will not be included') \
% (len(self.failed), self.total))
        dialog.vbox.pack_start(status, False, True, 5)
        dialog.vbox.show_all()
        column.clicked()
        response = dialog.run()
        dialog.destroy()
        while gtk.events_pending():
            gtk.main_iteration()
        if not response == gtk.RESPONSE_OK:
            return False
        else:
            return True
        
    def insensitive(self):
        self.refresh.hide()
        self.mainbox.set_sensitive(False)
        self.options.set_sensitive(False)
        while gtk.events_pending():
            gtk.main_iteration()
        return

    def sensitive(self):
        self.refresh.show()
        self.mainbox.set_sensitive(True)
        self.options.set_sensitive(True)
        while gtk.events_pending():
            gtk.main_iteration()
        return
        

def map_font(name):
    """
    This just maps every style to the same file so that Platypus doesn't
     balk if it encounters style tags i.e. <b></b>
    
    Not really necessary since we're not using those anyways, but...
    """
    # Give this a pass as it's not that important and a fail here
    # shouldn't stop anything.
    try:
        addMapping(name, 0, 0, name)
        addMapping(name, 0, 1, name)
        addMapping(name, 1, 0, name)
        addMapping(name, 1, 1, name) 
    except:
        pass
    return
    
def find_type1_name(path):
    """
    Extract a font name from an AFM file.
    """
    noname = _('Face name unavailable')
    try:
        f = open(path)
    except IOError:
        return noname
    found = 0
    while not found:
        line = f.readline()[:-1]
        if not found and line[:16] == 'StartCharMetrics':
            return noname
        if line[:8] == 'FontName':
            fontName = line[9:]
            found = 1
    fontName.strip()
    return fontName

def _build_tree(dic):
    lstore = SKIP_LS
    for font, error in dic.iteritems():
        error = str(error)
        if error.find(':'):
            try:
                error = error.split(':')[1]
            except IndexError:
                pass
        error.strip()
        lstore.append([font, error])
    tree = gtk.TreeView(lstore)
    cell_render = gtk.CellRendererText()
    c1 = gtk.TreeViewColumn(_('Font file'), cell_render, text=0)
    c1.set_min_width(175)
    c1.set_sort_column_id(0)
    c2 = gtk.TreeViewColumn(_('Problem encountered'), cell_render, text=1)
    c2.set_min_width(275)
    tree.append_column(c1)
    tree.append_column(c2)
    return tree, c1


