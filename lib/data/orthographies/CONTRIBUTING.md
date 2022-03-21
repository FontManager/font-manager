#### The data in these files was originally compiled for the [Fontaine Project](http://www.unifont.org/fontaine/) by Edward H. Trager


Please feel free to improve these files and file a pull request but make sure to include a rationale for any edits.



#### Creating a new Orthography file


An orthography consists of a simple C structure :

```
{
    "Name",
    "Native Name",
    Key Codepoint,
    "Sample string",
    {
        "Pangram 1",
        "Pangram 2",
        FONT_MANAGER_END_OF_DATA
    },
    {
        Codepoint,
        Another Codepoint,
        FONT_MANAGER_START_RANGE_PAIR,
        Starting Codepoint, Ending Codepoint,
        Some More Codepoints,
        FONT_MANAGER_END_OF_DATA
    }
},
```

Key Codepoint - the orthography can not be supported without this codepoint.

The array of pangrams can contain up to 9 - they are not currently used anywhere but may be in the future.

The array of codepoints can contain up to 4095 codepoints.

The special value FONT_MANAGER_START_RANGE_PAIR indicates that the next two codepoints represent a range and everything between them should be included in the orthography.

The special value FONT_MANAGER_END_OF_DATA marks the end of an array.

The filename should match Name with spaces removed.

An empty string "" can be used in place of a sample or pangram.



