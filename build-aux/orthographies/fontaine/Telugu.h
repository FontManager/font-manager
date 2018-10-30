//
// Telugu.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef TELUGU
#define TELUGU

namespace Telugu{

//
// Unicode values 
//
UINT32 values[]={
	// Telugu - Various signs
	0x0C01, // ( ఁ ) TELUGU SIGN CANDRABINDU
	0x0C02, // ( ం ) TELUGU SIGN ANUSVARA
	0x0C03, // ( ః ) TELUGU SIGN VISARGA
	// Telugu - Independent vowels
	0x0C05, // ( అ ) TELUGU LETTER A
	0x0C06, // ( ఆ ) TELUGU LETTER AA
	0x0C07, // ( ఇ ) TELUGU LETTER I
	0x0C08, // ( ఈ ) TELUGU LETTER II
	0x0C09, // ( ఉ ) TELUGU LETTER U
	0x0C0A, // ( ఊ ) TELUGU LETTER UU
	0x0C0B, // ( ఋ ) TELUGU LETTER VOCALIC R
	0x0C0C, // ( ఌ ) TELUGU LETTER VOCALIC L
	0x0C0E, // ( ఎ ) TELUGU LETTER E
	0x0C0F, // ( ఏ ) TELUGU LETTER EE
	0x0C10, // ( ఐ ) TELUGU LETTER AI
	0x0C12, // ( ఒ ) TELUGU LETTER O
	0x0C13, // ( ఓ ) TELUGU LETTER OO
	0x0C14, // ( ఔ ) TELUGU LETTER AU
	// Telugu - Consonants
	0x0C15, // ( క ) TELUGU LETTER KA
	0x0C16, // ( ఖ ) TELUGU LETTER KHA
	0x0C17, // ( గ ) TELUGU LETTER GA
	0x0C18, // ( ఘ ) TELUGU LETTER GHA
	0x0C19, // ( ఙ ) TELUGU LETTER NGA
	0x0C1A, // ( చ ) TELUGU LETTER CA
	0x0C1B, // ( ఛ ) TELUGU LETTER CHA
	0x0C1C, // ( జ ) TELUGU LETTER JA
	0x0C1D, // ( ఝ ) TELUGU LETTER JHA
	0x0C1E, // ( ఞ ) TELUGU LETTER NYA
	0x0C1F, // ( ట ) TELUGU LETTER TTA
	0x0C20, // ( ఠ ) TELUGU LETTER TTHA
	0x0C21, // ( డ ) TELUGU LETTER DDA
	0x0C22, // ( ఢ ) TELUGU LETTER DDHA
	0x0C23, // ( ణ ) TELUGU LETTER NNA
	0x0C24, // ( త ) TELUGU LETTER TA
	0x0C25, // ( థ ) TELUGU LETTER THA
	0x0C26, // ( ద ) TELUGU LETTER DA
	0x0C27, // ( ధ ) TELUGU LETTER DHA
	0x0C28, // ( న ) TELUGU LETTER NA
	0x0C2A, // ( ప ) TELUGU LETTER PA
	0x0C2B, // ( ఫ ) TELUGU LETTER PHA
	0x0C2C, // ( బ ) TELUGU LETTER BA
	0x0C2D, // ( భ ) TELUGU LETTER BHA
	0x0C2E, // ( మ ) TELUGU LETTER MA
	0x0C2F, // ( య ) TELUGU LETTER YA
	0x0C30, // ( ర ) TELUGU LETTER RA
	0x0C31, // ( ఱ ) TELUGU LETTER RRA
	0x0C32, // ( ల ) TELUGU LETTER LA
	0x0C33, // ( ళ ) TELUGU LETTER LLA
	0x0C35, // ( వ ) TELUGU LETTER VA
	0x0C36, // ( శ ) TELUGU LETTER SHA
	0x0C37, // ( ష ) TELUGU LETTER SSA
	0x0C38, // ( స ) TELUGU LETTER SA
	0x0C39, // ( హ ) TELUGU LETTER HA
	// Telugu - Addition for Sanskrit
	0x0C3D, // ( ఽ ) TELUGU SIGN AVAGRAHA
	// Telugu - Dependent vowel signs
	0x0C3E, // ( ా ) TELUGU VOWEL SIGN AA
	0x0C3F, // ( ి ) TELUGU VOWEL SIGN I
	0x0C40, // ( ీ ) TELUGU VOWEL SIGN II
	0x0C41, // ( ు ) TELUGU VOWEL SIGN U
	0x0C42, // ( ూ ) TELUGU VOWEL SIGN UU
	0x0C43, // ( ృ ) TELUGU VOWEL SIGN VOCALIC R
	0x0C44, // ( ౄ ) TELUGU VOWEL SIGN VOCALIC RR
	0x0C46, // ( ె ) TELUGU VOWEL SIGN E
	0x0C47, // ( ే ) TELUGU VOWEL SIGN EE
	0x0C48, // ( ై ) TELUGU VOWEL SIGN AI
	0x0C4A, // ( ొ ) TELUGU VOWEL SIGN O
	0x0C4B, // ( ో ) TELUGU VOWEL SIGN OO
	0x0C4C, // ( ౌ ) TELUGU VOWEL SIGN AU
	// Telugu - Various signs
	0x0C4D, // ( ్ ) TELUGU SIGN VIRAMA
	0x0C55, // ( ౕ ) TELUGU LENGTH MARK
	0x0C56, // ( ౖ ) TELUGU AI LENGTH MARK
	// Telugu - Historic phonetic variants
	0x0C58, // ( ౘ ) TELUGU LETTER TSA
	0x0C59, // ( ౙ ) TELUGU LETTER DZA
	// Telugu - Additional vowels for Sanskrit
	0x0C60, // ( ౠ ) TELUGU LETTER VOCALIC RR
	0x0C61, // ( ౡ ) TELUGU LETTER VOCALIC LL
	// Telugu - Dependent vowels
	0x0C62, // ( ౢ ) TELUGU VOWEL SIGN VOCALIC L
	0x0C63, // ( ౣ ) TELUGU VOWEL SIGN VOCALIC LL
	// Telugu - Digits
	0x0C66, // ( ౦ ) TELUGU DIGIT ZERO
	0x0C67, // ( ౧ ) TELUGU DIGIT ONE
	0x0C68, // ( ౨ ) TELUGU DIGIT TWO
	0x0C69, // ( ౩ ) TELUGU DIGIT THREE
	0x0C6A, // ( ౪ ) TELUGU DIGIT FOUR
	0x0C6B, // ( ౫ ) TELUGU DIGIT FIVE
	0x0C6C, // ( ౬ ) TELUGU DIGIT SIX
	0x0C6D, // ( ౭ ) TELUGU DIGIT SEVEN
	0x0C6E, // ( ౮ ) TELUGU DIGIT EIGHT
	0x0C6F, // ( ౯ ) TELUGU DIGIT NINE
	// Telugu - Telugu fractions and weights
	0x0C78, // ( ౸ ) TELUGU FRACTION DIGIT ZERO FOR ODD POWERS OF FOUR
	0x0C79, // ( ౹ ) TELUGU FRACTION DIGIT ONE FOR ODD POWERS OF FOUR
	0x0C7A, // ( ౺ ) TELUGU FRACTION DIGIT TWO FOR ODD POWERS OF FOUR
	0x0C7B, // ( ౻ ) TELUGU FRACTION DIGIT THREE FOR ODD POWERS OF FOUR
	0x0C7C, // ( ౼ ) TELUGU FRACTION DIGIT ONE FOR EVEN POWERS OF FOUR
	0x0C7D, // ( ౽ ) TELUGU FRACTION DIGIT TWO FOR EVEN POWERS OF FOUR
	0x0C7E, // ( ౾ ) TELUGU FRACTION DIGIT THREE FOR EVEN POWERS OF FOUR
	0x0C7F, // ( ౿ ) TELUGU SIGN TUUMU	
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"క ఖ గ ఘ ఙ చ ఛ జ", // just sample characters for now ...
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Telugu", // Common name
	"తెలుగు", // Native name
	0x0C15, // key -- LETTER KA
	values,
	"క ఖ గ ఘ ఙ చ ఛ జ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
