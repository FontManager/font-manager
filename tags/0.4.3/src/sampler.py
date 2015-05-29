"""
This module generates a pdf sample page from a directory or a python
 list of fonts. It supports Truetype and Type 1 fonts. 

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

from os.path import join, exists

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.pdfmetrics import FontError, FontNotFoundError
from reportlab.pdfbase.ttfonts import TTFont, TTFontFile, TTFError
from reportlab.lib.units import inch
from reportlab.lib.fonts import addMapping
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.platypus.flowables import KeepTogether

from common import Throbber, natural_sort

# letter == (612.0, 792.0)
PAGE_WIDTH = letter[0]
PAGE_HEIGHT = letter[1]
# file extensions to include
TYPE1_EXTS = ('.pfb', '.PFB')
TRUETYPE_EXTS = ('.ttf', '.ttc', '.otf', '.TTF', '.TTC', '.OTF')
# A place for rejected files
SKIP_LS = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING)
# Typical font preview
LINE1 = _("The quick brown fox jumps over the lazy dog.")
LINE2 = _("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
LINE3 = _("abcdefghijklmnopqrstuvwxyz")
LINE4 = _("1234567890.:,;(*!?')")
LINE = { 1 : LINE1, 2 : LINE2, 3 : LINE3, 4 : LINE4 }


class Config(object):
    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.font_size = 20
        author =  os.getenv('LOGNAME')
        self.author = author.capitalize()
        self.subject = _('Sample of included fonts')
        self.include_pangram = False

class BuildSample:
    """
    Build a sample pdf from given directory or list
        
    Keyword arguments:
    config -- a Config instance or None to use default values
    collection -- collection name / pdf name
    fontdir -- a python list or the directory to scan for font files
    output -- the name of output file - <fullpath>/filename.pdf
    builder -- a gtk.Builder instance
    """    
    def __init__(self, config, collection, fontdir, output, builder):
        #
        if config is None:
            self.config = Config()
        else:
            self.config = config
        self.styles = self.config.styles
        self.font_size = self.config.font_size
        self.author =  self.config.author
        self.subject = self.config.subject
        #
        self.collection = collection
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
        topMargin=1*inch, bottomMargin=0.75*inch)
        self.body = [ Spacer(1, 0.01*inch) ]
        style = self.styles[ "Normal" ]
        self.load_label.set_text(_('Preparing : '))
        self.load_label.show()
        self.progress_label.show()
        if type(self.fontdir) == list:
            files = natural_sort(self.fontdir)
            self.total = len(filelist)
            for filepath in files:
                filename = filepath.rsplit('/', 1)[1]
                self.sort_and_register(filename, filepath, style)
        elif exists(self.fontdir):
            for root, dirs, files in os.walk(self.fontdir):
                files = natural_sort(files)
                for filename in files:
                    self.total += 1
                    filepath = join(root, filename)
                    self.sort_and_register(filename, filepath, style)
        else:
            self.blank_labels()
            self.sensitive()
            while gtk.events_pending():
                gtk.main_iteration()   
            logging.error('No files given for export')
            return False
        self.blank_labels()
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
        self.blank_labels()
        self.sensitive()
        while gtk.events_pending():
            gtk.main_iteration()
        return True
    
    def build_basic_paragraph(self, filename, name, style):
        fullsize = self.font_size
        halfsize = fullsize / 2
        quarter = fullsize / 4
        threequarter = halfsize + quarter
        # Build our current sample
        try:
            sample = []
            current_file = Paragraph\
            ('<font size="%s">' % halfsize + filename + '</font>', style)
            sample.append(current_file)
            sample.append(Spacer(1, 0.1*inch))
            current_sample = Paragraph\
            ('<font name="%s" size="%s">' % \
            (name, fullsize) + name + '</font>', style)
            sample.append(current_sample)
            sample.append(Spacer(1, 0.2*inch))
            #
            if self.config.include_pangram:
                for linenumber in 1, 2, 3, 4:
                    current_sample = Paragraph\
                    ('<font name="%s" size="%s">' % \
                    (name, threequarter) + LINE[linenumber] \
                    + '</font>', style)
                    sample.append(current_sample)
                    sample.append(Spacer(1, 0.1*inch))
            sample.append(Spacer(1, 0.5*inch))
            self.body.append(KeepTogether(sample))
            while gtk.events_pending():
                gtk.main_iteration()
        # Triggered by some font psnames?
        except ValueError, error:
            self.failed[filename] = error
        return
        
    def sort_and_register(self, filename, filepath, style):
        if filename.endswith(TRUETYPE_EXTS):
            name = self.register_ttf(filename, filepath)
            while gtk.events_pending():
                gtk.main_iteration()
            if not name:
                return False
            self.build_basic_paragraph(filename, name, style)
        elif filename.endswith(TYPE1_EXTS):
            name = self.register_type1(filename, filepath)
            while gtk.events_pending():
                gtk.main_iteration()
            if not name:
                return False
            self.build_basic_paragraph(filename, name, style)
        return True
        
    def register_ttf(self, filename, filepath):
        self.progress_label.set_text(filename)
        try:
            # Prepare the font for use
            tt_file = TTFontFile(filepath)#(filepath, charInfo=1, validate=1)
            # makeSubset is called later on and sometimes raises an
            # IndexError, so we call it here so we can catch it in time.
            # Seems to only happen with shoddy fonts.
            tt_file.makeSubset(range(128))
            name = tt_file.name
            font = TTFont(name, filepath)
            pdfmetrics.registerFont(font)
            # Map the same file to every style
            map_font(name)
            return name
        except TTFError, error:
            self.failed[filename] = error
            return False
        except (IndexError, AssertionError), error:
            self.failed[filename] = error
            return False
            
    def register_type1(self, filename, filepath):
        self.progress_label.set_text(filename)
        try:
            # Prepare the font for use
            pfb_file = filepath
            if filepath.endswith('.pfb'):
                afm_file = filepath.replace('.pfb', '.afm')
            elif filepath.endswith('.PFB'):
                afm_file = filepath.replace('.PFB', '.AFM')
            face = pdfmetrics.EmbeddedType1Face(afm_file, pfb_file)
            name = find_type1_name(afm_file)
            pdfmetrics.registerTypeFace(face)
            font = pdfmetrics.Font(name, name, 'WinAnsiEncoding')
            pdfmetrics.registerFont(font)
            return name
        except (FontError, FontNotFoundError), error:
            self.failed[filename] = error
            return False
        except (IndexError, AssertionError), error:
            self.failed[filename] = error
            return False
            
    def prompt_for_failed_fonts(self):
        SKIP_LS.clear()
        if len(self.failed) > 0:
            if not self.confirm_action(self.failed):
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
        dialog.set_default_size(625, 225)
        sw = gtk.ScrolledWindow()
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        sw.set_property('shadow-type', gtk.SHADOW_ETCHED_IN)
        tree, column = _build_tree(dic)
        sw.add(tree)
        dialog.vbox.pack_start(sw, True, True, 5)
        status = gtk.Label\
(_('Due to the reasons listed above %s out of %s fonts will not be included in the sample sheet') \
% (len(self.failed), self.total))
        dialog.vbox.pack_start(status, False, True, 5)
        dialog.vbox.show_all()
        # Sort listing by simulating a click on header
        column.clicked()
        response = dialog.run()
        dialog.destroy()
        while gtk.events_pending():
            gtk.main_iteration()
        if not response == gtk.RESPONSE_OK:
            return False
        else:
            return True
            
    def blank_labels(self):
        self.load_label.set_text('')
        self.load_label.hide()
        self.progress_label.set_text('')
        self.progress_label.hide()
        self.throbber.stop()
        while gtk.events_pending():
            gtk.main_iteration()
        return
        
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
     balk if it encounters style tags i.e. <b></b><i></i>
    
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
    Try to extract a font name from an AFM file.
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
            fontname = line[9:]
            found = 1
    fontname.strip()
    return fontname

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
        error = unicode(error, errors='replace')
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

