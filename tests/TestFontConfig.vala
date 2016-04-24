using FontConfig;

public class TestAccept : FontManager.TestCase {

    string? filepath = null;
    Accept accept;

    public TestAccept () {
        base("FontConfig");
        add_test("Accept::create ", test_create);
        add_test("Accept::save ", test_save);
        add_test("Accept::validate ", test_valid_xml);
        add_test("Accept::load ", test_load);
    }

    public override void set_up () {
        accept = new Accept();
        accept.config_dir = Environment.get_current_dir();
        filepath = accept.get_filepath();
        return;
    }

    public void test_create () {
        assert(accept is Accept);
        return;
    }

    public void test_save () {
        accept.add("monospace");
        accept.add("sans");
        accept.add("serif");
        accept.save();
        assert_exists(filepath);
    }

    public void test_valid_xml () {
        assert(is_valid_xml(filepath));
        return;
    }

    public void test_load () {
        accept.load();
        assert(accept.contains("monospace"));
        assert(accept.contains("sans"));
        assert(accept.contains("serif"));
        try_delete(filepath);
        return;
    }

    public override void tear_down () {
        accept = null;
        filepath = null;
        return;
    }

}

public class TestAliasElement : FontManager.TestCase {

    AliasElement? ae = null;

    public TestAliasElement () {
        base("FontConfig");
        add_test("AliasElement::create ", test_create);
    }

    public override void set_up () {
        ae = new AliasElement(null);
        return;
    }

    public void test_create () {
        assert(ae is AliasElement);
        ae.family = "Test";
        assert(ae.family != null);
        assert(ae.prefer is Gee.HashSet);
        assert(ae.accept is Gee.HashSet);
        assert(ae.default is Gee.HashSet);
        return;
    }

    public override void tear_down () {
        ae = null;
        return;
    }

}

public class TestAliases : FontManager.TestCase {

    string? filepath = null;
    Aliases? aliases = null;

    public TestAliases () {
        base("FontConfig");
        add_test("Aliases::create ", test_create);
        add_test("Aliases::save ", test_save);
        add_test("Aliases::validate ", test_valid_xml);
        add_test("Aliases::load ", test_load);
    }

    public override void set_up () {
        aliases = new Aliases();
        aliases.config_dir = Environment.get_current_dir();
        filepath = aliases.get_filepath();
        return;
    }

    public void test_create () {
        assert(aliases is Aliases);
        assert(aliases.config_dir != null);
        assert(aliases.target_file != null);
        return;
    }

    public void test_save () {
        aliases.add("Test");
        AliasElement ae = aliases["Test"];
        ae.prefer.add("SomeFont");
        ae.prefer.add("SomeOtherFont");
        ae.accept.add("YetAnotherFont");
        ae.default.add("DefaultFont");
        aliases.save();
        return;
    }

    public void test_valid_xml () {
        assert(is_valid_xml(filepath));
        return;
    }

    public void test_load () {
        aliases.load();
        assert(aliases.has_key("Test"));
        AliasElement ae = aliases["Test"];
        assert(ae.family == "Test");
        assert(ae.prefer.contains("SomeFont"));
        assert(ae.prefer.contains("SomeOtherFont"));
        assert(ae.accept.contains("YetAnotherFont"));
        assert(ae.default.contains("DefaultFont"));
        try_delete(filepath);
        return;
    }

    public override void tear_down () {
        aliases = null;
        filepath = null;
        return;
    }

}

public class TestDirectories : FontManager.TestCase {

    string? filepath = null;
    Directories dirs;

    public TestDirectories () {
        base("FontConfig");
        add_test("Directories::create ", test_create);
        add_test("Directories::save ", test_save);
        add_test("Directories::validate ", test_valid_xml);
        add_test("Directories::load ", test_load);
    }

    public override void set_up () {
        dirs = new Directories();
        dirs.config_dir = Environment.get_current_dir();
        filepath = dirs.get_filepath();
        return;
    }

    public void test_create () {
        assert(dirs is Directories);
        return;
    }

    public void test_save () {
        dirs.add("/usr/share/fonts");
        dirs.add("/home/user/.local/fonts");
        dirs.save();
        assert_exists(filepath);
    }

    public void test_valid_xml () {
        assert(is_valid_xml(filepath));
        return;
    }

    public void test_load () {
        dirs.load();
        assert(dirs.contains("/usr/share/fonts"));
        assert(dirs.contains("/home/user/.local/fonts"));
        try_delete(filepath);
        return;
    }

    public override void tear_down () {
        dirs = null;
        filepath = null;
        return;
    }

}

public class TestFamilies : FontManager.TestCase {

    Families families;

    public TestFamilies () {
        base("FontConfig");
        add_test("Families::create ", test_create);
        add_test("Families::update ", test_update);
    }

    public override void set_up () {
        families = new Families();
        return;
    }

    public void test_create () {
        assert(families is Families);
        return;
    }

    public void test_update () {
        assert(families.size == 0);
        families.update();
        assert(families.size > 0);
        return;
    }

    public override void tear_down () {
        families = null;
        return;
    }

}

public class TestReject : FontManager.TestCase {

    string? filepath = null;
    Reject reject;

    public TestReject () {
        base("FontConfig");
        add_test("Reject::create ", test_create);
        add_test("Reject::save ", test_save);
        add_test("Reject::validate ", test_valid_xml);
        add_test("Reject::load ", test_load);
    }

    public override void set_up () {
        reject = new Reject();
        reject.config_dir = Environment.get_current_dir();
        filepath = reject.get_filepath();
        return;
    }

    public void test_create () {
        assert(reject is Reject);
        return;
    }

    public void test_save () {
        reject.add("monospace");
        reject.add("sans");
        reject.add("serif");
        reject.save();
        assert_exists(filepath);
    }

    public void test_valid_xml () {
        assert(is_valid_xml(filepath));
        return;
    }

    public void test_load () {
        reject.load();
        assert(reject.contains("monospace"));
        assert(reject.contains("sans"));
        assert(reject.contains("serif"));
        try_delete(filepath);
        return;
    }

    public override void tear_down () {
        reject = null;
        filepath = null;
        return;
    }

}

public class TestSource : FontManager.TestCase {

    File file = File.new_for_path(Environment.get_current_dir());

    public TestSource () {
        base("FontConfig");
        add_test("Source::create ", test_create);
        add_test("Source::availability ", test_availability);
    }

    public void test_create () {
        var source = new FontConfig.Source(file);
        assert(source is FontConfig.Source);
        return;
    }

    public void test_availability () {
        var source = new FontConfig.Source(file);
        assert(source.available);
        source = null;
        source = new FontConfig.Source(File.new_for_path("/not/available/"));
        assert(!(source.available));
        return;
    }

}

public class TestSources : FontManager.TestCase {

    string? filepath = null;
    Sources? sources = null;

    const string [] test_paths = { "/etc", "/fontsource1", "/fontsource2", "/fontsource3" };

    public TestSources () {
        base("FontConfig");
        add_test("Sources::create ", test_create);
        add_test("Sources::save ", test_save);
        add_test("Sources::validate ", test_valid_xml);
        add_test("Sources::load ", test_load);
    }

    public override void set_up () {
        sources = new Sources();
        sources.config_dir = Environment.get_current_dir();
        sources.active.config_dir = Environment.get_current_dir();
        filepath = sources.get_filepath();
        return;
    }

    public void test_create () {
        assert(sources is Sources);
        return;
    }

    public void test_save () {
        foreach (var p in test_paths)
            sources.add_from_path(p);
        assert(sources.size == test_paths.length);
        sources.save();
        assert_exists(filepath);
    }

    public void test_valid_xml () {
        assert(is_valid_xml(filepath));
        return;
    }

    public void test_load () {
        assert(sources.size == 0);
        sources.load();
        assert(sources.size == test_paths.length);
        foreach (var s in sources)
            assert(s.path in test_paths);
        try_delete(filepath);
        return;
    }

    public override void tear_down () {
        sources = null;
        filepath = null;
        return;
    }

}
