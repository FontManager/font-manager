//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009,2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// PanAfricanLatin.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef PANAFRICANLATIN
#define PANAFRICANLATIN

namespace PanAfricanLatin{

//
// Unicode values beyond Basic Latin:
// 
UINT32 values[]={
	0x00D8, // Ø
	0x00F8, // ø
	0x0110, // Đ
	0x0111, // đ
	0x014A, // Ŋ
	0x014B, // ŋ
	0x0152, // Œ
	0x0153, // œ
	0x0181, // Ɓ
	0x0186, // Ɔ
	0x0187, // Ƈ
	0x0188, // ƈ
	0x0189, // Ɖ
	0x018A, // Ɗ
	0x018E, // Ǝ
	0x018F, // Ə
	0x0190, // Ɛ
	0x0191, // Ƒ
	0x0192, // ƒ
	0x0193, // Ɠ
	0x0194, // Ɣ
	0x0196, // Ɩ
	0x0197, // Ɨ
	0x0198, // Ƙ
	0x0199, // ƙ
	0x019D, // Ɲ
	0x01A4, // Ƥ
	0x01A5, // ƥ
	0x01A9, // Ʃ
	0x01AC, // Ƭ
	0x01AD, // ƭ
	0x01AE, // Ʈ
	0x01B1, // Ʊ
	0x01B2, // Ʋ
	0x01B3, // Ƴ
	0x01B4, // ƴ
	0x01B7, // Ʒ
	0x01DD, // ǝ
	0x0241, // Ɂ
	0x0242, // ɂ
	0x0243, // Ƀ
	0x0244, // Ʉ
	0x024B, // ɋ
	0x024C, // Ɍ
	0x0251, // ɑ
	0x0253, // ɓ
	0x0254, // ɔ
	0x0256, // ɖ
	0x0257, // ɗ
	0x0259, // ə
	0x025B, // ɛ
	0x0260, // ɠ
	0x0263, // ɣ
	0x0266, // ɦ
	0x0268, // ɨ
	0x0269, // ɩ
	0x0272, // ɲ
	0x027D, // ɽ
	0x027E, // ɾ
	0x0283, // ʃ
	0x0288, // ʈ
	0x0289, // ʉ
	0x028A, // ʊ
	0x028B, // ʋ
	0x028C, // ʌ
	0x0292, // ʒ
	0x0294, // ʔ
	0x0295, // ʕ
	0x2C64, // Ɽ Unicode 5.0
	0x2C6D, // Ɑ Unicode 5.1
	0x2C72, // Ⱳ Unicode 5.1
	0x2C73, // ⱳ Unicode 5.1
	//
	// modifier letters
	// 
	0x02BC, // ʼ
	0x02C0, // ˀ
	0x02C6, // ˆ
	0x02C7, // ˇ
	0x02CA, // ˊ
	0x02CB, // ˋ
	//
	// combining diacritics above
	// 
	0x0300, // ̀ needs mkmk, can be stacked above mark
	0x0301, // ́ needs mkmk, can be stacked above mark
	0x0302, // ̂ needs mkmk, can be stacked above mark
	0x0303, // ̃ 
	0x0304, // ̄ needs mkmk, can have mark stacked above
	0x0307, // ̇ 
	0x0308, // ̈ needs mkmk, can have mark stacked above
	0x030C, // ̌ needs mkmk, can be stacked above mark
	0x030D, // ̍ 
	0x1DC4, // ᷄ needs mkmk, can be stacked above mark
	0x1DC5, // ᷅ needs mkmk, can be stacked above mark
	0x1DC6, // ᷆ needs mkmk, can be stacked above mark
	0x1DC7, // ᷇ needs mkmk, can be stacked above mark
	//
	// combining diacritics below
	// 
	0x0323, // ̣ shape of 0329 can be variant in Yoruba
	0x0324, // ̤
	0x0329, // ̩
	0x032D, // ̭
	0x0330, // ̰
	0x0331, // ̱
	//
	// combining cedilla
	// 
	0x0327, // ̧, can also be combined with vowels a, e, i, o, u
	//
	// precomposed forms, need anchors too
	// 
	0x00C0, // À
	0x00C1, // Á
	0x00C2, // Â
	0x00C3, // Ã
	0x00C4, // Ä
	0x00C8, // È
	0x00C9, // É
	0x00CA, // Ê
	0x00CB, // Ë
	0x00CC, // Ì
	0x00CD, // Í
	0x00CE, // Î
	0x00CF, // Ï
	0x00D1, // Ñ
	0x00D2, // Ò
	0x00D3, // Ó
	0x00D4, // Ô
	0x00D6, // Ö
	0x00DC, // Ü
	0x00E0, // à
	0x00E1, // á
	0x00E2, // â
	0x00E3, // ã
	0x00E4, // ä
	0x00E8, // è
	0x00E9, // é
	0x00EA, // ê
	0x00EB, // ë
	0x00EC, // ì
	0x00ED, // í
	0x00EE, // î
	0x00EF, // ï
	0x1E2E, // Ḯ
	0x1E2F, // ḯ
	0x00F1, // ñ
	0x00F2, // ò
	0x00F3, // ó
	0x00F4, // ô
	0x00F6, // ö
	0x00FC, // ü
	0x0100, // Ā
	0x0101, // ā
	0x0102, // Ă
	0x0103, // ă
	0x010C, // Č
	0x010D, // č
	0x0112, // Ē
	0x0113, // ē
	0x0128, // Ĩ
	0x0129, // ĩ
	0x014C, // Ō
	0x014D, // ō
	0x0160, // Š
	0x0161, // š
	0x0168, // Ũ
	0x0169, // ũ
	0x016A, // Ū
	0x016B, // ū
	0x0170, // Ű
	0x0171, // ű
	0x0174, // Ŵ
	0x0175, // ŵ
	0x01CD, // Ǎ
	0x01CE, // ǎ
	0x01CF, // Ǐ
	0x01D0, // ǐ
	0x01D1, // Ǒ
	0x01D2, // ǒ
	0x01E6, // Ǧ
	0x01E7, // ǧ
	0x0228, // Ȩ
	0x0229, // ȩ
	0x1E04, // Ḅ
	0x1E05, // ḅ
	0x1E0C, // Ḍ
	0x1E0D, // ḍ
	0x1E0E, // Ḏ
	0x1E0F, // ḏ
	0x1E12, // Ḓ
	0x1E13, // ḓ
	0x1E24, // Ḥ
	0x1E25, // ḥ
	0x1E36, // Ḷ
	0x1E37, // ḷ
	0x1E3C, // Ḽ
	0x1E3D, // ḽ
	0x1E3E, // Ḿ
	0x1E3F, // ḿ
	0x1E44, // Ṅ
	0x1E45, // ṅ
	0x1E46, // Ṇ
	0x1E47, // ṇ
	0x1E4A, // Ṋ
	0x1E4B, // ṋ
	0x1E4C, // Ṍ
	0x1E4D, // ṍ
	0x1E50, // Ṑ
	0x1E51, // ṑ
	0x1E52, // Ṓ
	0x1E53, // ṓ
	0x1E62, // Ṣ
	0x1E63, // ṣ
	0x1E6C, // Ṭ
	0x1E6D, // ṭ
	0x1E6E, // Ṯ
	0x1E6F, // ṯ
	0x1E70, // Ṱ
	0x1E71, // ṱ
	0x1E80, // Ẁ
	0x1E81, // ẁ
	0x1E82, // Ẃ
	0x1E83, // ẃ
	0x1E84, // Ẅ
	0x1E85, // ẅ
	0x1E92, // Ẓ
	0x1E93, // ẓ
	0x1EA0, // Ạ
	0x1EA1, // ạ
	0x1EAC, // Ậ
	0x1EAD, // ậ
	0x01DE, // Ǟ
	0x01DF, // ǟ
	0x1EB8, // Ẹ
	0x1EB9, // ẹ
	0x1EBC, // Ẽ
	0x1EBD, // ẽ
	0x1EC6, // Ệ
	0x1EC7, // ệ
	0x1ECA, // Ị
	0x1ECB, // ị
	0x1ECC, // Ọ
	0x1ECD, // ọ
	0x1ED8, // Ộ
	0x1ED9, // ộ
	0x022A, // Ȫ
	0x022B, // ȫ
	0x01FF, // ǿ
	0x01FE, // Ǿ
	0x1EE4, // Ụ
	0x1EE5, // ụ
	0x1EF2, // Ỳ
	0x1EF3, // ỳ
	// 2011.04.18.ET Addenda based on Denis Jacquerye <moyogo@gmail.com>
	// email of 2010.12.01
	0x019F, // Ɵ
	0x0275, // ɵ
	0xA78D, // Ɥ
	0x0265, // ɥ
	0xA78B, // Ꞌ
	0xA78C, // ꞌ
	0x0166, // Ŧ
	0x0167, // ŧ
	//
	// 2011.04.19.ET Additional code points from Anloc's 
	// charlist.txt of 2010.12.01:
	// 
	0x00D5, // Õ
	0x00D9, // Ù
	0x00DA, // Ú
	0x00DB, // Û
	0x00DD, // Ý
	0x00F5, // õ
	0x00F9, // ù
	0x00FA, // ú
	0x00FB, // û
	0x00FD, // ý
	0x011A, // Ě
	0x011B, // ě
	0x011C, // Ĝ
	0x011D, // ĝ
	0x0120, // Ġ
	0x0121, // ġ
	0x012A, // Ī
	0x012B, // ī
	0x0131, // ı
	0x0143, // Ń
	0x0144, // ń
	0x0176, // Ŷ
	0x0177, // ŷ
	0x017D, // Ž
	0x017E, // ž
	0x01D3, // Ǔ
	0x01D4, // ǔ
	0x01F8, // Ǹ
	0x01F9, // ǹ
	0x024D, // ɍ
	0x0267, // ɧ
	0x02BF, // ʿ
	0x02D7, // ˗
	0x02EE, // ˮ
	0x1E5A, // Ṛ
	0x1E5B, // ṛ
	0xA789, // ꞉
	0xA78A, // ꞊
	0x0245, // Ʌ	
	//
	// 2011.02.01.ET addendum based on email from Daniel Johnson:
	//
	0xA7AA, // Ɦ H with hook
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Pan African Latin sentence placeholder ...",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Pan African Latin", // Common name
	"Pan African Latin", // Native name
	0x00C0, // KEY = LATIN LETTER A WITH GRAVE
	values,
	"ÀÁẬậíîȪȫ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
