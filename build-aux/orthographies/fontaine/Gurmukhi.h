//
// Gurmukhi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef GURMUKHI
#define GURMUKHI

namespace Gurmukhi{

//
// Unicode values 
//
UINT32 values[]={
	// Gurmukhi - Various signs
	0x0A01, // ( ਁ ) GURMUKHI SIGN ADAK BINDI
	0x0A02, // ( ਂ ) GURMUKHI SIGN BINDI
	0x0A03, // ( ਃ ) GURMUKHI SIGN VISARGA
	// Gurmukhi - Independent vowels
	0x0A05, // ( ਅ ) GURMUKHI LETTER A
	0x0A06, // ( ਆ ) GURMUKHI LETTER AA
	0x0A07, // ( ਇ ) GURMUKHI LETTER I
	0x0A08, // ( ਈ ) GURMUKHI LETTER II
	0x0A09, // ( ਉ ) GURMUKHI LETTER U
	0x0A0A, // ( ਊ ) GURMUKHI LETTER UU
	0x0A0F, // ( ਏ ) GURMUKHI LETTER EE
	0x0A10, // ( ਐ ) GURMUKHI LETTER AI
	0x0A13, // ( ਓ ) GURMUKHI LETTER OO
	0x0A14, // ( ਔ ) GURMUKHI LETTER AU
	// Gurmukhi - Consonants
	0x0A15, // ( ਕ ) GURMUKHI LETTER KA
	0x0A16, // ( ਖ ) GURMUKHI LETTER KHA
	0x0A17, // ( ਗ ) GURMUKHI LETTER GA
	0x0A18, // ( ਘ ) GURMUKHI LETTER GHA
	0x0A19, // ( ਙ ) GURMUKHI LETTER NGA
	0x0A1A, // ( ਚ ) GURMUKHI LETTER CA
	0x0A1B, // ( ਛ ) GURMUKHI LETTER CHA
	0x0A1C, // ( ਜ ) GURMUKHI LETTER JA
	0x0A1D, // ( ਝ ) GURMUKHI LETTER JHA
	0x0A1E, // ( ਞ ) GURMUKHI LETTER NYA
	0x0A1F, // ( ਟ ) GURMUKHI LETTER TTA
	0x0A20, // ( ਠ ) GURMUKHI LETTER TTHA
	0x0A21, // ( ਡ ) GURMUKHI LETTER DDA
	0x0A22, // ( ਢ ) GURMUKHI LETTER DDHA
	0x0A23, // ( ਣ ) GURMUKHI LETTER NNA
	0x0A24, // ( ਤ ) GURMUKHI LETTER TA
	0x0A25, // ( ਥ ) GURMUKHI LETTER THA
	0x0A26, // ( ਦ ) GURMUKHI LETTER DA
	0x0A27, // ( ਧ ) GURMUKHI LETTER DHA
	0x0A28, // ( ਨ ) GURMUKHI LETTER NA
	0x0A2A, // ( ਪ ) GURMUKHI LETTER PA
	0x0A2B, // ( ਫ ) GURMUKHI LETTER PHA
	0x0A2C, // ( ਬ ) GURMUKHI LETTER BA
	0x0A2D, // ( ਭ ) GURMUKHI LETTER BHA
	0x0A2E, // ( ਮ ) GURMUKHI LETTER MA
	0x0A2F, // ( ਯ ) GURMUKHI LETTER YA
	0x0A30, // ( ਰ ) GURMUKHI LETTER RA
	0x0A32, // ( ਲ ) GURMUKHI LETTER LA
	0x0A33, // ( ਲ਼ ) GURMUKHI LETTER LLA
	0x0A35, // ( ਵ ) GURMUKHI LETTER VA
	0x0A36, // ( ਸ਼ ) GURMUKHI LETTER SHA
	0x0A38, // ( ਸ ) GURMUKHI LETTER SA
	0x0A39, // ( ਹ ) GURMUKHI LETTER HA
	// Gurmukhi - Various signs
	0x0A3C, // ( ਼ ) GURMUKHI SIGN NUKTA
	// Gurmukhi - Dependent vowel signs
	0x0A3E, // ( ਾ ) GURMUKHI VOWEL SIGN AA
	0x0A3F, // ( ਿ ) GURMUKHI VOWEL SIGN I
	0x0A40, // ( ੀ ) GURMUKHI VOWEL SIGN II
	0x0A41, // ( ੁ ) GURMUKHI VOWEL SIGN U
	0x0A42, // ( ੂ ) GURMUKHI VOWEL SIGN UU
	0x0A47, // ( ੇ ) GURMUKHI VOWEL SIGN EE
	0x0A48, // ( ੈ ) GURMUKHI VOWEL SIGN AI
	0x0A4B, // ( ੋ ) GURMUKHI VOWEL SIGN OO
	0x0A4C, // ( ੌ ) GURMUKHI VOWEL SIGN AU
	// Gurmukhi - Various signs
	0x0A4D, // ( ੍ ) GURMUKHI SIGN VIRAMA
	0x0A51, // ( ੑ ) GURMUKHI SIGN UDAAT
	// Gurmukhi - Additional consonants
	0x0A59, // ( ਖ਼ ) GURMUKHI LETTER KHHA
	0x0A5A, // ( ਗ਼ ) GURMUKHI LETTER GHHA
	0x0A5B, // ( ਜ਼ ) GURMUKHI LETTER ZA
	0x0A5C, // ( ੜ ) GURMUKHI LETTER RRA
	0x0A5E, // ( ਫ਼ ) GURMUKHI LETTER FA
	// Gurmukhi - Digits
	0x0A66, // ( ੦ ) GURMUKHI DIGIT ZERO
	0x0A67, // ( ੧ ) GURMUKHI DIGIT ONE
	0x0A68, // ( ੨ ) GURMUKHI DIGIT TWO
	0x0A69, // ( ੩ ) GURMUKHI DIGIT THREE
	0x0A6A, // ( ੪ ) GURMUKHI DIGIT FOUR
	0x0A6B, // ( ੫ ) GURMUKHI DIGIT FIVE
	0x0A6C, // ( ੬ ) GURMUKHI DIGIT SIX
	0x0A6D, // ( ੭ ) GURMUKHI DIGIT SEVEN
	0x0A6E, // ( ੮ ) GURMUKHI DIGIT EIGHT
	0x0A6F, // ( ੯ ) GURMUKHI DIGIT NINE
	// Gurmukhi - Gurmukhi-specific additions
	0x0A70, // ( ੰ ) GURMUKHI TIPPI
	0x0A71, // ( ੱ ) GURMUKHI ADDAK
	0x0A72, // ( ੲ ) GURMUKHI IRI
	0x0A73, // ( ੳ ) GURMUKHI URA
	0x0A74, // ( ੴ ) GURMUKHI EK ONKAR
	0x0A75, // ( ੵ ) GURMUKHI SIGN YAKASH
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ਕ ਖ ਗ ਘ ਙ ਚ ਛ ਜ", // sample letters for now ...
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Gurmukhi", // Common name
	"ਗੁਰਮੁਖੀ", // Native name
	0x0A15, // key
	values,
	"ਕ ਖ ਗ ਘ ਙ ਚ ਛ ਜ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
