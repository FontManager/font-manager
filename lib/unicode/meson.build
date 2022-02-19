
unicode_sources = [
    'unicode-codepoint-list.c',
    'unicode-codepoint-list.h',
    'unicode-character-map.c',
    'unicode-character-map.h',
    'unicode-character-info.c',
    'unicode-character-info.h',
    'unicode-info.c',
    'unicode-info.h',
    'unicode-search-bar.c',
    'unicode-search-bar.h'
]

libunicode = both_libraries('unicode',
                            unicode_sources,
                            dependencies: base_deps,
                            link_with: libfontmanager_gtk)

