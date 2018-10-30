//
// Nko.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef NKO
#define NKO

namespace Nko{

//
// Unicode values 
//
UINT32 values[]={
	// NKo - Digits
	0x07C0, // ( ‎߀‎ ) NKO DIGIT ZERO
	0x07C1, // ( ‎߁‎ ) NKO DIGIT ONE
	0x07C2, // ( ‎߂‎ ) NKO DIGIT TWO
	0x07C3, // ( ‎߃‎ ) NKO DIGIT THREE
	0x07C4, // ( ‎߄‎ ) NKO DIGIT FOUR
	0x07C5, // ( ‎߅‎ ) NKO DIGIT FIVE
	0x07C6, // ( ‎߆‎ ) NKO DIGIT SIX
	0x07C7, // ( ‎߇‎ ) NKO DIGIT SEVEN
	0x07C8, // ( ‎߈‎ ) NKO DIGIT EIGHT
	0x07C9, // ( ‎߉‎ ) NKO DIGIT NINE
	// NKo - Letters
	0x07CA, // ( ‎ߊ‎ ) NKO LETTER A
	0x07CB, // ( ‎ߋ‎ ) NKO LETTER EE
	0x07CC, // ( ‎ߌ‎ ) NKO LETTER I
	0x07CD, // ( ‎ߍ‎ ) NKO LETTER E
	0x07CE, // ( ‎ߎ‎ ) NKO LETTER U
	0x07CF, // ( ‎ߏ‎ ) NKO LETTER OO
	0x07D0, // ( ‎ߐ‎ ) NKO LETTER O
	0x07D1, // ( ‎ߑ‎ ) NKO LETTER DAGBASINNA
	0x07D2, // ( ‎ߒ‎ ) NKO LETTER N
	0x07D3, // ( ‎ߓ‎ ) NKO LETTER BA
	0x07D4, // ( ‎ߔ‎ ) NKO LETTER PA
	0x07D5, // ( ‎ߕ‎ ) NKO LETTER TA
	0x07D6, // ( ‎ߖ‎ ) NKO LETTER JA
	0x07D7, // ( ‎ߗ‎ ) NKO LETTER CHA
	0x07D8, // ( ‎ߘ‎ ) NKO LETTER DA
	0x07D9, // ( ‎ߙ‎ ) NKO LETTER RA
	0x07DA, // ( ‎ߚ‎ ) NKO LETTER RRA
	0x07DB, // ( ‎ߛ‎ ) NKO LETTER SA
	0x07DC, // ( ‎ߜ‎ ) NKO LETTER GBA
	0x07DD, // ( ‎ߝ‎ ) NKO LETTER FA
	0x07DE, // ( ‎ߞ‎ ) NKO LETTER KA
	0x07DF, // ( ‎ߟ‎ ) NKO LETTER LA
	0x07E0, // ( ‎ߠ‎ ) NKO LETTER NA WOLOSO
	0x07E1, // ( ‎ߡ‎ ) NKO LETTER MA
	0x07E2, // ( ‎ߢ‎ ) NKO LETTER NYA
	0x07E3, // ( ‎ߣ‎ ) NKO LETTER NA
	0x07E4, // ( ‎ߤ‎ ) NKO LETTER HA
	0x07E5, // ( ‎ߥ‎ ) NKO LETTER WA
	0x07E6, // ( ‎ߦ‎ ) NKO LETTER YA
	0x07E7, // ( ‎ߧ‎ ) NKO LETTER NYA WOLOSO
	// NKo - Archaic letters
	0x07E8, // ( ‎ߨ‎ ) NKO LETTER JONA JA
	0x07E9, // ( ‎ߩ‎ ) NKO LETTER JONA CHA
	0x07EA, // ( ‎ߪ‎ ) NKO LETTER JONA RA
	// NKo - Tone marks
	0x07EB, // ( ߫ ) NKO COMBINING SHORT HIGH TONE
	0x07EC, // ( ߬ ) NKO COMBINING SHORT LOW TONE
	0x07ED, // ( ߭ ) NKO COMBINING SHORT RISING TONE
	0x07EE, // ( ߮ ) NKO COMBINING LONG DESCENDING TONE
	0x07EF, // ( ߯ ) NKO COMBINING LONG HIGH TONE
	0x07F0, // ( ߰ ) NKO COMBINING LONG LOW TONE
	0x07F1, // ( ߱ ) NKO COMBINING LONG RISING TONE
	0x07F2, // ( ߲ ) NKO COMBINING NASALIZATION MARK
	0x07F3, // ( ߳ ) NKO COMBINING DOUBLE DOT ABOVE
	0x07F4, // ( ‎ߴ‎ ) NKO HIGH TONE APOSTROPHE
	0x07F5, // ( ‎ߵ‎ ) NKO LOW TONE APOSTROPHE
	// NKo - Symbol
	0x07F6, // ( ߶ ) NKO SYMBOL OO DENNEN
	// NKo - Punctuation
	0x07F7, // ( ߷ ) NKO SYMBOL GBAKURUNEN
	0x07F8, // ( ߸ ) NKO COMMA
	0x07F9, // ( ߹ ) NKO EXCLAMATION MARK
	// NKo - Letter extender
	0x07FA, // ( ‎ߺ‎ ) NKO LAJANYALAN
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"‎ߊ‎ ‎ߋ‎ ‎ߌ‎ ‎ߍ‎ ‎ߎ‎ ‎ߏ‎ ‎ߐ‎ ‎ߑ‎ ‎ߒ‎ ‎ߓ‎ ‎ߔ‎ ‎ߕ‎ ‎ߖ‎",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"N’Ko", // Common name
	"ߒߞߏ", // Native name
	0x07CA, // key
	values,
	"‎ߊ‎ ‎ߋ‎ ‎ߌ‎ ‎ߍ‎ ‎ߎ‎ ‎ߏ‎ ‎ߐ‎ ‎ߑ‎ ‎ߒ‎ ‎ߓ‎ ‎ߔ‎ ‎ߕ‎ ‎ߖ‎", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
