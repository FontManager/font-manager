//
// Oriya.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ORIYA
#define ORIYA

namespace Oriya{

//
// Unicode values 
//
UINT32 values[]={
	// Oriya - Various signs
	0x0B01, // ( ଁ ) ORIYA SIGN CANDRABINDU
	0x0B02, // ( ଂ ) ORIYA SIGN ANUSVARA
	0x0B03, // ( ଃ ) ORIYA SIGN VISARGA
	// Oriya - Independent vowels
	0x0B05, // ( ଅ ) ORIYA LETTER A
	0x0B06, // ( ଆ ) ORIYA LETTER AA
	0x0B07, // ( ଇ ) ORIYA LETTER I
	0x0B08, // ( ଈ ) ORIYA LETTER II
	0x0B09, // ( ଉ ) ORIYA LETTER U
	0x0B0A, // ( ଊ ) ORIYA LETTER UU
	0x0B0B, // ( ଋ ) ORIYA LETTER VOCALIC R
	0x0B0C, // ( ଌ ) ORIYA LETTER VOCALIC L
	0x0B0F, // ( ଏ ) ORIYA LETTER E
	0x0B10, // ( ଐ ) ORIYA LETTER AI
	0x0B13, // ( ଓ ) ORIYA LETTER O
	0x0B14, // ( ଔ ) ORIYA LETTER AU
	// Oriya - Consonants
	0x0B15, // ( କ ) ORIYA LETTER KA
	0x0B16, // ( ଖ ) ORIYA LETTER KHA
	0x0B17, // ( ଗ ) ORIYA LETTER GA
	0x0B18, // ( ଘ ) ORIYA LETTER GHA
	0x0B19, // ( ଙ ) ORIYA LETTER NGA
	0x0B1A, // ( ଚ ) ORIYA LETTER CA
	0x0B1B, // ( ଛ ) ORIYA LETTER CHA
	0x0B1C, // ( ଜ ) ORIYA LETTER JA
	0x0B1D, // ( ଝ ) ORIYA LETTER JHA
	0x0B1E, // ( ଞ ) ORIYA LETTER NYA
	0x0B1F, // ( ଟ ) ORIYA LETTER TTA
	0x0B20, // ( ଠ ) ORIYA LETTER TTHA
	0x0B21, // ( ଡ ) ORIYA LETTER DDA
	0x0B22, // ( ଢ ) ORIYA LETTER DDHA
	0x0B23, // ( ଣ ) ORIYA LETTER NNA
	0x0B24, // ( ତ ) ORIYA LETTER TA
	0x0B25, // ( ଥ ) ORIYA LETTER THA
	0x0B26, // ( ଦ ) ORIYA LETTER DA
	0x0B27, // ( ଧ ) ORIYA LETTER DHA
	0x0B28, // ( ନ ) ORIYA LETTER NA
	0x0B2A, // ( ପ ) ORIYA LETTER PA
	0x0B2B, // ( ଫ ) ORIYA LETTER PHA
	0x0B2C, // ( ବ ) ORIYA LETTER BA
	0x0B2D, // ( ଭ ) ORIYA LETTER BHA
	0x0B2E, // ( ମ ) ORIYA LETTER MA
	0x0B2F, // ( ଯ ) ORIYA LETTER YA
	0x0B30, // ( ର ) ORIYA LETTER RA
	0x0B32, // ( ଲ ) ORIYA LETTER LA
	0x0B33, // ( ଳ ) ORIYA LETTER LLA
	0x0B35, // ( ଵ ) ORIYA LETTER VA
	0x0B36, // ( ଶ ) ORIYA LETTER SHA
	0x0B37, // ( ଷ ) ORIYA LETTER SSA
	0x0B38, // ( ସ ) ORIYA LETTER SA
	0x0B39, // ( ହ ) ORIYA LETTER HA
	// Oriya - Various signs
	0x0B3C, // ( ଼ ) ORIYA SIGN NUKTA
	0x0B3D, // ( ଽ ) ORIYA SIGN AVAGRAHA
	// Oriya - Dependent vowel signs
	0x0B3E, // ( ା ) ORIYA VOWEL SIGN AA
	0x0B3F, // ( ି ) ORIYA VOWEL SIGN I
	0x0B40, // ( ୀ ) ORIYA VOWEL SIGN II
	0x0B41, // ( ୁ ) ORIYA VOWEL SIGN U
	0x0B42, // ( ୂ ) ORIYA VOWEL SIGN UU
	0x0B43, // ( ୃ ) ORIYA VOWEL SIGN VOCALIC R
	0x0B44, // ( ୄ ) ORIYA VOWEL SIGN VOCALIC RR
	0x0B47, // ( େ ) ORIYA VOWEL SIGN E
	0x0B48, // ( ୈ ) ORIYA VOWEL SIGN AI
	// Oriya - Two-part dependent vowel signs
	0x0B4B, // ( ୋ ) ORIYA VOWEL SIGN O
	0x0B4C, // ( ୌ ) ORIYA VOWEL SIGN AU
	// Oriya - Various signs
	0x0B4D, // ( ୍ ) ORIYA SIGN VIRAMA
	0x0B56, // ( ୖ ) ORIYA AI LENGTH MARK
	0x0B57, // ( ୗ ) ORIYA AU LENGTH MARK
	// Oriya - Additional consonants
	0x0B5C, // ( ଡ଼ ) ORIYA LETTER RRA
	0x0B5D, // ( ଢ଼ ) ORIYA LETTER RHA
	0x0B5F, // ( ୟ ) ORIYA LETTER YYA
	// Oriya - Additional vowels for Sanskrit
	0x0B60, // ( ୠ ) ORIYA LETTER VOCALIC RR
	0x0B61, // ( ୡ ) ORIYA LETTER VOCALIC LL
	// Oriya - Dependent vowels
	0x0B62, // ( ୢ ) ORIYA VOWEL SIGN VOCALIC L
	0x0B63, // ( ୣ ) ORIYA VOWEL SIGN VOCALIC LL
	// Oriya - Digits
	0x0B66, // ( ୦ ) ORIYA DIGIT ZERO
	0x0B67, // ( ୧ ) ORIYA DIGIT ONE
	0x0B68, // ( ୨ ) ORIYA DIGIT TWO
	0x0B69, // ( ୩ ) ORIYA DIGIT THREE
	0x0B6A, // ( ୪ ) ORIYA DIGIT FOUR
	0x0B6B, // ( ୫ ) ORIYA DIGIT FIVE
	0x0B6C, // ( ୬ ) ORIYA DIGIT SIX
	0x0B6D, // ( ୭ ) ORIYA DIGIT SEVEN
	0x0B6E, // ( ୮ ) ORIYA DIGIT EIGHT
	0x0B6F, // ( ୯ ) ORIYA DIGIT NINE
	// Oriya - Oriya-specific additions
	0x0B70, // ( ୰ ) ORIYA ISSHAR
	0x0B71, // ( ୱ ) ORIYA LETTER WA
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"କ ଖ ଗ ଘ ଙ ଚ ଛ ଜ", // sample letters for now ...
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Oriya", // Common name
	"ଓଡ଼ିଆ", // Native name
	0x0B15, // key
	values,
	"କ ଖ ଗ ଘ ଙ ଚ ଛ ଜ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
