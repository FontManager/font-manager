/*
*
* Do not edit directly. See build-aux directory
*
*
* Open source license information courtesy of
*
*  //
*  // The Fontaine Font Analysis Project
*  //
*  // Copyright (c) 2009 by Edward H. Trager
*  // All Rights Reserved
*  //
*  // Released under the GNU GPL version 2.0 or later.
*  //
*
* See http://www.unifont.org/fontaine/ for more information.
*
* Special thanks to Edward H. Trager, and of course everyone
* involved with the Open Font Library for all their efforts. :-)
*
* http://www.openfontlibrary.org/
*
*/

G_BEGIN_DECLS

#define MAX_KEYWORD_ENTRIES 25

static const struct
{
    const gchar   *license;
    const gchar   *license_url;
    const gchar   *keywords[MAX_KEYWORD_ENTRIES];
}
LicenseData[] =
{

    {
        "Aladdin Free Public License",
        "http://pages.cs.wisc.edu/~ghost/doc/AFPL/6.01/Public.htm",
        {
            "Aladdin",
            NULL
        }
    },

    {
        "Apache 2.0",
        "http://www.apache.org/licenses/LICENSE-2.0",
        {
            "Apache",
            "Apache License",
            "Apache 2 License",
            NULL
        }
    },

    {
        "Arphic Public License",
        "http://ftp.gnu.org/gnu/non-gnu/chinese-fonts-truetype/LICENSE",
        {
            "ARPHIC PUBLIC LICENSE",
            "Arphic Public License",
            "文鼎公眾授權書",
            "Arphic",
            NULL
        }
    },

    {
        "Bitstream Vera License",
        "http://www-old.gnome.org/fonts/#Final_Bitstream_Vera_Fonts",
        {
            "Bitstream",
            "Vera",
            "DejaVu",
            NULL
        }
    },

    {
        "CC-BY-SA",
        "http://creativecommons.org/licenses/by-sa/3.0/",
        {
            "Creative Commons Attribution ShareAlike",
            "Creative-Commons-Attribution-ShareAlike",
            "Creative Commons Attribution Share Alike",
            "Creative-Commons-Attribution-Share-Alike",
            "Creative Commons BY SA",
            "Creative-Commons-BY-SA",
            "CC BY SA",
            "CC-BY-SA",
            NULL
        }
    },

    {
        "CC-BY",
        "http://creativecommons.org/licenses/by/3.0/",
        {
            "Creative Commons Attribution",
            "Creative-Commons-Attribution",
            "CC BY",
            "CC-BY",
            NULL
        }
    },

    {
        "CC-0",
        "http://creativecommons.org/publicdomain/zero/1.0/",
        {
            "Creative Commons Zero",
            "Creative-Commons-Zero",
            "Creative Commons 0",
            "Creative-Commons-0",
            "CC Zero",
            "CC-Zero",
            "CC 0",
            "CC-0",
            NULL
        }
    },

    {
        "Freeware",
        "http://en.wikipedia.org/wiki/Freeware",
        {
            "freeware",
            "free ware",
            NULL
        }
    },

    {
        "GPL with font exception",
        "http://www.gnu.org/copyleft/gpl.html",
        {
            "LiberationFontLicense",
            "with font exception",
            "Liberation font software",
            "LIBERATION is a trademark of Red Hat",
            "this font does not by itself cause the resulting document to be covered by the GNU",
            NULL
        }
    },

    {
        "GNU General Public License",
        "http://www.gnu.org/copyleft/gpl.html",
        {
            "GPL",
            "GNU Public License",
            "GNU GENERAL PUBLIC LICENSE",
            "GNU General Public License",
            "General Public License",
            "GNU copyleft",
            "GNU",
            "www.gnu.org",
            "Licencia Pública General de GNU",
            "free as in free-speech",
            "free as in free speech",
            "languagegeek.com",
            NULL
        }
    },

    {
        "GNU Lesser General Public License",
        "http://www.gnu.org/licenses/lgpl.html",
        {
            "LGPL",
            "GNU Lesser General Public License",
            "Lesser General Public License",
            NULL
        }
    },

    {
        "GUST Font License",
        "http://tug.org/fonts/licenses/GUST-FONT-LICENSE.txt",
        {
            "GUST",
            NULL
        }
    },

    {
        "IPA",
        "http://opensource.org/licenses/ipafont.html",
        {
            "IPA License",
            "Information-technology Promotion Agency",
            "(IPA)",
            " IPA ",
            NULL
        }
    },

    {
        "M+ Fonts Project License",
        "http://mplus-fonts.sourceforge.jp/webfonts/#license",
        {
            "M+ FONTS PROJECT",
            NULL
        }
    },

    {
        "MIT License",
        "http://www.opensource.org/licenses/mit-license.php",
        {
            "M.I.T.",
            "Software without restriction,",
            NULL
        }
    },

    {
        "Magenta Open License",
        "http://www.ellak.gr/pub/fonts/mgopen/index.en.html#license",
        {
            "MgOpen",
            NULL
        }
    },

    {
        "Monotype Imaging EULA",
        "http://www.fonts.com/info/legal/eula/monotype-imaging",
        {
            "valuable asset of Monotype",
            "Monotype Typography",
            "www.monotype.com",
            NULL
        }
    },

    {
        "SIL Open Font License",
        "http://scripts.sil.org/OFL",
        {
            "OFL",
            "Open Font License",
            "scripts.sil.org/OFL",
            "openfont",
            "open font",
            "NHN Corporation",
            "American Mathematical Society",
            "http://www.ams.org",
            NULL
        }
    },

    {
        "Public Domain (not a license)",
        "http://en.wikipedia.org/wiki/Public_domain",
        {
            "public domain",
            "Public Domain",
            NULL
        }
    },

    {
        "STIX Font License",
        "http://www.aip.org/stixfonts/user_license.html",
        {
            "2007 by the STI Pub Companies",
            "the derivative work will carry a different name",
            NULL
        }
    },

    {
        "Ubuntu Font License 1.0",
        "http://font.ubuntu.com/ufl/ubuntu-font-licence-1.0.txt",
        {
            "Ubuntu Font Licence 1.0",
            "UBUNTU FONT LICENCE Version 1.0",
            NULL
        }
    },

    {
        "License to TeX Users Group for the Utopia Typeface",
        "http://tug.org/fonts/utopia/LICENSE-utopia.txt",
        {
            "The Utopia fonts are freely available; see http://tug.org/fonts/utopia",
            NULL
        }
    },

    {
        "XFree86 License",
        "http://www.xfree86.org/legal/licenses.html",
        {
            "XFree86",
            "X Consortium",
            NULL
        }
    },

    {
        "Unknown License",
        NULL,
        {
            NULL
        }
    },

};

#define LICENSE_ENTRIES G_N_ELEMENTS(LicenseData)

gint get_license_type(const gchar *license, const gchar *copyright, const gchar * url);
gchar * get_license_name (gint license_type);
gchar * get_license_url (gint license_type);

G_END_DECLS
