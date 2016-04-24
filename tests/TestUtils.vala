
void assert_exists (string filepath) {
    assert(File.new_for_path(filepath).query_exists());
    return;
}

void try_delete (string filepath) {
    /* Try to cleanup */
    try {
        var file = File.new_for_path(filepath);
        file.delete();
    } catch (Error e) {
        if (!(e is FileError.NOENT))
            message("Failed to remove temporary file : %s", e.message);
    }
    return;
}

string get_xmllint_path () {
    string? xmllint = Environment.find_program_in_path("xmllint");
    assert(xmllint != null);
    return xmllint;
}

bool is_valid_xml (string filepath) {
    string cmd = "%s --noout --valid %s".printf(get_xmllint_path(), filepath);
    return (get_command_line_status(cmd) == 0);
}

