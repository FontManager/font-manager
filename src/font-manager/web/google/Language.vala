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

}
