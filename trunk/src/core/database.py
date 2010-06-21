"""
This module is used to group functions which access the database.
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


import sqlite3

import _fontutils

from utils.common import delete_cache
from constants import DATABASE_FILE, HOME


FIELDS = ('owner', 'filepath', 'filetype', 'filesize', 'checksum', 'psname',
'family', 'style', 'foundry', 'copyright', 'version', 'description',
'license', 'license_url')

INIT = """
CREATE TABLE IF NOT EXISTS Fonts
(
uid INTEGER PRIMARY KEY,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT,
%s TEXT
);
""" % FIELDS


class Database(object):
    """
    This class provides a convenient way to open/close connections to the
    applications database, and perform common operations.

    This class can also serve as a decorator for any functions which need
    temporary access to the database. It handles opening a connection to the
    database, passing an active cursor to the wrapped function, and ensuring
    that any changes are commited before closing the connection.

    Any functions decorated by this class should expect a cursor object as
    their first argument, other arguments will be preserved, as will any
    return values.

    """
    def __init__(self, wrapped=None):
        self.debug = 0
        self.dbfile = DATABASE_FILE
        self.conn = None
        self.cursor = None
        self.error = None
        self.wrapped = wrapped

    def __call__(self, *args, **kwargs):
        self.connect()
        results = self.wrapped(self.cursor, *args, **kwargs)
        self.disconnect()
        return results

    def commit(self):
        """
        Commit any pending changes without closing the connection.
        """
        if self.conn is not None:
            self.conn.commit()
        return

    def connect(self):
        """
        Open a connection to the database, do initial setup including
        creating tables if they don't already exist.
        """
        self.conn = sqlite3.connect(self.dbfile)
        #self.conn.text_factory = sqlite3.OptimizedUnicode
        self.conn.text_factory = str
        self.conn.row_factory = sqlite3.Row
        self.cursor = self.conn.cursor()
        self.cursor.executescript(INIT)
        self.conn.commit()
        return

    def disconnect(self):
        """
        Ensure that any changes are committed before closing the connection.
        """
        if self.cursor:
            self.commit()
            self.cursor.close()
            self.conn.close()
            self.conn = None
            self.cursor = None
        return

    def get_cursor(self):
        """
        Return a cursor object, establish a connection to the database if
        one does not already exist.
        """
        if self.cursor is None:
            self.connect()
        return self.cursor

    def query(self, sql, subs=None):
        """
        Run a query on the database, return True if successful.

        sql -- query to execute

        Keyword Arguments:

        subs -- tuple of values to use in parameter substition
        """
        if self.debug:
            if subs is None:
                print "\nSQL: %s\n" % (sql)
            else:
                print "\nSQL: %s (%s)\n" % (sql, subs)
        if self.cursor is None:
            self.get_cursor()
        try:
            if subs is None:
                self.cursor.execute(sql)
            else:
                self.cursor.execute(sql, subs)
            self.error = None
            return True
        except sqlite3.Error, error:
            self.error = error
        return False


class Table(object):
    """
    This class is an abstraction which allows accessing our tables in a
    more "pythonic" way.

    name -- name of the table to access

    Examples:

    * Access the 'Fonts' table in our database
        fonts = Table('Fonts')
    * Select a column from our table
        fonts['filesize']
    * Get a list of all rows where the family column contains "Sans"
        fonts.get('*', 'family LIKE "%Sans%"')
    * Remove all rows where the family column contains "Sans"
        fonts.remove('family LIKE "%Sans%"')
    * Set search and sort
        fonts.search('family LIKE "%Serif%"')
        fonts.sort('filepath')
    * Iterate through the results
        for font in fonts:
            print font['filepath']
    * Add a row
        fonts.insert('somevalue', 'someothervalue', 'etc')
    * Save changes
        fonts.save()
    * Save changes and close database
        fonts.close()
    """
    def __init__(self, name):
        self.name = name
        self.db = Database()
        self._search = ''
        self._sort = ''

    def __getitem__(self, column):
        """
        __getcolumn__
        """
        return self.get(column)

    def __iter__(self):
        """
        Create a data set, and return an iterator --> "self".
        """
        sql = 'SELECT * FROM %s %s %s' % (self.name, self._search, self._sort)
        if self.db.query(sql):
            return self
        else:
            raise sqlite3.ProgrammingError(self.db.error)

    def __len__(self):
        """
        Return the number of entries in the table.
        """
        sql = 'SELECT count(*) FROM %s %s' % (self.name, self._search)
        if self.db.query(sql):
            results = int(self.db.cursor.fetchone()[0])
            return results
        else:
            raise sqlite3.ProgrammingError(self.db.error)

    def close(self):
        """
        Commit changes and close the database connection.
        """
        self.db.disconnect()
        return

    def get(self, select, search=None, sort=None):
        """
        Query table.

        select -- expression list between the SELECT and FROM keywords

        Keyword Arguments:

        search -- expression list after "WHERE" clause
        sort -- expression list after "ORDER BY" clause

        Returns a list of matching rows.
        """
        self.search(search)
        self.sort(sort)
        subs = (select, self.name, self._search, self._sort)
        sql = 'SELECT %s FROM %s %s %s' % subs
        if self.db.query(sql):
            return self.db.cursor.fetchall()
        else:
            raise sqlite3.ProgrammingError(self.db.error)

    def insert(self, *data):
        """
        Insert a row.

        data -- values or a tuple of values to insert
        """
        if isinstance(data[0], tuple):
            if self.name == 'Fonts':
                placeholder = '(NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
            else:
                placeholder = ('?,' * len(data[0]))[:-1]
            sql = 'INSERT INTO %s VALUES %s' % (self.name, placeholder)
            data = data[0]
        elif isinstance(data[0], str):
            placeholder = ('?,' * len(data))[:-1]
            sql = 'INSERT INTO %s VALUES (%s)' % (self.name, placeholder)
        else:
            raise ValueError('Incorrect argument type or length')
        if self.db.query(sql, data):
            return
        else:
            raise sqlite3.ProgrammingError(self.db.error)

    def next(self):
        """
        Return the next item in "self".
        """
        result = self.db.cursor.fetchone()
        if not result:
            raise StopIteration
        return result

    def remove(self, pattern):
        """
        pattern -- expression list after "WHERE" clause
        """
        sql = 'DELETE FROM %s WHERE %s' % (self.name, pattern)
        if self.db.query(sql):
            return
        else:
            raise sqlite3.ProgrammingError(self.db.error)

    def save(self):
        """
        Commit changes.
        """
        self.db.commit()
        return

    def search(self, pattern):
        """
        pattern -- expression list after "WHERE" clause
                    or None to clear a previous search
        """
        if pattern:
            self._search = 'WHERE %s' % pattern
        else:
            self._search = ''
        return

    def sort(self, pattern):
        """
        pattern -- expression list after "ORDER BY" clause
                    or None to clear a previous sort
        """
        if pattern:
            self._sort = 'ORDER BY %s' % pattern
        else:
            self._sort = ''
        return


def _add_details(metadata, system):
    """
    Add owner information and format foundry name.
    """
    if system and not metadata['filepath'].startswith(HOME):
        metadata['owner'] = 'System'
    elif not system or metadata['filepath'].startswith(HOME):
        metadata['owner'] = 'User'
    foundry = metadata.get('foundry')
    if foundry is None:
        foundry = 'unknown'
    if foundry != 'unknown':
        foundry = foundry.strip()
        if len(foundry) < 4:
            foundry = foundry.upper()
        else:
            foundry = foundry.capitalize()
    metadata['foundry'] = foundry
    return metadata

def _drop_indexed(available, indexed):
    """
    Remove files which are already in database from list of files
    to be updated.
    """
    new_files = []
    for dic in available:
        for filepath in dic.iterkeys():
            if filepath in indexed:
                continue
            else:
                new_files.append(dic)
    return new_files

def _get_details(filedict, system=False):
    """
    Use FreeType2 to load each file and gather information about it.

    Return a list of dictionaries.
    """
    details = []
    for font, foundry in _get_file_details(filedict):
        for index in range(_fontutils.FT_Get_Face_Count(font)):
            try:
                metadata = _fontutils.FT_Get_File_Info(font, index, foundry)
            except IOError:
                break
            metadata = _add_details(metadata, system)
            metadata = _pad_metadata(metadata)
            details.append(metadata)
    return details

def _get_file_details(filedict):
    """
    Generator that returns path and vendor for every file in a dict.
    """
    for filepath in filedict:
        for font, foundry in filepath.iteritems():
            yield font, foundry
    return

def _get_row_data(font):
    """
    Return a tuple suitable for sqlite parameter substition.
    """
    row_data = []
    for i in range(14):
        row_data.append(font[FIELDS[i]])
    row_data = tuple(row_data)
    return row_data

def _pad_metadata(metadata):
    """
    Fill any empty fields with 'None'.
    """
    for field in FIELDS:
        if not metadata.get(field):
            metadata[field] = 'None'
    return metadata


def sync():
    """
    Use FontConfig to find installed fonts.

    Open each one using FreeType2 and gather information about it,
    but only if file is not already in the database. Then populate or
    update the database.
    """

    def _get_indexed_files():
        """
        Return a list of any files already in the database.
        """
        paths = []
        for row in table['filepath']:
            paths.append(row[0])
        return paths

    def _need_update():
        available = _fontutils.FcFileList()
        indexed = _get_indexed_files()
        update = _drop_indexed(available, indexed)
        return available, indexed, update

    def _sync(system=False):
        fontdetails = _get_details(update, system)
        for font in fontdetails:
            table.insert(_get_row_data(font))
        return

    table = Table('Fonts')
    # 'System' fonts
    _fontutils.FcEnableHomeConfig(False)
    update = _need_update()[2]
    if len(update) > 0:
        delete_cache()
    _sync(True)
    # 'User' fonts
    _fontutils.FcEnableHomeConfig(True)
    available, indexed, update = _need_update()
    if len(update) > 0 or len(available) != len(indexed):
        delete_cache()
    _sync(False)
    table.close()
    return

