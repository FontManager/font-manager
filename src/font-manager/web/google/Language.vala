/* Language.vala
 *
 * Copyright (C) 2020 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

#if HAVE_WEBKIT

namespace FontManager.GoogleFonts {

    public struct LanguageData {
        public string display_name;
        public string name;
        public string sample;
    }

    public const LanguageData [] Languages = {
        { N_("Arabic"), "arabic", "الحب سماء لا تمطر غير الأحلام." },
        { N_("Bengali"), "bengali", "আগুনের শিখা নিভে গিয়েছিল, আর তিনি জানলা দিয়ে তারাদের দিকে তাকালেন৷" },
        { N_("Chinese (Hong Kong)"), "chinese-hongkong", "他們所有的設備和儀器彷彿都是有生命的。" },
        { N_("Chinese (Simplified)"), "chinese-simplified", "他们所有的设备和仪器彷佛都是有生命的。" },
        { N_("Chinese (Traditional)"), "chinese-traditional", "他們所有的設備和儀器彷彿都是有生命的。" },
        { N_("Cyrillic"), "cyrillic", "Алая вспышка осветила силуэт зазубренного крыла." },
        { N_("Cyrillic Extended"), "cyrillic-ext", "Видовище перед нашими очима справді вражало." },
        { N_("Devanagari"), "devanagari", "अंतरिक्ष यान से दूर नीचे पृथ्वी शानदार ढंग से जगमगा रही थी ।" },
        { N_("Greek"), "greek", "Ήταν απλώς θέμα χρόνου." },
        { N_("Greek Extended"), "greek-ext", "Ήταν απλώς θέμα χρόνου." },
        { N_("Gujarati"), "gujarati", "અમને તેની જાણ થાય તે પહેલાં જ, અમે જમીન છોડી દીધી હતી." },
        { N_("Gurmukhi"), "gurmukhi", "ਸਵਾਲ ਸਿਰਫ਼ ਸਮੇਂ ਦਾ ਸੀ।" },
        { N_("Hebrew"), "hebrew", "אז הגיע הלילה של כוכב השביט הראשון." },
        { N_("Japanese"), "japanese", "彼らの機器や装置はすべて生命体だ。" },
        { N_("Kannada"), "kannada", "ಇದು ಕೇವಲ ಸಮಯದ ಪ್ರಶ್ನೆಯಾಗಿದೆ." },
        { N_("Khmer"), "khmer", "ខ្ញុំបានមើលព្យុះ ដែលមានភាពស្រស់ស្អាតណាស់ ប៉ុន្តែគួរឲ្យខ្លាច" },
        { N_("Korean"), "korean", "그들의 장비와 기구는 모두 살아 있다." },
        { N_("Latin"), "latin", "Almost before we knew it, we had left the ground." },
        { N_("Latin Extended"), "latin-ext", "Almost before we knew it, we had left the ground." },
        { N_("Malayalam"), "malayalam", "അവരുടെ എല്ലാ ഉപകരണങ്ങളും യന്ത്രങ്ങളും ഏതെങ്കിലും രൂപത്തിൽ സജീവമാണ്." },
        { N_("Myanmar"), "myanmar", "သူတို့ရဲ့ စက်ပစ္စည်းတွေ၊ ကိရိယာတွေ အားလုံး အသက်ရှင်ကြတယ်။" },
        { N_("Oriya"), "oriya", "ଏହା କେବଳ ଏକ ସମୟ କଥା ହିଁ ଥିଲା." },
        { N_("Sinhala"), "sinhala", "එය කාලය පිළිබඳ ප්‍රශ්නයක් පමණක් විය." },
        { N_("Tamil"), "tamil", "அந்திமாலையில், அலைகள் வேகமாக வீசத் தொடங்கின." },
        { N_("Telugu"), "telugu", "ఆ రాత్రి మొదటిసారిగా ఒక నక్షత్రం నేలరాలింది." },
        { N_("Thai"), "thai", "การเดินทางขากลับคงจะเหงา" },
        { N_("Tibetan"), "tibetan", "ཁོ་ཚོའི་སྒྲིག་ཆས་དང་ལག་ཆ་ཡོད་ཚད་གསོན་པོ་རེད།" },
        { N_("Vietnamese"), "vietnamese", "Bầu trời trong xanh thăm thẳm, không một gợn mây." }
    };

    public class Sample : Object {

        public string display_name { get; set; }
        public string name { get; set; }
        public string sample { get; set; }

        public Sample (string lang) {
            foreach (var entry in Languages) {
                if (entry.name == lang) {
                    Object(display_name: entry.display_name, name: entry.name, sample: entry.sample);
                }
            }
        }

    }

    public class SampleModel : Object, GLib.ListModel {

        public StringSet? items {
            get {
                return _items;
            }
            set {
                uint n_items = get_n_items();
                _items = value;
                items_changed(0, n_items, get_n_items());
            }
        }

        StringSet? _items = null;

        public Type get_item_type () {
            return typeof(Sample);
        }

        public uint get_n_items () {
            return items != null ? items.size : 0;
        }

        public Object? get_item (uint position) {
            return new Sample(items[position]);
        }

    }

    public class SampleRow : Gtk.Box {

        public static SampleRow from_item (Object item) {
            var row = new SampleRow() { orientation = Gtk.Orientation.VERTICAL, margin = 6 };
            var sample = (Sample) item;
            var name_label = new Gtk.Label(sample.display_name);
            row.pack_start(name_label, false, false, 2);
            name_label.show();
            var sample_label = new Gtk.Label("<small>%s</small>".printf(sample.sample)) {
                sensitive = false,
                ellipsize = Pango.EllipsizeMode.END,
                use_markup = true
            };
            row.pack_end(sample_label, false, false, 2);
            sample_label.show();
            return row;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-fonts-sample-list.ui")]
    public class SampleList : Gtk.Popover {

        public signal void row_selected (string sample);

        public SampleModel model { get; private set; }

        public StringSet items {
            set {
                model.items = value;
            }
        }

        [GtkChild] Gtk.ListBox sample_list;

        construct {
            sample_list.row_activated.connect((box, row) => {
                if (row == null)
                    return;
                uint position = row.get_index();
                var item = (Sample) model.get_item(position);
                row_selected(item.sample);
            });
            notify["model"].connect((obj, pspec) => {
                sample_list.bind_model(model, SampleRow.from_item);
            });
            model = new SampleModel();
        }

        public void unselect_all () {
            sample_list.unselect_all();
            return;
        }

    }

}

#endif /* HAVE_WEBKIT */
