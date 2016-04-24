#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Will be inserted as a comment above the vendor list, if not None
CREDIT = "Various Sources"

# Expected to return [(id, name), ...]
# id is the unique vendor id to match against
# name is the full vendor name
def list_vendors () :
    return [
    (b"ACG", b"Monotype Imaging"),
    (b"B?", b"Bigelow & Holmes"),
    (b"FJ", b"Fujitsu"),
    (b"RICO", b"Ricoh")
    ]
