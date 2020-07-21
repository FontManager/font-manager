
public static int main (string [] args) {

    Test.init(ref args);
    TestSuite root = TestSuite.get_root();

    /* BEGIN FONTCONFIG TESTING */
    root.add_suite(new TestAliasElement().get_suite());
    root.add_suite(new TestAliases().get_suite());
    root.add_suite(new TestDirectories().get_suite());
    root.add_suite(new TestReject().get_suite());
    root.add_suite(new TestSource().get_suite());
    root.add_suite(new TestSources().get_suite());
    /* END FONTCONFIG TESTING */

    return Test.run();

}
