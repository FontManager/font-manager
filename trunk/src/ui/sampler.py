"""
This module generates a pdf sample page from a directory or a python
list of fonts. It supports Truetype and Type 1 fonts.

At the moment the output is very basic, but more complex styles and
options will be added over time, hopefully.
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
# Disable warnings related to accessing gtk.Dialog.vbox
# pylint: disable-msg=E1101

import os
import gtk
import gobject

from os.path import join, isdir, realpath

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.pdfmetrics import FontError, FontNotFoundError
from reportlab.pdfbase.ttfonts import TTFont, TTFontFile, TTFError
from reportlab.lib.units import inch
from reportlab.lib.fonts import addMapping
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.platypus.flowables import KeepTogether

from utils.common import natural_sort, natural_sort_pathlist, run_dialog

# letter == (612.0, 792.0)
PAGE_WIDTH = letter[0]
PAGE_HEIGHT = letter[1]
# file extensions to include
TYPE1_EXTS = ('.pfb', '.PFB')
TRUETYPE_EXTS = ('.ttf', '.ttc', '.otf', '.TTF', '.TTC', '.OTF')
# A place for rejected files
SKIP_LS = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING)
# Typical font preview
LINE1 = "The quick brown fox jumps over the lazy dog."
LINE2 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LINE3 = "abcdefghijklmnopqrstuvwxyz"
LINE4 = "1234567890.:,;(*!?')"
LINE = { 1 : LINE1, 2 : LINE2, 3 : LINE3, 4 : LINE4 }


class Config(object):
    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.fontsize = 20
        author =  os.getenv('USER')
        self.author = author.capitalize()
        self.subject = _('Sample of included fonts')
        self.pangram = False


class BuildSample:
    """
    Build a sample pdf from given directory or list

    objects -- an ObjectContainer instance

    Keyword arguments:
    config -- a Config instance or None to use default values
    collection -- collection name / pdf name
    fontlist -- a python list or the directory to scan for font files
    outfile -- the name of output file - <fullpath>/filename.pdf
    """
    def __init__(self, objects, config, collection, fontlist, outfile):
        #
        if config is None:
            self.config = Config()
        else:
            self.config = config
        self.styles = self.config.styles
        self.font_size = self.config.fontsize
        self.author =  self.config.author
        self.subject = self.config.subject
        #
        self.objects = objects
        self.collection = collection
        self.fontlist = fontlist
        self.outfile = outfile
        filelist = []
        if isinstance(fontlist, (tuple, list)):
            filelist = fontlist
        elif isdir(fontlist):
            for root, unused_dirs, files in os.walk(fontlist):
                for filename in files:
                    filepath = realpath(join(root, filename))
                    if not filepath in filelist:
                        filelist.append(filepath)
        else:
            raise TypeError\
            ('No files given for export, not a valid filepath or python list')
        self.total = len(filelist)
        self.fontlist = filelist
        self.failed = {}
        self.body = None
        self.rltotal = None
        self.rlprogress = None

    def basic(self):
        """
        Constructs a basic pdf listing the filename followed by a sample
        rendering of the font.
        """
        processed = 0
        progressbar = self.objects['ProgressBar']
        progress_label = self.objects['ProgressLabel']
        doc = SimpleDocTemplate(self.outfile, pagesize=letter, \
        title=self.collection, author=self.author, subject=self.subject, \
        leftMargin=0.75*inch, rightMargin=0.75*inch, \
        topMargin=1*inch, bottomMargin=0.75*inch)
        self.body = [ Spacer(1, 0.01*inch) ]
        style = self.styles[ "Normal" ]
        progress_label.set_text(_('Registering font files...'))
        while gtk.events_pending():
            gtk.main_iteration()
        for filepath in natural_sort_pathlist(self.fontlist):
            filename = filepath.rsplit('/', 1)[1]
            self.sort_and_register(filename, filepath, style)
            processed += 1
            progressbar.set_text(filename)
            self.objects.progress_callback(None, self.total, processed)
        progress_label.set_text('')
        progressbar.set_text('')
        self.objects['ProgressWindow'].hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if not self.prompt_for_failed_fonts():
            return False
        self.objects['ProgressWindow'].show()
        progress_label.set_text(_('Rendering PDF file...'))
        while gtk.events_pending():
            gtk.main_iteration()
        # Render and save pdf
        doc.setProgressCallBack(self._on_render_progress)
        doc.build(self.body)
        #
        return True

    def _on_render_progress(self, typ, val):
        """
        Progress callback function.
        """
        if typ == 'SIZE_EST':
            self.rltotal = val
        elif typ == 'PROGRESS' and self.rltotal is not None:
            if val > self.rlprogress:
                self.objects.progress_callback(None, self.rltotal, val)
                self.rlprogress = val
        elif typ == 'FINISHED':
            self.rltotal = None
            self.rlprogress = None
        return

    def build_basic_paragraph(self, filename, name, style):
        fullsize = self.font_size
        halfsize = fullsize / 2
        quarter = fullsize / 4
        threequarter = halfsize + quarter
        # Build our current sample
        try:
            sample = []
            current_file = Paragraph\
            ('<font size="{0}">'.format(halfsize) + filename + '</font>', style)
            sample.append(current_file)
            sample.append(Spacer(1, 0.1*inch))
            current_sample = Paragraph\
            ('<font name="{0}" size="{1}">'.format(name,
                                            fullsize) + name + '</font>', style)
            sample.append(current_sample)
            sample.append(Spacer(1, 0.2*inch))
            #
            if self.config.pangram:
                for linenumber in 1, 2, 3, 4:
                    current_sample = Paragraph\
                    ('<font name="{0}" size="{1}">'.format(name,
                    threequarter) + LINE[linenumber] + '</font>', style)
                    sample.append(current_sample)
                    sample.append(Spacer(1, 0.1*inch))
            sample.append(Spacer(1, 0.5*inch))
            self.body.append(KeepTogether(sample))
        # Triggered by some font psnames?
        except ValueError, error:
            self.failed[filename] = error
        return

    def sort_and_register(self, filename, filepath, style):
        if filename.endswith(TRUETYPE_EXTS):
            name = self.register_ttf(filename, filepath)
            if not name:
                return False
            self.build_basic_paragraph(filename, name, style)
        elif filename.endswith(TYPE1_EXTS):
            name = self.register_type1(filename, filepath)
            if not name:
                return False
            self.build_basic_paragraph(filename, name, style)
        return True

    def register_ttf(self, filename, filepath):
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
        dialog = gtk.Dialog(_('Skipping the following families'), None,
                        gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
                                ('Cancel', gtk.RESPONSE_CANCEL,
                                    'Continue', gtk.RESPONSE_OK))
        dialog.set_default_size(625, 225)
        sw = gtk.ScrolledWindow()
        sw.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        sw.set_property('shadow-type', gtk.SHADOW_ETCHED_IN)
        tree = _build_tree(dic)
        sw.add(tree)
        dialog.vbox.pack_start(sw, True, True, 5)
        status = gtk.Label(_('Due to the reasons listed above {0!s} out of \
{1!s} fonts will not be included in the sample sheet').format(len(self.failed),
                                                                    self.total))
        dialog.vbox.pack_start(status, False, True, 5)
        dialog.vbox.show_all()
        result = run_dialog(dialog = dialog)
        return (result == gtk.RESPONSE_OK)


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
    ordered = natural_sort([e for e in dic.iterkeys()])
    for font in ordered:
        error = str(dic[font])
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
    col1 = gtk.TreeViewColumn(_('Font file'), cell_render, text=0)
    col1.set_min_width(175)
    col1.set_sort_column_id(0)
    col2 = gtk.TreeViewColumn(_('Problem encountered'), cell_render, text=1)
    col2.set_min_width(275)
    tree.append_column(col1)
    tree.append_column(col2)
    return tree
