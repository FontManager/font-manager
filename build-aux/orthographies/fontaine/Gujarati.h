//
// Gujarati.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef GUJARATI
#define GUJARATI

namespace Gujarati{

//
// Unicode values 
//
UINT32 values[]={
	// Gujarati - Various signs
	0x0A81, // ( ઁ ) GUJARATI SIGN CANDRABINDU
	0x0A82, // ( ં ) GUJARATI SIGN ANUSVARA
	0x0A83, // ( ઃ ) GUJARATI SIGN VISARGA
	// Gujarati - Independent vowels
	0x0A85, // ( અ ) GUJARATI LETTER A
	0x0A86, // ( આ ) GUJARATI LETTER AA
	0x0A87, // ( ઇ ) GUJARATI LETTER I
	0x0A88, // ( ઈ ) GUJARATI LETTER II
	0x0A89, // ( ઉ ) GUJARATI LETTER U
	0x0A8A, // ( ઊ ) GUJARATI LETTER UU
	0x0A8B, // ( ઋ ) GUJARATI LETTER VOCALIC R
	0x0A8C, // ( ઌ ) GUJARATI LETTER VOCALIC L
	0x0A8D, // ( ઍ ) GUJARATI VOWEL CANDRA E
	0x0A8F, // ( એ ) GUJARATI LETTER E
	0x0A90, // ( ઐ ) GUJARATI LETTER AI
	0x0A91, // ( ઑ ) GUJARATI VOWEL CANDRA O
	0x0A93, // ( ઓ ) GUJARATI LETTER O
	0x0A94, // ( ઔ ) GUJARATI LETTER AU
	// Gujarati - Consonants
	0x0A95, // ( ક ) GUJARATI LETTER KA
	0x0A96, // ( ખ ) GUJARATI LETTER KHA
	0x0A97, // ( ગ ) GUJARATI LETTER GA
	0x0A98, // ( ઘ ) GUJARATI LETTER GHA
	0x0A99, // ( ઙ ) GUJARATI LETTER NGA
	0x0A9A, // ( ચ ) GUJARATI LETTER CA
	0x0A9B, // ( છ ) GUJARATI LETTER CHA
	0x0A9C, // ( જ ) GUJARATI LETTER JA
	0x0A9D, // ( ઝ ) GUJARATI LETTER JHA
	0x0A9E, // ( ઞ ) GUJARATI LETTER NYA
	0x0A9F, // ( ટ ) GUJARATI LETTER TTA
	0x0AA0, // ( ઠ ) GUJARATI LETTER TTHA
	0x0AA1, // ( ડ ) GUJARATI LETTER DDA
	0x0AA2, // ( ઢ ) GUJARATI LETTER DDHA
	0x0AA3, // ( ણ ) GUJARATI LETTER NNA
	0x0AA4, // ( ત ) GUJARATI LETTER TA
	0x0AA5, // ( થ ) GUJARATI LETTER THA
	0x0AA6, // ( દ ) GUJARATI LETTER DA
	0x0AA7, // ( ધ ) GUJARATI LETTER DHA
	0x0AA8, // ( ન ) GUJARATI LETTER NA
	0x0AAA, // ( પ ) GUJARATI LETTER PA
	0x0AAB, // ( ફ ) GUJARATI LETTER PHA
	0x0AAC, // ( બ ) GUJARATI LETTER BA
	0x0AAD, // ( ભ ) GUJARATI LETTER BHA
	0x0AAE, // ( મ ) GUJARATI LETTER MA
	0x0AAF, // ( ય ) GUJARATI LETTER YA
	0x0AB0, // ( ર ) GUJARATI LETTER RA
	0x0AB2, // ( લ ) GUJARATI LETTER LA
	0x0AB3, // ( ળ ) GUJARATI LETTER LLA
	0x0AB5, // ( વ ) GUJARATI LETTER VA
	0x0AB6, // ( શ ) GUJARATI LETTER SHA
	0x0AB7, // ( ષ ) GUJARATI LETTER SSA
	0x0AB8, // ( સ ) GUJARATI LETTER SA
	0x0AB9, // ( હ ) GUJARATI LETTER HA
	// Gujarati - Various signs
	0x0ABC, // ( ઼ ) GUJARATI SIGN NUKTA
	0x0ABD, // ( ઽ ) GUJARATI SIGN AVAGRAHA
	// Gujarati - Dependent vowel signs
	0x0ABE, // ( ા ) GUJARATI VOWEL SIGN AA
	0x0ABF, // ( િ ) GUJARATI VOWEL SIGN I
	0x0AC0, // ( ી ) GUJARATI VOWEL SIGN II
	0x0AC1, // ( ુ ) GUJARATI VOWEL SIGN U
	0x0AC2, // ( ૂ ) GUJARATI VOWEL SIGN UU
	0x0AC3, // ( ૃ ) GUJARATI VOWEL SIGN VOCALIC R
	0x0AC4, // ( ૄ ) GUJARATI VOWEL SIGN VOCALIC RR
	0x0AC5, // ( ૅ ) GUJARATI VOWEL SIGN CANDRA E
	0x0AC7, // ( ે ) GUJARATI VOWEL SIGN E
	0x0AC8, // ( ૈ ) GUJARATI VOWEL SIGN AI
	0x0AC9, // ( ૉ ) GUJARATI VOWEL SIGN CANDRA O
	0x0ACB, // ( ો ) GUJARATI VOWEL SIGN O
	0x0ACC, // ( ૌ ) GUJARATI VOWEL SIGN AU
	// Gujarati - Various signs
	0x0ACD, // ( ્ ) GUJARATI SIGN VIRAMA
	0x0AD0, // ( ૐ ) GUJARATI OM
	// Gujarati - Additional vowels for Sanskrit
	0x0AE0, // ( ૠ ) GUJARATI LETTER VOCALIC RR
	0x0AE1, // ( ૡ ) GUJARATI LETTER VOCALIC LL
	0x0AE2, // ( ૢ ) GUJARATI VOWEL SIGN VOCALIC L
	0x0AE3, // ( ૣ ) GUJARATI VOWEL SIGN VOCALIC LL
	// Gujarati - Digits
	0x0AE6, // ( ૦ ) GUJARATI DIGIT ZERO
	0x0AE7, // ( ૧ ) GUJARATI DIGIT ONE
	0x0AE8, // ( ૨ ) GUJARATI DIGIT TWO
	0x0AE9, // ( ૩ ) GUJARATI DIGIT THREE
	0x0AEA, // ( ૪ ) GUJARATI DIGIT FOUR
	0x0AEB, // ( ૫ ) GUJARATI DIGIT FIVE
	0x0AEC, // ( ૬ ) GUJARATI DIGIT SIX
	0x0AED, // ( ૭ ) GUJARATI DIGIT SEVEN
	0x0AEE, // ( ૮ ) GUJARATI DIGIT EIGHT
	0x0AEF, // ( ૯ ) GUJARATI DIGIT NINE
	// Gujarati - Currency sign
	0x0AF1, // ( ૱ ) GUJARATI RUPEE SIGN	
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ક ખ ગ ઘ ઙ ચ છ જ", // Sample characters for now ...
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Gujarati", // Common name
	"ગુજરાતી લિપિ", // Native name
	0x0A95, // key
	values,
	"ક ખ ગ ઘ ઙ ચ છ જ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
