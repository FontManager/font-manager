//
// Malayalam.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MALAYALAM
#define MALAYALAM

namespace Malayalam{

//
// Unicode values 
//
UINT32 values[]={
	// Malayalam - Various signs
	0x0D02, // ( ം ) MALAYALAM SIGN ANUSVARA
	0x0D03, // ( ഃ ) MALAYALAM SIGN VISARGA
	// Malayalam - Independent vowels
	0x0D05, // ( അ ) MALAYALAM LETTER A
	0x0D06, // ( ആ ) MALAYALAM LETTER AA
	0x0D07, // ( ഇ ) MALAYALAM LETTER I
	0x0D08, // ( ഈ ) MALAYALAM LETTER II
	0x0D09, // ( ഉ ) MALAYALAM LETTER U
	0x0D0A, // ( ഊ ) MALAYALAM LETTER UU
	0x0D0B, // ( ഋ ) MALAYALAM LETTER VOCALIC R
	0x0D0C, // ( ഌ ) MALAYALAM LETTER VOCALIC L
	0x0D0E, // ( എ ) MALAYALAM LETTER E
	0x0D0F, // ( ഏ ) MALAYALAM LETTER EE
	0x0D10, // ( ഐ ) MALAYALAM LETTER AI
	0x0D12, // ( ഒ ) MALAYALAM LETTER O
	0x0D13, // ( ഓ ) MALAYALAM LETTER OO
	0x0D14, // ( ഔ ) MALAYALAM LETTER AU
	// Malayalam - Consonants
	0x0D15, // ( ക ) MALAYALAM LETTER KA
	0x0D16, // ( ഖ ) MALAYALAM LETTER KHA
	0x0D17, // ( ഗ ) MALAYALAM LETTER GA
	0x0D18, // ( ഘ ) MALAYALAM LETTER GHA
	0x0D19, // ( ങ ) MALAYALAM LETTER NGA
	0x0D1A, // ( ച ) MALAYALAM LETTER CA
	0x0D1B, // ( ഛ ) MALAYALAM LETTER CHA
	0x0D1C, // ( ജ ) MALAYALAM LETTER JA
	0x0D1D, // ( ഝ ) MALAYALAM LETTER JHA
	0x0D1E, // ( ഞ ) MALAYALAM LETTER NYA
	0x0D1F, // ( ട ) MALAYALAM LETTER TTA
	0x0D20, // ( ഠ ) MALAYALAM LETTER TTHA
	0x0D21, // ( ഡ ) MALAYALAM LETTER DDA
	0x0D22, // ( ഢ ) MALAYALAM LETTER DDHA
	0x0D23, // ( ണ ) MALAYALAM LETTER NNA
	0x0D24, // ( ത ) MALAYALAM LETTER TA
	0x0D25, // ( ഥ ) MALAYALAM LETTER THA
	0x0D26, // ( ദ ) MALAYALAM LETTER DA
	0x0D27, // ( ധ ) MALAYALAM LETTER DHA
	0x0D28, // ( ന ) MALAYALAM LETTER NA
	0x0D2A, // ( പ ) MALAYALAM LETTER PA
	0x0D2B, // ( ഫ ) MALAYALAM LETTER PHA
	0x0D2C, // ( ബ ) MALAYALAM LETTER BA
	0x0D2D, // ( ഭ ) MALAYALAM LETTER BHA
	0x0D2E, // ( മ ) MALAYALAM LETTER MA
	0x0D2F, // ( യ ) MALAYALAM LETTER YA
	0x0D30, // ( ര ) MALAYALAM LETTER RA
	0x0D31, // ( റ ) MALAYALAM LETTER RRA
	0x0D32, // ( ല ) MALAYALAM LETTER LA
	0x0D33, // ( ള ) MALAYALAM LETTER LLA
	0x0D34, // ( ഴ ) MALAYALAM LETTER LLLA
	0x0D35, // ( വ ) MALAYALAM LETTER VA
	0x0D36, // ( ശ ) MALAYALAM LETTER SHA
	0x0D37, // ( ഷ ) MALAYALAM LETTER SSA
	0x0D38, // ( സ ) MALAYALAM LETTER SA
	0x0D39, // ( ഹ ) MALAYALAM LETTER HA
	// Malayalam - Addition for Sanskrit
	0x0D3D, // ( ഽ ) MALAYALAM SIGN AVAGRAHA
	// Malayalam - Dependent vowel signs
	0x0D3E, // ( ാ ) MALAYALAM VOWEL SIGN AA
	0x0D3F, // ( ി ) MALAYALAM VOWEL SIGN I
	0x0D40, // ( ീ ) MALAYALAM VOWEL SIGN II
	0x0D41, // ( ു ) MALAYALAM VOWEL SIGN U
	0x0D42, // ( ൂ ) MALAYALAM VOWEL SIGN UU
	0x0D43, // ( ൃ ) MALAYALAM VOWEL SIGN VOCALIC R
	0x0D44, // ( ൄ ) MALAYALAM VOWEL SIGN VOCALIC RR
	0x0D46, // ( െ ) MALAYALAM VOWEL SIGN E
	0x0D47, // ( േ ) MALAYALAM VOWEL SIGN EE
	0x0D48, // ( ൈ ) MALAYALAM VOWEL SIGN AI
	// Malayalam - Two-part dependent vowel signs
	0x0D4A, // ( ൊ ) MALAYALAM VOWEL SIGN O
	0x0D4B, // ( ോ ) MALAYALAM VOWEL SIGN OO
	0x0D4C, // ( ൌ ) MALAYALAM VOWEL SIGN AU
	// Malayalam - Various signs
	0x0D4D, // ( ് ) MALAYALAM SIGN VIRAMA
	0x0D57, // ( ൗ ) MALAYALAM AU LENGTH MARK
	// Malayalam - Additional vowels for Sanskrit
	0x0D60, // ( ൠ ) MALAYALAM LETTER VOCALIC RR
	0x0D61, // ( ൡ ) MALAYALAM LETTER VOCALIC LL
	// Malayalam - Dependent vowels
	0x0D62, // ( ൢ ) MALAYALAM VOWEL SIGN VOCALIC L
	0x0D63, // ( ൣ ) MALAYALAM VOWEL SIGN VOCALIC LL
	// Malayalam - Digits
	0x0D66, // ( ൦ ) MALAYALAM DIGIT ZERO
	0x0D67, // ( ൧ ) MALAYALAM DIGIT ONE
	0x0D68, // ( ൨ ) MALAYALAM DIGIT TWO
	0x0D69, // ( ൩ ) MALAYALAM DIGIT THREE
	0x0D6A, // ( ൪ ) MALAYALAM DIGIT FOUR
	0x0D6B, // ( ൫ ) MALAYALAM DIGIT FIVE
	0x0D6C, // ( ൬ ) MALAYALAM DIGIT SIX
	0x0D6D, // ( ൭ ) MALAYALAM DIGIT SEVEN
	0x0D6E, // ( ൮ ) MALAYALAM DIGIT EIGHT
	0x0D6F, // ( ൯ ) MALAYALAM DIGIT NINE
	// Malayalam - Malayalam numerics
	0x0D70, // ( ൰ ) MALAYALAM NUMBER TEN
	0x0D71, // ( ൱ ) MALAYALAM NUMBER ONE HUNDRED
	0x0D72, // ( ൲ ) MALAYALAM NUMBER ONE THOUSAND
	// Malayalam - Fractions
	0x0D73, // ( ൳ ) MALAYALAM FRACTION ONE QUARTER
	0x0D74, // ( ൴ ) MALAYALAM FRACTION ONE HALF
	0x0D75, // ( ൵ ) MALAYALAM FRACTION THREE QUARTERS
	// Malayalam - Date mark
	0x0D79, // ( ൹ ) MALAYALAM DATE MARK
	// Malayalam - Chillu letters
	0x0D7A, // ( ൺ ) MALAYALAM LETTER CHILLU NN
	0x0D7B, // ( ൻ ) MALAYALAM LETTER CHILLU N
	0x0D7C, // ( ർ ) MALAYALAM LETTER CHILLU RR
	0x0D7D, // ( ൽ ) MALAYALAM LETTER CHILLU L
	0x0D7E, // ( ൾ ) MALAYALAM LETTER CHILLU LL
	0x0D7F, // ( ൿ ) MALAYALAM LETTER CHILLU K	
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ക ഖ ഗ ഘ ങ ച ഛ ജ", // sample letters for now ...
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Malayalam", // Common name
	"മലയാളം", // Native name
	0x0D15, // key
	values,
	"ക ഖ ഗ ഘ ങ ച ഛ ജ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
