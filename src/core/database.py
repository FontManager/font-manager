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

from constants import DATABASE_FILE


INIT = """
CREATE TABLE IF NOT EXISTS Fonts
(
uid INTEGER PRIMARY KEY,
{0} TEXT,
{1} TEXT,
{2} TEXT,
{3} TEXT,
{4} TEXT,
{5} TEXT,
{6} TEXT,
{7} TEXT,
{8} TEXT,
{9} TEXT,
{10} TEXT,
{11} TEXT,
{12} TEXT,
{13} TEXT,
{14} TEXT,
{15} TEXT,
{16} TEXT,
{17} TEXT,
{18} TEXT,
{19} TEXT,
{20} TEXT,
{21} TEXT
);
""".format('owner', 'filepath', 'filetype', 'filesize', 'checksum', 'psname',
'family', 'style', 'foundry', 'copyright', 'version', 'description', 'license',
'license_url', 'panose', 'face', 'pfamily', 'pstyle', 'pvariant', 'pweight',
'pstretch', 'pdescr')


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
                print "\nSQL: {0}\n".format(sql)
            else:
                print "\nSQL: {0} ({1})\n".format(sql, subs)
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
        sql = 'SELECT * FROM {0} {1} {2}'.format(self.name,
                                                    self._search, self._sort)
        if self.db.query(sql):
            return self
        else:
            raise sqlite3.ProgrammingError(self.db.error)

    def __len__(self):
        """
        Return the number of entries in the table.
        """
        sql = 'SELECT count(*) FROM {0} {1}'.format(self.name, self._search)
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
        sql = 'SELECT {0} FROM {1} {2} {3}'.format(select, self.name,
                                                self._search, self._sort)
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
            sql = 'INSERT INTO {0} VALUES {1}'.format(self.name, placeholder)
            data = data[0]
        elif isinstance(data[0], str):
            placeholder = ('?,' * len(data))[:-1]
            sql = 'INSERT INTO {0} VALUES ({1})'.format(self.name, placeholder)
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
        sql = 'DELETE FROM {0} WHERE {1}'.format(self.name, pattern)
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
            self._search = 'WHERE {0}'.format(pattern)
        else:
            self._search = ''
        return

    def sort(self, pattern):
        """
        pattern -- expression list after "ORDER BY" clause
                    or None to clear a previous sort
        """
        if pattern:
            self._sort = 'ORDER BY {0}'.format(pattern)
        else:
            self._sort = ''
        return
