/* LanguageData.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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
        public string label;
        public string name;
        public string sample;
    }

    // Sample strings used here should be sourced from https://fonts.google.com/
    public const LanguageData [] Languages = {
        { N_("Adlam"), "adlam", "𞤚𞤵𞥅𞤺𞤢𞥄𞤣𞤫 𞤱𞤮𞤲𞤣𞤫 𞤸𞤫𞤬𞤼𞤭𞤲𞤺𞤮𞤤 𞤸𞤮𞤪𞤥𞤢 𞤳𞤢𞤤𞤢 𞤲𞤫𞤯𞥆𞤮 𞤫" },
        { N_("Anatolian Hieroglyphs"), "anatolian-heiroglyphs", "𔗷𔗬𔑈𔓯𔐤𔗷𔖶𔔆𔗐𔓱𔑣𔓢𔑈𔓷𔖻𔗔𔑏𔖱𔗷𔖶𔑦𔗬𔓯𔓷 𔖖𔓢𔕙𔑯𔗦 𔖪𔖱𔖪 𔑮𔐓𔗵𔗬 𔐱𔕬𔗬𔑰𔖱" },
        { N_("Arabic"), "arabic", "الحب سماء لا تمطر غير الأحلام." },
        { N_("Armenian"), "armenian", "Քանզի մարդկային ընտանիքի բոլոր անդամներին" },
        { N_("Avestan"), "avestan", "𐬞𐬎𐬭𐬕𐬍𐬝 𐬛𐬁𐬢𐬁 𐬋 𐬨𐬀𐬌𐬢𐬌𐬌𐬋 𐬑𐬀𐬭𐬛 𐬐𐬎" },
        { N_("Balinese"), "balinese", "ᬫᬦᬶᬫ᭄ᬩᬦ᭄ᬕ᭄ ᬭᬶᬅᬦ᭄ᬢᬸᬓᬦ᭄ ᬧᬦ᭄ᬕᬦ᭄ᬕ᭄ᬓᬾᬦ᭄ ᬭᬶᬦ᭄ᬕ᭄ ᬲᬸᬪᬓᬃᬫ" },
        { N_("Bamum"), "bamum", "ꚳꚴ𖥉𖥊𖥋𖥌𖥍 𖡼𖡽𖠀𖠁𖠂𖠃𖠄 𖠎𖠏𖠐𖠑𖠒𖠓𖠔 ꚠꚡꚢꚣꚤꚥꚦ 𖨔𖨕𖨖𖨗𖨘𖨙𖨚 𖠣𖠤𖠥𖠦𖠧𖠨𖠩" },
        { N_("Bassa Vah"), "bassa-vah", "𖫞𖫫𖫰 𖫐𖫭𖫱𖫐𖫗𖫭𖫰𖫞𖫭𖫰 𖫑𖫫𖫱 𖫔𖫬𖫱𖫞𖫬𖫱𖫭𖫱𖫐𖫕𖫭𖫰 𖫔𖫪𖫰𖫐𖫬𖫲𖫐 𖫞𖫫𖫰𖫬𖫱 𖫕𖫨𖫲𖫐𖫪𖫳𖫐𖫕𖫪𖫱" },
        { N_("Batak"), "batak", "ᯘᯮᯂᯮᯖᯉ᯲ᯉᯉ᯲ᯐᯬᯔ᯲ᯅᯤᯇᯪᯂ᯲᯾" },
        { N_("Bengali"), "bengali", "আগুনের শিখা নিভে গিয়েছিল, আর তিনি জানলা দিয়ে তারাদের দিকে তাকালেন৷" },
        { N_("Bhaiksuki"), "bhaiksuki", "𑰧𑰝𑰿𑰨𑱃𑰕𑰐𑰝𑰰𑱃𑰫𑰯𑰡𑰿𑰝𑰰𑰡𑰿𑰧𑰯𑰧𑰭𑰿𑰪𑰯𑰝𑰡𑰿𑰝𑰿𑰨𑰿𑰧𑰯𑰜𑰯𑰽𑱃𑰁𑰠𑰯𑰨𑰾𑱃𑰦𑰯𑰡𑰪𑰢𑰨𑰰𑰪𑰯𑰨𑰭𑰿𑰧𑱃𑰭𑰨𑰿𑰪𑰸𑰬𑰯𑰦𑰢𑰰𑱃𑰭𑰟𑰭" },
        { N_("Brahmi"), "brahmi", "𑀫𑀦 𑀱𑀩𑀩 𑀫𑀯𑀥𑀬𑀢𑀅 𑀩𑀅𑀬𑀔𑀭𑀅 𑀰𑀭𑀰𑀦𑀬𑀅 𑀮𑀓𑀮𑀳 𑀳𑀥𑀫𑀅 𑀥𑀓" },
        { N_("Braille"), "braille", "⠁⠇⠇ ⠓⠥⠍⠁⠝ ⠃⠑⠊⠝⠛⠎ ⠁⠗⠑ ⠃⠕⠗⠝ ⠋⠗⠑⠑ ⠁⠝⠙ ⠑⠟⠥⠁⠇" },
        { N_("Buginese"), "buginese", "Pura ritimbang nasengnge dipattongengngi" },
        // { N_("Buhid"), "buhid", "" },
        { N_("Caucasian Albanian"), "caucasian-albanian", "𐕗𐕘𐕙𐔷𐔸𐔹𐔺 𐔻𐔼𐔽𐕌𐕍𐕎𐕏 𐕂𐕃𐕄𐕅𐕆𐕇𐕈 𐔰𐔱𐔲𐔳𐔴𐔵𐔶 𐕡𐕢𐕣𐔾𐔿𐕀𐕁 𐕉𐕊𐕋𐕚𐕛𐕜𐕝" },
        { N_("Canadian Aboriginal"), "canadian-aboriginal", "ᐃᒪᐃᒻᒪᑦ ᐃᓕᑕᖅᓯᒪᐅᑎᖃᑦᒪᑦ ᓯᕗᓕᕐᓂᓴᑐᖃᕐᓂᒃ ᓂᕐᓱᐃᓂᑦᒥᒃ" },
        { N_("Carian"), "carian", "𐊪𐊾𐊠𐊽𐊾𐊲𐊸𐊫𐊷𐋉𐋃𐊷𐊲𐊷𐊲𐊰𐊫𐋇𐊫𐊰𐊪𐊫𐊣" },
        { N_("Chakma"), "chakma", "𑄡𑄨𑄠𑄚𑄧𑄖𑄳𑄠𑄬 𑄟𑄚𑄬𑄭 𑄉𑄨𑄢𑄨𑄢𑄴 𑄝𑄬𑄇𑄴𑄅𑄚𑄧𑄖𑄳𑄠𑄴 𑄥𑄧𑄁 𑄃𑄮 𑄑𑄚𑄑𑄚𑄳𑄠𑄴 𑄝𑄚𑄝𑄚𑄳𑄠𑄴 𑄃𑄇𑄴𑄇𑄥𑄁𑄃𑄚𑄩" },
        { N_("Cham"), "cham", "ꨢꨓꨴ ꨎꨈꨓꨪ ꨦꨩꩆꨓꨪꨘꨳꨩꨢꨧꨶꨩꨓꩆꨓꨴꨳꨩꨘꨩꩌ ꨀꨩꨖꨩꨣꩍ ꨠꨩꨘꨥꨚꨣꨪꨥꨩꨣꨧꨳ ꨧꨣꨶꨯꨮꨦꨩꨠꨚꨪ ꨧꨕꨧꨳꨩꨘꨩꩌ" },
        { N_("Cherokee"), "cherokee", "ᎠᎣᎤᎴᎺᎾᏃᏆᏒᏔᏣᏫᏲᏴ" },
        { N_("Chinese (Hong Kong)"), "chinese-hongkong", "他們所有的設備和儀器彷彿都是有生命的。" },
        { N_("Chinese (Simplified)"), "chinese-simplified", "他们所有的设备和仪器彷佛都是有生命的。" },
        { N_("Chinese (Traditional)"), "chinese-traditional", "他們所有的設備和儀器彷彿都是有生命的。" },
        { N_("Chorasmian"), "chorasmian", "𐾽𐾾 𐾿𐾲𐾲 𐾽𐾶𐾴𐾺𐿄𐾰 𐾲𐾰𐾺𐾻𐿂𐾰 𐿃𐿂𐿃𐾾𐾺𐾰 𐾼𐾻𐾼𐾵 𐾵𐾴𐾽𐾰 𐾴𐾻" },
        { N_("Coptic"), "coptic", "لمّا كان الاعتراف بالكرامة المتأصلة في جميع" },
        { N_("Cuneiform"), "cuneiform", "𒆪𒌋𒀭𒆷𒈦𒇻𒀭𒆘𒀀𒁺𒀭𒀫𒌓𒀭𒈾𒀭𒇸𒀀𒉿𒈝𒀸" },
        { N_("Cypriot"), "cypriot", "𐠀𐠜𐠍𐠚 𐠃𐠙𐠪𐠒𐠚 𐠰𐠜𐠙𐠪𐠎𐠡𐠦𐠚 𐠰𐠛 𐠅𐠮𐠣𐠚 𐠊𐠩 𐠰𐠩 𐠊𐠪𐠋𐠚𐠰𐠩" },
        { N_("Cypro Minoan"), "cypro-minoan", "𒾙𒾚𒾛𒾜𒾝𒾞𒾟𒾠𒾡𒾢𒾣𒾤𒾥𒾦𒾧𒾨𒾩𒾪𒾫𒾬𒾭𒾮𒾯𒾰𒾱𒾲𒾳𒾴𒾵𒾶𒾷𒾸𒾹𒾺𒾻𒾼𒾽𒾾𒾿𒿀𒿁𒿂𒿃𒿄𒿅𒿆𒿇𒿈" },
        { N_("Cyrillic"), "cyrillic", "Алая вспышка осветила силуэт зазубренного крыла." },
        { N_("Cyrillic Extended"), "cyrillic-ext", "Видовище перед нашими очима справді вражало." },
        { N_("Deseret"), "deseret", "𐐃𐑊 𐐸𐐷𐐭𐑋𐐲𐑌 𐐺𐐨𐐮𐑍𐑆 𐐪𐑉 𐐺𐐫𐑉𐑌 𐑁𐑉𐐨 𐐰𐑌𐐼 𐐨𐐿𐐶𐐲𐑊 𐐮𐑌" },
        { N_("Devanagari"), "devanagari", "अंतरिक्ष यान से दूर नीचे पृथ्वी शानदार ढंग से जगमगा रही थी ।" },
        { N_("Duployan"), "duployan", "𛱕𛱖𛱗𛱘𛱙𛱚 𛱩𛱪𛱰𛱱𛱲𛱳𛱴 𛰀𛰁𛰂𛰃𛰄𛰅𛰆 𛲔𛲕𛲖𛲗𛲘𛲙𛲜 𛰎𛰏𛰐𛰑𛰒𛰓𛰔 𛱢𛱣𛱤𛱥𛱦𛱧𛱨" },
        { N_("Egyptian Hieroglyphs"), "egyptian-heiroglyphs", "𓈖𓆓 𓊽𓉐𓉐 𓈖𓏲𓇯𓂝𓏴𓃾 𓉐𓃾𓂝𓃻𓁶𓃾 𓌓𓁶𓌓𓆓𓂝𓃾 𓌅𓂧𓌅𓀠 𓀠𓇯𓈖𓃾 𓇯𓂧" },
        { N_("Elbasan"), "elbasan", "𐔟 𐔁𐔀 𐔒𐔎𐔇𐔔 𐔏𐔇 𐔠𐔖 𐔀𐔝𐔎𐔇 𐔟 𐔒𐔁𐔟𐔛𐔌𐔔𐔈 𐔄𐔍𐔝𐔈 𐔝𐔈 𐔗𐔎𐔇𐔐𐔐𐔈" },
        { N_("Elymaic"), "elymaic", "𐿬𐿭 𐿮𐿡𐿡 𐿬𐿥𐿣𐿩𐿵𐿠 𐿡𐿠𐿩𐿲𐿳𐿠 𐿴𐿳𐿴𐿭𐿩𐿠 𐿫𐿪𐿫𐿤 𐿤𐿣𐿬𐿠 𐿣𐿪" },
        { N_("Ethiopic"), "ethiopic", "፤ ምድርም ሁሉ በአንድ ቋንቋና በአንድ ንግግር ነበረች።" },
        { N_("Georgian"), "georgian", "ვინაიდან ადამიანთა ოჯახის ყველა წევრისათვის" },
        { N_("Glagolitic"), "glagolitic", "ⰲⱐⱄⰻ ⰱⱁ ⰾⱓⰴⰻⰵ ⱃⱁⰴⱔⱅⱏ ⱄⱔ ⱄⰲⱁⰱⱁⰴⱐⱀⰻ ⰻ ⱃⰰⰲⱐⱀⰻ" },
        { N_("Gothic"), "gothic", "𐌰𐌻𐌻𐌰𐌹 𐌼𐌰𐌽𐌽𐌰 𐍆𐍂𐌴𐌹𐌷𐌰𐌻𐍃 𐌾𐌰𐌷 𐍃𐌰𐌼𐌰𐌻𐌴𐌹𐌺𐍉 𐌹𐌽 𐍅𐌰𐌹𐍂𐌸𐌹𐌳𐌰𐌹" },
        { N_("Grantha"), "grantha", "𑌯𑌤𑍍𑌰 𑌜𑌗𑌤𑌿 𑌶𑌾𑌨𑍍𑌤𑌿𑌨𑍍𑌯𑌾𑌯𑌸𑍍𑌵𑌾𑌤𑌨𑍍𑌤𑍍𑌰𑍍𑌯𑌾𑌣𑌾𑌂 𑌆𑌧𑌾𑌰𑌃 𑌮𑌾𑌨𑌵𑌪𑌰𑌿𑌵𑌾𑌰𑌸𑍍𑌯 𑌸𑌰𑍍𑌵𑍇𑌷𑌾𑌮𑌪𑌿" },
        { N_("Greek"), "greek", "Ήταν απλώς θέμα χρόνου." },
        { N_("Greek Extended"), "greek-ext", "Ήταν απλώς θέμα χρόνου." },
        { N_("Gujarati"), "gujarati", "અમને તેની જાણ થાય તે પહેલાં જ, અમે જમીન છોડી દીધી હતી." },
        { N_("Gunjala Gondi"), "gunjala-gondi", "𑵺𑶌𑵭 𑶀𑶌𑵭𑵳 𑶅𑶍𑵽-𑵶𑶂𑶗𑵰𑶋" },
        { N_("Gurmukhi"), "gurmukhi", "ਸਵਾਲ ਸਿਰਫ਼ ਸਮੇਂ ਦਾ ਸੀ।" },
        { N_("Hanifi Rohingya"), "hanifi-rohingya", "𐴀𐴞𐴕𐴐𐴝𐴦𐴕 𐴁𐴠𐴒𐴧𐴟𐴕 𐴀𐴝𐴎𐴝𐴊𐴢 𐴀𐴝𐴌 𐴀𐴠𐴑𐴧𐴟 𐴉𐴟𐴥𐴖𐴝𐴙𐴕𐴝" },
        { N_("Hanunoo"), "hanunoo", "ᜣᜩᜳᜥ ᜩᜰᜳᜧᜳᜥ ᜵ ᜣᜲᜦ ᜢᜨ ᜫᜣᜪ ᜵" },
        { N_("Hatran"), "hatran", "𐣬𐣭 𐣮𐣡𐣡 𐣬𐣥𐣣𐣩𐣵𐣠 𐣡𐣠𐣩𐣲𐣣𐣠 𐣴𐣣𐣴𐣭𐣩𐣠 𐣫𐣪𐣫𐣤 𐣤𐣣𐣬𐣠 𐣣𐣪" },
        { N_("Hebrew"), "hebrew", "אז הגיע הלילה של כוכב השביט הראשון." },
        { N_("Imperial Aramaic"), "imperial-aramaic", "𐡌𐡍 𐡎𐡁𐡁 𐡌𐡅𐡃𐡉𐡕𐡀 𐡁𐡀𐡉𐡒𐡓𐡀 𐡔𐡓𐡔𐡍𐡉𐡀 𐡋𐡊𐡋𐡄 𐡄𐡃𐡌𐡀 𐡃𐡊" },
        { N_("Indic Siyaq Numbers"), "indic-siyac-numbers", "𞲝𞲞𞲟𞲠𞲡 𞲆𞲇𞲈𞲉𞲊𞲋𞲌 𞱸𞲂𞲃𞲄𞲅 𞲘 ا٠١٢٣٤٥" },
        { N_("Inscriptional Pahlavi"), "inscriptional-pahlavi", "𐭬𐭭 𐭮𐭡𐭡 𐭬𐭥𐭣𐭩𐭲𐭠 𐭡𐭠𐭩𐭬𐭥𐭠 𐭱𐭥𐭱𐭭𐭩𐭠 𐭫𐭪𐭫𐭤 𐭤𐭣𐭬𐭠 𐭣𐭪" },
        { N_("Inscriptional Parthian"), "inscriptional-parthian", "𐭌𐭍 𐭎𐭁𐭁 𐭌𐭅𐭃𐭉𐭕𐭀 𐭁𐭀𐭉𐭒𐭓𐭀 𐭔𐭓𐭔𐭍𐭉𐭀 𐭋𐭊𐭋𐭄 𐭄𐭃𐭌𐭀 𐭃𐭊" },
        { N_("Japanese"), "japanese", "彼らの機器や装置はすべて生命体だ。" },
        { N_("Javanese"), "javanese", "꧋ꦩꦤꦶꦩ꧀ꦧꦁꦩꦤꦮꦲꦏ꧀ꦲꦏ꧀ꦲꦸꦩꦠ꧀ꦩꦤꦸꦁꦱꦥꦼꦂꦭꦸꦲꦤ꧀ꦠꦸꦏ꧀ꦥꦔꦪꦺꦴꦩ꧀ꦩꦤ꧀ꦏꦤ꧀ꦛꦶꦥꦿꦤꦠꦤ꧀ꦭꦤ꧀ꦠꦠꦤꦤ" },
        { N_("Kaithi"), "kaithi", "𑂉𑂍 𑂃𑂠𑂧𑂷 𑂍𑂵 𑂠𑂴 𑂥𑂵𑂗𑂰 𑂩𑂯𑂪 𑃀" },
        { N_("Kannada"), "kannada", "ಇದು ಕೇವಲ ಸಮಯದ ಪ್ರಶ್ನೆಯಾಗಿದೆ." },
        { N_("Kharoshthi"), "kharoshthi", "𐨩𐨟𐨿𐨪 𐨗𐨒𐨟𐨁 𐨭𐨌𐨣𐨿𐨟𐨁𐨣𐨿𐨩𐨌𐨩𐨯𐨿𐨬𐨌𐨟𐨣𐨿𐨟𐨿𐨪𐨿𐨩𐨌𐨞𐨌𐨎 𐨀𐨌𐨢𐨌𐨪𐨏 𐨨𐨌𐨣𐨬𐨤𐨪𐨁𐨬𐨌𐨪𐨯𐨿𐨩 𐨯𐨪𐨿𐨬𐨅𐨮𐨌𐨨𐨤𐨁" },
        { N_("Kawi"), "kawi", "𑽅𑽎𑽅𑼆𑼯𑼒𑽉𑽑𑽒𑽑𑽔𑽉𑼙𑽂𑼫𑼾𑼰𑽂𑼝𑼪𑼴𑼱𑽉" },
        { N_("Kayah Li"), "kayah-li", "ꤒꤟꤢꤧ꤬ꤚꤤ꤬ꤒꤟꤢꤧ꤬ꤊꤛꤢ꤭ ꤘꤣ ꤠꤢ꤭ ꤞꤢꤧꤐꤟꤢꤦ ꤟꤢꤩꤏꤥ꤬ ꤔꤟꤢꤧ꤬ ꤔꤌꤣ꤬ꤗꤢ꤬ ꤢ꤬ꤥ꤬" },
        { N_("Khmer"), "khmer", "ខ្ញុំបានមើលព្យុះ ដែលមានភាពស្រស់ស្អាតណាស់ ប៉ុន្តែគួរឲ្យខ្លាច" },
        { N_("Khojki"), "khojki", "𑈩𑈤𑈨𑈦𑈬𑈺𑈀𑈞𑈩𑈬𑈞𑈺𑈁𑈐𑈶𑈬𑈛𑈺𑈂𑈺𑈀𑈐𑈶𑈙𑈺𑈂𑈺𑈪𑈈𑈶𑈞𑈺𑈑𑈥𑈺𑈪𑈨𑈬𑈧𑈥𑈺𑈈𑈀𑈞" },
        { N_("Khudawadi"), "khudawadi", "𑋝𑋗𑋛𑋙𑋠 𑊰𑋑𑋝𑋠𑋑 𑊱𑋂𑋩𑋠𑋏 𑊲 𑊰𑋂𑋩𑋍 𑊲 𑋞𑊺𑋩𑋑 ڄ𑋘 𑋞𑋛𑋠𑋚𑋘 𑊺𑊰𑋑" },
        { N_("Korean"), "korean", "그들의 장비와 기구는 모두 살아 있다." },
        { N_("Lao"), "lao", "ດ້ວຍເຫດວ່າ ການຮັບຮູ້ກຽດຕິສັກອັນມີປະຈຳຢູ່ຕົວບຸກຄົນໃນວົງສະກຸນຂອງມະນຸດທຸກໆຄົນ" },
        { N_("Lepcha"), "lepcha", "᰿᱁᰿ ᰂᰦᰮᰛᰧᰶᰕᰩ ᰂᰦᰮᰛᰧᰶ ᰣᰦᰜᰬᰮᰌᰨ ᰌᰧᰜᰬ" },
        { N_("Latin"), "latin", "Almost before we knew it, we had left the ground." },
        { N_("Latin Extended"), "latin-ext", "Almost before we knew it, we had left the ground." },
        { N_("Limbu"), "limbu", "ᤂᤧ᤹ᤕᤥ ᤁᤢᤴᤔᤢᤵᤔᤠᤸᤗᤧ ᤆᤠ ᤆᤥᤃᤢᤀᤠᤱ ᤐᤡᤖᤢ ᤜᤧᤰᤁᤩᤠᤱ ᤆᤠ ᤛᤢᤶᤒᤠᤰᤆᤧᤴ ᤑᤠ ᤏᤰᤁᤡᤸᤗᤧ ᤛᤢᤶᤒᤠᤰ ᤐᤡᤖᤢᤖᤧᤳᤇ॥" },
        { N_("Linear A"), "linear-a", "𐘀𐘁𐘂𐘃𐘄𐘅𐘆 𐘣𐘤𐘥𐘦𐘧𐘨𐘩 𐚯𐚰𐚱𐚲𐚳𐚴𐚵 𐜟𐜠𐜡𐜢𐜣𐜤𐜥 𐚨𐚩𐚪𐚫𐚬𐚭𐚮 𐛋𐛌𐛍𐛎𐛏𐛐𐛑" },
        { N_("Linear B"), "linear-b", "𐀴𐀪𐀡𐀆𐄀𐁁𐀐𐀄𐄀𐀐𐀩𐀯𐀍𐄀𐀸𐀐 𐃠 𐄈 𐀴𐀪𐀡𐄀𐀁𐀕𐄀𐀡𐀆𐄀𐀃𐀺𐀸 𐃠 𐄇 𐀴𐀪𐀡𐄀𐀐𐀩𐀯𐀍𐄀𐀸𐀐𐄀𐀀𐀢𐄀𐀐𐀏𐀄𐀕𐀜" },
        { N_("Lisu"), "lisu", "ꓞꓳ ꓘꓹ ꓠꓯꓹꓼ ꓢꓲ ꓫꓬ ꓟ ꓙ ꓖꓴ ꓗꓪ ꓟꓬꓱꓽ ꓧꓳꓽ ꓢꓴ ꓠꓬ꓾" },
        { N_("Lycian"), "lycian", "𐊁𐊂𐊚𐊑𐊏𐊚 𐊓𐊕𐊑𐊏𐊀𐊇𐊒 𐊎𐊚𐊏 𐊁𐊓𐊕𐊑𐊏𐊀𐊇𐊀𐊗𐊚 𐊛𐊀𐊏𐊀𐊅𐊀𐊈𐊀 𐊛𐊕𐊓𐊓𐊆𐊍𐊀𐊅𐊆" },
        { N_("Lydian"), "lydian", "𐤠𐤨𐤯𐤦𐤫 𐤫𐤵𐤲𐤦𐤳 𐤲𐤤𐤩𐤷𐤨 𐤱𐤶𐤫𐤳𐤷𐤦𐤱𐤦𐤣 𐤱𐤠𐤨𐤪𐤷 𐤠𐤭𐤯𐤦𐤪𐤰𐤮" },
        { N_("Mahajani"), "mahajani", "𑅙𑅒𑅧𑅕𑅑 𑅬𑅐𑅧𑅯 𑅨𑅭𑅑𑅯𑅐𑅭 𑅕𑅓 𑅰𑅫𑅑 𑅰𑅥𑅰𑅛𑅔𑅧 𑅕𑅓 𑅛𑅧𑅬𑅛𑅐𑅣 𑅗𑅒𑅭𑅯 𑅒𑅭 𑅰𑅬𑅐𑅧" },
        { N_("Malayalam"), "malayalam", "അവരുടെ എല്ലാ ഉപകരണങ്ങളും യന്ത്രങ്ങളും ഏതെങ്കിലും രൂപത്തിൽ സജീവമാണ്." },
        { N_("Mandaic"), "mandaic", "ࡕࡉࡁࡉࡋ ࡓࡌࡀ ࡀࡐࡀࡓࡀ ࡀࡎࡀࡓ ࡏࡅࡕࡓࡀ ࡂࡁࡓࡀ ࡍࡄࡅࡓࡀ ࡁࡓࡀࡄࡉࡌ" },
        { N_("Manichaean"), "manichaean", "𐫖𐫗 𐫘𐫁𐫁 𐫖𐫇𐫅𐫏𐫤𐫀 𐫁𐫀𐫏𐫞𐫡𐫀 𐫢𐫡𐫢𐫗𐫏𐫀 𐫓𐫐𐫓𐫆 𐫆𐫅𐫖𐫀 𐫅𐫐" },
        { N_("Math"), "math", "𝞉𝞩𝟃𞻰⟥⦀⦁ 𝚢𝚣𝚤𝖿𝗀𝗁𝗂 𝑻𝑼𝑽𝗔𝗕𝗖𝗗 ϑϕϰϱϵℊℎ ⊰⊱⊲⊳⊴⊵⫕ 𞹴𞹵𞹶𞹷𞹹𞹺𞹻" },
        { N_("Marchen"), "marchen", "𑲉𑱺𑲪 𑱸𑱴𑱺𑲱 𑲌𑲰𑱽𑲚𑲱𑱽𑲩𑲰𑲉𑲍𑲥𑲰𑱺𑱽𑲚𑲪𑲩𑲰𑱽𑲰𑲵 𑲏𑲰𑱼𑲮𑲰𑲊𑲎 𑲁𑲰𑱽𑲅𑱾𑲊𑲱𑲅𑲰𑲊𑲍𑲩 𑲍𑲊𑲥𑲳𑲌𑲰𑲁𑱾𑲱 𑲍𑱼𑲍𑲩𑲰𑱽𑲰𑲵" },
        { N_("Masaram Gondi"), "masaram-gondi", "𑴫𑴴𑴓𑴧𑴱𑴤𑵄 𑴫𑴴𑴡𑴧𑴱𑴤𑵄 𑴤𑴧𑴥𑴓𑴩𑴳𑴛𑴧𑴱𑴤𑵄 𑴫𑴫𑵅𑴥𑴩𑵅𑴧𑴱𑴤𑴧𑴱𑴤𑵄 𑴤𑴱𑴛𑴦𑴤𑵄 ॥" },
        { N_("Mayan Numerals"), "mayan-numerals", "𝋠𝋡𝋢𝋣𝋤𝋥𝋦 𝋧𝋨𝋩𝋪𝋫𝋬𝋭" },
        { N_("Medefaidrin"), "medefaidrin", "𖹀𖹦𖹻𖹧 𖹻 𖹫𖹠𖹦𖹤 𖹃𖹣𖹫 𖹤𖹨 𖹦𖹻𖹫𖹤 𖹣𖹫 𖹤𖹠 𖹛𖹫 𖹧𖹨𖹫𖹤𖹣 𖹫𖹤𖹣𖹧𖹨" },
        { N_("Meetei Mayek"), "meetei-mayek", "ꯃꯤꯑꯣꯏꯕ ꯈꯨꯗꯤꯡꯃꯛ ꯄꯣꯛꯄ ꯃꯇꯝꯗ ꯅꯤꯡꯇꯝꯃ ꯑꯃꯗꯤ ꯏꯖꯖꯠꯑꯃꯁꯨꯡ ꯍꯛ" },
        { N_("Mende Kikakui"), "mende-kikakui", "𞡥𞠖𞢻𞠢𞠮𞠣 𞢣𞠽 𞡅 𞡄 𞠺 𞡈 𞡗 𞢰𞠎 𞡔 𞡪, 𞡅𞠧 𞡄 𞡥𞢻𞠤 𞡖𞠢 𞠄𞠦" },
        { N_("Meroitic"), "meroitic", "𐦣𐦤𐦥𐦦𐦮𐦯𐦰 𐦀𐦁𐦂𐦃𐦄𐦅𐦆 𐦱𐦲𐦳𐦴𐦵𐦶𐦷 𐦾𐦿𐦧𐦨𐦩𐦪𐦫 𐦑𐦒𐦓𐦔𐦠𐦡𐦢 𐦜𐦝𐦞𐦟𐦎𐦏𐦐" },
        // { N_(""), "meroitic-cursive", "" },
        // { N_(""), "meroitic-heiroglyphs", "" },
        { N_("Miao"), "miao", "𖼐𖽪𖾐 𖼞𖽪 𖼷𖽷 𖽐𖼊𖽪𖾏 𖼷𖽷 𖼊𖽡 𖽐𖼞𖽻𖾏 𖼽𖽘 𖼮𖽷𖾑 𖼨𖽑𖽪𖾐 𖽐𖼊𖽪𖾏 𖼎𖽻 𖼡𖽑𖽔𖾑 𖼀𖽱 𖼎𖽻 𖼡𖽻𖾐 𖽐𖼊𖽪𖾏 𖼀𖽡𖾐 𖼳𖽔𖾐" },
        { N_("Modi"), "modi", "𑘕𑘿𑘧𑘰 𑘀𑘨𑘿𑘞𑘲 𑘦𑘰𑘡𑘪 𑘎𑘳𑘘𑘳𑘽𑘪𑘰𑘝𑘲𑘩 𑘭𑘨𑘿𑘪 𑘪𑘿𑘧𑘎𑘿𑘝𑘲𑘽𑘓𑘲 𑘭𑘿𑘪𑘰𑘥𑘰𑘪𑘲𑘎 𑘢𑘿𑘨𑘝𑘲𑘬𑘿𑘙𑘰 𑘪" },
        { N_("Mongolian"), "mongolian", "ᠬᠦᠮᠦᠨ ᠪᠦᠷ ᠲᠥᠷᠥᠵᠦ ᠮᠡᠨᠳᠡᠯᠡᠬᠦ ᠡᠷᠬᠡ ᠴᠢᠯᠥᠭᠡ ᠲᠡᠢ᠂" },
        { N_("Mro"), "mro", "𖩏𖩖𖩔𖩆𖩊 𖩗𖩖𖩊 𖩍𖩖𖩌 𖩎𖩆𖩁 𖩋𖩖 𖩍𖩖𖩌𖩯" },
        { N_("Multani"), "multani", "𑊡𑊖𑊢 𑊌𑊆𑊖 𑊥𑊚𑊖𑊚𑊡𑊡𑊥𑊤𑊖𑊚𑊖𑊢𑊡𑊕𑊚 𑊀𑊙𑊢𑊦 𑊠𑊚𑊤𑊛𑊢𑊤𑊢𑊥𑊡 𑊥𑊢𑊤𑊥𑊠𑊛" },
        { N_("Music"), "music", "𝄆 𝄙𝆏 𝅗𝅘𝅥𝅘𝅥𝅯𝅘𝅥𝅱 𝄞𝄟𝄢 𝄾𝄿𝄎 𝄴 𝄶𝅁 𝄭𝄰 𝇛𝇜 𝄊 𝄇 𝀸𝀹𝀺𝀻𝀼𝀽 𝈀𝈁𝈂𝈃𝈄𝈅" },
        { N_("Myanmar"), "myanmar", "သူတို့ရဲ့ စက်ပစ္စည်းတွေ၊ ကိရိယာတွေ အားလုံး အသက်ရှင်ကြတယ်။" },
        { N_("Nabataean"), "nabataean", "𐢓𐢔 𐢖𐢃𐢂 𐢓𐢈𐢅𐢍𐢞𐢀 𐢃𐢁𐢍𐢚𐢛𐢀 𐢝𐢛𐢝𐢕𐢍𐢀 𐢑𐢏𐢑𐢆 𐢇𐢅𐢓𐢀 𐢅𐢏" },
        { N_("Nag Mundari"), "nag-mundari", "𞓛𞓐𞓗𞓤𞓨 𞓙𞓐𞓡𞓐𞓢𞓐 𞓢𞓤 𞓧𞓕𞓨𞓣𞓕𞓔 𞓐𞓡𞓐𞓐 𞓕𞓢𞓝𞓚𞓓𞓕𞓣 𞓢𞓐 𞓣𞓤𞓕𞓙 𞓑𞓕𞓚𞓝𞓚𞓗𞓕𞓗𞓕𞓝 𞓣𞓤 𞓖𞓕𞓨𞓕𞓧" },
        { N_("Nandinagari"), "nandinagari", "𑧇𑦽𑧠𑧈 𑦵𑦰𑦽𑧒 𑧋𑧑𑧞𑦽𑧒𑧁𑧠𑧇𑧑𑧇𑧍𑧠𑧊𑧑𑦽𑧞𑦽𑧠𑧈𑧠𑧇𑧑𑦼𑧑𑧞 𑦡𑧀𑧑𑧈𑧟 𑧆𑧑𑧁𑧊𑧂𑧈𑧒𑧊𑧑𑧈𑧍𑧠𑧇 𑧍𑧈𑧠𑧊𑧚𑧌𑧑𑧆𑧂𑧒" },
        { N_("New Tai Lue"), "new-tai-lue", "ᦝᧂᦑᦸᦰ ᦍᦸᧆᦑᦲᧈᦷᦢᦆᧄ ᦅᧀᦂᦱᧂᦐᦸᧂ ᦂᦱᧁ ᦙᦸᧃᦟᦱᧆᦓᧄᧉ ᦶᦙᧈᦷᦎᦶᦂᧄᧉ" },
        { N_("Newa"), "newa", "𑐳𑐎𑐮𑐾𑑄 𑐩𑐣𑐹𑐟 𑐳𑑂𑐰𑐟𑐣𑑂𑐟𑑂𑐬 𑐰 𑐖𑑂𑐰𑐮𑐶𑐖𑑂𑐰𑑅 𑐁𑐟𑑂𑐩𑐳𑐩𑑂𑐩𑐵𑐣 𑐰 𑐰𑐵𑑄 𑐡𑐂𑐎𑐠𑑄 𑐧𑐸𑐂" },
        // { N_(""), "nko", "" },
        { N_("Nüshu"), "nushu", "𛇤𛅰𛈕𛅸𛇃𛆤𛈕 𛇤𛅰𛈕𛅸𛇃𛆤𛈕 𛇤𛅰𛈕𛅸𛇃𛆤𛈕 𛇤𛅰𛈕𛅸𛇃𛆤𛈕 𛇤𛅰𛈕𛅸𛇃𛆤𛈕 " },
        { N_("Ogham"), "ogham", "᚛ᚌᚔᚚ ᚓ ᚈᚔᚄᚓᚇ ᚔᚅ ᚃᚐᚔᚇᚉᚆᚓ᚜ ᚛ᚇᚘᚐ ᚋᚁᚐ ᚌᚐᚄᚉᚓᚇᚐᚉᚆ᚜" },
        { N_("Ol Chiki"), "ol-chiki", "ᱡᱚᱛᱚ ᱞᱮᱠᱟᱱᱚ ᱢᱳᱱᱚ ᱟᱨᱚ ᱚᱫᱷᱤᱠᱟᱨᱚ ᱨᱮᱭᱟᱠᱚ ᱟᱫᱷᱟᱨᱚ ᱨᱮ ᱢᱩᱪᱳᱛᱚ ᱫᱷᱟᱵᱤᱪᱚ ᱥᱣᱚᱛᱚᱱᱛᱨᱚ" },
        { N_("Old Hungarian"), "old-hungarian", "𐲪𐲢𐲙𐲔 𐲥𐲬𐲖𐲦𐲤𐲦𐲬𐲖 𐲌𐲛𐲍𐲮𐲀𐲙 𐲐𐲢𐲙𐲔 𐲯𐲢𐲞𐲦  𐲥𐲀𐲯𐲎 𐲥𐲦𐲙𐲇𐲞𐲂𐲉 𐲘𐲀𐲨𐲤 𐲒𐲀𐲙𐲛𐲤 𐲤𐲨𐲦𐲙 𐲓𐲛𐲮𐲀𐲆 𐲆𐲐𐲙𐲀𐲖𐲦𐲔 𐲘𐲀𐲨𐲀𐲤𐲘𐲤𐲦𐲢 𐲍𐲢𐲍𐲗𐲘𐲤𐲦𐲢𐲆𐲐𐲙𐲀𐲖𐲦𐲀𐲔 𐲍 𐲐𐲒 𐲀 𐲤 𐲐 𐲗 𐲗 𐲖𐲦 𐲀" },
        { N_("Old Italic"), "old-italic", "𐌆𐌀𐌌𐌈𐌉𐌂 𐌈𐌖𐌍 𐌗𐌀𐌓𐌖𐌍 𐌘𐌄𐌓𐌔𐌖 𐌆𐌀𐌌𐌀𐌈𐌉 𐌀𐌉𐌔 𐌑𐌀𐌔 𐌐𐌖𐌉𐌀" },
        { N_("Old North Arabian"), "old-north-arabian", "𐪃𐪌 𐪊𐪈𐪈 𐪃𐪅𐪕𐪚𐪗𐪑 𐪈𐪑𐪚𐪄𐪇𐪑 𐪏𐪇𐪏𐪌𐪚𐪑 𐪁𐪋𐪁𐪀 𐪀𐪕𐪃𐪑 𐪕𐪋" },
        { N_("Old Permic"), "old-permic", "𐍐𐍑𐍒𐍓𐍔𐍕𐍖 𐍞𐍟𐍠𐍡𐍢𐍣𐍤 𐍥𐍦𐍧𐍨𐍩𐍪𐍫 𐍗𐍘𐍙𐍚𐍛𐍜𐍝 𐍬𐍭𐍮𐍯𐍰𐍱𐍲" },
        { N_("Old Persian"), "old-persian", "𐎧𐏁𐎹𐎠𐎼𐏁𐎠𐏐𐎧𐏁𐎹𐎰𐎡𐎹𐏐𐎺𐏀𐎼𐎣𐏐𐎧𐏁𐎠𐎹𐎰𐎡𐎹𐏐" },
        { N_("Old Sogdian"), "old-sogdian", "𐼍𐼏 𐼑𐼂𐼃 𐼍𐼇𐼌𐼊𐼚𐼁 𐼂𐼀𐼊𐼋𐼘𐼁 𐼙𐼘𐼙𐼎𐼊𐼁 𐼌𐼋𐼌𐼅 𐼆𐼌𐼍𐼁 𐼌𐼋" },
        { N_("Old South Arabian"), "old-south-arabian", "𐩣𐩬 𐩪𐩨𐩨 𐩣𐩥𐩵𐩺𐩩𐩱 𐩨𐩱𐩺𐩤𐩧𐩱 𐩦𐩧𐩦𐩬𐩺𐩱 𐩡𐩫𐩡𐩠 𐩠𐩵𐩣𐩱 𐩵𐩫" },
        { N_("Old Turkic"), "old-turkic", "𐱅𐰇𐰼𐰜 𐰆𐰍𐰔 𐰋𐰏𐰠𐰼𐰃 𐰉𐰆𐰑𐰣 𐱁𐰃𐰓𐰤 𐰇𐰔𐰀 𐱅𐰭𐰼𐰃 𐰉𐰽𐰢𐰽𐰺 𐰽𐰺𐰀 𐰘𐰃𐰼 𐱅𐰠𐰃𐰤𐰢𐰾𐰼" },
        { N_("Osage"), "osage", "𐒻𐓲𐓣𐓤𐓪 𐓰𐓘͘𐓤𐓘 𐓷𐓣͘ 𐓘𐓵𐓟 𐓘𐓬𐓘 𐓤𐓘𐓸𐓘 𐓤𐓯𐓣 𐓘𐓵𐓟 𐓘𐓬𐓘 𐓪𐓬𐓸𐓘" },
        { N_("Osmanya"), "osmanya", "𐒛𐒆𐒖𐒒𐒖𐒔𐒖 𐒊𐒖𐒑𐒑𐒛𐒒𐒂𐒕𐒈 𐒓𐒚𐒄𐒓 𐒊𐒖𐒉𐒛 𐒘𐒈𐒖𐒌𐒝 𐒄𐒙𐒇 𐒖𐒔" },
        { N_("Oriya"), "oriya", "ଏହା କେବଳ ଏକ ସମୟ କଥା ହିଁ ଥିଲା." },
        { N_("Pahawh Hmong"), "pahawh-hmong", "𖬑𖬦𖬰 𖬇𖬰𖬧𖬵 𖬁𖬲𖬬 𖬇𖬲𖬤 𖬓𖬲𖬞 𖬐𖬰𖬦 𖬉 𖬘𖬲𖬤 𖬀𖬰𖬝𖬵 𖬔𖬟𖬰 𖬂𖬲𖬤𖬵 𖬅𖬲𖬨𖬵 𖬓𖬲𖬥𖬰 𖬄𖬲𖬟" },
        { N_("Palmyrene"), "palmyrene", "𐡬𐡭 𐡯𐡡𐡡 𐡬𐡥𐡣𐡩𐡶𐡠 𐡡𐡠𐡩𐡳𐡴𐡠 𐡵𐡴𐡵𐡭𐡩𐡠 𐡫𐡪𐡫𐡤 𐡤𐡣𐡬𐡠 𐡣𐡪" },
        { N_("Pau Cin Hau"), "pau-cin-hau", "𑫢𑫪𑫫𑫬𑫭𑫮𑫯 𑫸𑫱𑫲𑫳𑫴𑫵𑫶 𑫔𑫜𑫝𑫞𑫟𑫠𑫡 𑫀𑫁𑫂𑫃𑫄𑫅𑫆 𑫰𑫕𑫖𑫗𑫘𑫙𑫚 𑫣𑫤𑫥𑫦𑫧𑫨𑫩" },
        { N_("Phags Pa"), "phags-pa", "ꡗ ꡈꡱ ᠂ ꡒ ꡂ ꡈꡞ ᠂ ꡚꡖꡋ ꡈꡞꡋꡨꡖ ꡗꡛꡧꡖ ꡈꡋ ꡈꡱꡨꡖ ꡳꡬꡖ" },
        { N_("Phoenician"), "phoenician", "𐤌𐤍 𐤎𐤁𐤁 𐤌𐤅𐤃𐤉𐤕𐤀 𐤁𐤀𐤉𐤒𐤓𐤀 𐤔𐤓𐤔𐤍𐤉𐤀 𐤋𐤊𐤋𐤄 𐤄𐤃𐤌𐤀 𐤃𐤊" },
        { N_("Psalter Pahlavi"), "psalter-pahlavi", "𐮋𐮌 𐮍𐮁𐮁 𐮋𐮅𐮃𐮈𐮑𐮀 𐮁𐮀𐮈𐮋𐮅𐮀 𐮐𐮅𐮐𐮌𐮈𐮀 𐮊𐮉𐮊𐮄 𐮄𐮃𐮋𐮀 𐮃𐮉" },
        { N_("Rejang"), "rejang", "ꤰꥈꤳꥎ ꤳꥈꥐ ꤾꥁꥉꥑ ꤸꥎꥑꤴꥉꤰ ꤳ꥓ꤸꥈꥆꥐ ꥁꥋꤰ꥓ꥁꥋꤰ꥓ ꤴꥎ ꤼ꥓ꤽꥊ  ꤰꥈꤳꥎ ꤵꤱꥇꥒꤰ꥓ꤷꥒ ꥆꤰꥎꥒ ꤶꥉꤰꥉꥑ" },
        { N_("Runic"), "runic", "ᚨᛚᛚᚨᛁ ᛗᚨᚾᚾᚨ ᚠᚱᛖᛁᚺᚨᛚᛋ ᛃᚨᚺ ᛋᚨᛗᚨᛚᛖᛁᚲᛟ ᛁᚾ ᚹᚨᛁᚱᚦᛁᛞᚨᛁ" },
        { N_("Samaritan"), "samaritan", "ࠌࠍ ࠎࠁࠁ ࠌࠅࠃࠉࠕࠀ ࠁࠀࠉࠒࠓࠀ ࠔࠓࠔࠍࠉࠀ ࠋࠊࠋࠄ ࠄࠃࠌࠀ ࠃࠊ" },
        { N_("Saurashtra"), "saurashtra", "ꢦꢶꢪ꣄ꢫꢳꢸ ꢚꢵꢞꢸ ꢥꢷꢞꢵꢪ꣄ ꢫꢶꢭ꣄ꢭꣁ ꢐꢠ꣄ꢜꢾꢥꣁ ꢨꢶꢱꢶꢬꢾꢱ꣄," },
        { N_("Sharada"), "sharada", "𑆪𑆠𑇀𑆫 𑆘𑆓𑆠𑆴 𑆯𑆳𑆤𑇀𑆠𑆴𑆤𑇀𑆪𑆳𑆪𑆱𑇀𑆮𑆳𑆠𑆤𑇀𑆠𑇀𑆫𑇀𑆪𑆳𑆟𑆳𑆁 𑆄𑆣𑆳𑆫𑆂 𑆩𑆳𑆤𑆮𑆥𑆫𑆴𑆮𑆳𑆫𑆱𑇀𑆪 𑆱𑆫𑇀𑆮𑆼𑆰𑆳𑆩𑆥𑆴" },
        { N_("Shavian"), "shavian", "𐑢𐑺𐑨𐑟 𐑮𐑧𐑒𐑩𐑜𐑯𐑦𐑖𐑩𐑯 𐑝 𐑞 𐑦𐑯𐑣𐑧𐑮𐑩𐑯𐑑 𐑛𐑦𐑜𐑯𐑦𐑑𐑦 𐑯 𐑝" },
        { N_("Siddham"), "siddham", "𑖧𑖝𑖿𑖨 𑖕𑖐𑖝𑖰 𑖫𑖯𑖡𑖿𑖝𑖰𑖡𑖿𑖧𑖯𑖧𑖭𑖿𑖪𑖯𑖝𑖡𑖿𑖝𑖿𑖨𑖿𑖧𑖯𑖜𑖯𑖽 𑖁𑖠𑖯𑖨𑖾 𑖦𑖯𑖡𑖪𑖢𑖨𑖰𑖪𑖯𑖨𑖭𑖿𑖧 𑖭𑖨𑖿𑖪𑖸𑖬𑖯𑖦𑖢𑖰" },
        { N_("SignWriting"), "signwriting", "𝧿𝨊𝡝𝪜𝦦𝪬𝡝𝪩𝡝𝪡𝤅" },
        { N_("Sinhala"), "sinhala", "එය කාලය පිළිබඳ ප්‍රශ්නයක් පමණක් විය." },
        { N_("Sogdian"), "sogdian", "𐼺𐼻 𐼼𐼱𐼱 𐼺𐼴𐼹𐼷𐽂𐼰 𐼱𐼰𐼷𐼸𐽀𐼰 𐽁𐽀𐽁𐼻𐼷𐼰 𐽄𐼸𐽄𐼳 𐼳𐼹𐼺𐼰 𐼹𐼸" },
        { N_("Sora Sompeng"), "sora-sompeng", "𑃜𑃑𑃝 𑃠𑃕𑃑𑃤 𑃐𑃠𑃢𑃙𑃑𑃤𑃙𑃜𑃢𑃜𑃐𑃚𑃢𑃑𑃙𑃑𑃝𑃜𑃢𑃙𑃨𑃢𑃖 𑃢𑃔𑃨𑃠𑃢𑃝𑃞" },
        { N_("Soyombo"), "soyombo", "𑩻𑩫𑪙𑩼 𑩣𑩞𑩫𑩑 𑩿𑩛𑩯𑪙𑩫𑩑𑩯𑪙𑩻𑩛𑩻𑪁𑪙𑩾𑩛𑩫𑩯𑪙𑩫𑪙𑩼𑪙𑩻𑩛𑩪𑩛𑪖 𑩐𑩛𑩮𑩛𑩼𑪗" },
        { N_("Sundanese"), "sundanese", "ᮚᮒᮢ ᮏᮌᮒᮤ ᮯᮔ᮪ᮒᮤᮔᮡᮚᮞ᮪ᮝᮒᮔ᮪ᮒᮢᮡᮔᮀ ᮃᮓᮛᮂ ᮙᮔᮝᮕᮛᮤᮝᮛᮞᮡ ᮞᮁᮝᮨᮯᮙᮕᮤ ᮞᮓᮞᮡᮔᮀ" },
        { N_("Syloti Nagri"), "syloti-nagri", "ꠎꠔ꠆ꠞ ꠎꠉꠔꠤ ꠡꠣꠘ꠆ꠔꠤꠘ꠆ꠎꠣꠎꠡ꠆ꠛꠣꠔꠘ꠆ꠔ꠆ꠞ꠆ꠎꠣꠘꠣꠋ ꠀꠗꠣꠞꠢ꠆ ꠝꠣꠘꠛꠙꠞꠤꠛꠣꠞꠡ꠆ꠎ ꠡꠞ꠆ꠛꠦꠡꠣꠝꠙꠤ" },
        // { N_("Symbols"), "symbols", "" },
        { N_("Syriac"), "syriac", "ܟܠ ܒܪܢܫܐ ܒܪܝܠܗ ܚܐܪܐ ܘܒܪܒܪ ܓܘ ܐܝܩܪܐ ܘܙܕܩܐ." },
        { N_("Tagalog"), "tagalog", "ᜀᜅ᜔ ᜎᜑᜆ᜔ ᜅ᜔ ᜆᜂᜌ᜔ ᜁᜐᜒᜈᜒᜎᜅ᜔ ᜈ ᜋᜎᜌ ᜀᜆ᜔ ᜉᜈ᜔ᜆᜌ᜔ᜉᜈ᜔ᜆᜌ᜔ ᜐ ᜃᜇᜅᜎᜈ᜔" },
        { N_("Tagbanwa"), "tagbanwa", "ᝬᝦᝮ ᝧᝤᝦᝲ ᝰᝨᝦᝲᝨᝬᝬᝰᝯᝦᝨᝦᝮᝬᝨᝫ ᝠᝧᝮᝣ ᝫᝨᝯᝩᝮᝲᝯᝮᝰᝬ ᝰᝮᝯᝲᝰᝫᝩᝲ" },
        { N_("Tai Le"), "tai-le", "ᥓᥣᥳ ᥞᥨᥛ ᥑᥤᥴ ᥘᥤ ᥞᥨᥛ ᥓᥨᥛᥰ ᥓᥣᥳ ᥙᥣᥰ ᥘᥤ ᥑᥤᥴ ᥙᥣᥰ" },
        { N_("Tamil"), "tamil", "அந்திமாலையில், அலைகள் வேகமாக வீசத் தொடங்கின." },
        { N_("Telugu"), "telugu", "ఆ రాత్రి మొదటిసారిగా ఒక నక్షత్రం నేలరాలింది." },
        { N_("Thai"), "thai", "การเดินทางขากลับคงจะเหงา" },
        { N_("Tibetan"), "tibetan", "ཁོ་ཚོའི་སྒྲིག་ཆས་དང་ལག་ཆ་ཡོད་ཚད་གསོན་པོ་རེད།" },
        { N_("Vietnamese"), "vietnamese", "Bầu trời trong xanh thăm thẳm, không một gợn mây." }
    };

    public class Sample : Object {

        public string label { get; set; }
        public string name { get; set; }
        public string sample { get; set; }

        public Sample (string lang) {
            // TRANSLATORS : The replacement character here refers to a language name.
            label = _("No sample for %s available").printf(lang);
            name = "unknown";
            sample = _("Please file an issue requesting an update to available samples.");
            foreach (var entry in Languages) {
                if (entry.name != lang)
                    continue;
                label = dgettext(null, entry.label);
                name = entry.name;
                sample = entry.sample;
                break;
            }
        }

    }

    public class SampleModel : Object, ListModel {

        public StringSet? items { get; set; }

        uint n_items = 0;

        construct {
            notify["items"].connect_after(() => {
                items_changed(0, n_items, get_n_items());
                n_items = get_n_items();
            });
        }

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

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/web/google/ui/google-fonts-sample-row.ui")]
    public class SampleRow : Gtk.Box {

        [GtkChild] public unowned Gtk.Label label { get; }
        [GtkChild] public unowned Gtk.Inscription sample { get; }

        public static SampleRow from_item (Object item) {
            var row = new SampleRow();
            var sample = (Sample) item;
            row.label.set_label(dgettext(null, sample.label));
            row.sample.set_markup("<small>%s</small>".printf(sample.sample));
            return row;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/web/google/ui/google-fonts-sample-list.ui")]
    public class SampleList : Gtk.Popover {

        public signal void row_selected (string sample);

        public StringSet items { get; set; }

        public SampleModel model { get; private set; }

        [GtkChild] unowned Gtk.ListBox sample_list;

        construct {
            sample_list.set_selection_mode(Gtk.SelectionMode.NONE);
            widget_set_name(this, "FontManagerGoogleFontsSampleList");
            model = new SampleModel();
            sample_list.bind_model(model, SampleRow.from_item);
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bind_property("items", model, "items", flags);
        }

        [GtkCallback]
        void on_row_activated (Gtk.ListBox list, Gtk.ListBoxRow row) {
            if (row == null)
                return;
            uint position = row.get_index();
            var item = (Sample) model.get_item(position);
            row_selected(item.sample);
            popdown();
            return;
        }

        public void unselect_all () {
            sample_list.unselect_all();
            return;
        }

    }

}

#endif /* HAVE_WEBKIT */

