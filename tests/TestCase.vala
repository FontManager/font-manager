/* TestCase.vala
 *
 * Originally from libgee : https://wiki.gnome.org/action/show/Projects/Libgee
 *
 * This copy contains minor modifications.
 *
/* testcase.vala
 *
 * Copyright (C) 2009 Julien Peeters
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *  Julien Peeters <contact@julienpeeters.fr>
 */

namespace FontManager {

    public abstract class TestCase : Object {

        public delegate void TestMethod ();

        GLib.TestSuite suite;

        /* Need to hold a ref to these */
        TestWrapper [] tests = new TestWrapper[0];

        public TestCase (string name) {
            suite = new GLib.TestSuite(name);
        }

        public void add_test (string name, owned TestMethod test) {
            TestWrapper t = new TestWrapper(name, (owned) test, this);
            tests += t;
            suite.add(new GLib.TestCase(t.name, t.set_up, t.run, t.tear_down ));
        }

        /* Called before every test.run */
        public virtual void set_up () {
            return;
        }

        /* Called after every test.run */
        public virtual void tear_down () {
            return;
        }

        public GLib.TestSuite get_suite () {
            return suite;
        }

        class TestWrapper {

            [CCode (notify = false)]
            public string name { get; private set; }

            TestMethod test;
            TestCase test_case;

            public TestWrapper (string name, owned TestMethod test, TestCase test_case) {
                this.name = name;
                this.test = (owned) test;
                this.test_case = test_case;
            }

            public void set_up (void * fixture) {
                test_case.set_up();
                return;
            }

            public void run (void * fixture) {
                test();
                return;
            }

            public void tear_down (void * fixture) {
                test_case.tear_down();
                return;
            }

        }
    }

}
