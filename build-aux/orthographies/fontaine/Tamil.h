//
// Tamil.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef TAMIL
#define TAMIL

namespace Tamil{

//
// Unicode values 
//
UINT32 values[]={
// Tamil - Signs
	0x0B82, // ( ஂ ) TAMIL SIGN ANUSVARA
	0x0B83, // ( ஃ ) TAMIL SIGN VISARGA
// Tamil - Independent vowels
	0x0B85, // ( அ ) TAMIL LETTER A
	0x0B86, // ( ஆ ) TAMIL LETTER AA
	0x0B87, // ( இ ) TAMIL LETTER I
	0x0B88, // ( ஈ ) TAMIL LETTER II
	0x0B89, // ( உ ) TAMIL LETTER U
	0x0B8A, // ( ஊ ) TAMIL LETTER UU
	0x0B8E, // ( எ ) TAMIL LETTER E
	0x0B8F, // ( ஏ ) TAMIL LETTER EE
	0x0B90, // ( ஐ ) TAMIL LETTER AI
	0x0B92, // ( ஒ ) TAMIL LETTER O
	0x0B93, // ( ஓ ) TAMIL LETTER OO
	0x0B94, // ( ஔ ) TAMIL LETTER AU
// Tamil - Consonants
	0x0B95, // ( க ) TAMIL LETTER KA 
	0x0B99, // ( ங ) TAMIL LETTER NGA
	0x0B9A, // ( ச ) TAMIL LETTER CA
	0x0B9C, // ( ஜ ) TAMIL LETTER JA
	0x0B9E, // ( ஞ ) TAMIL LETTER NYA
	0x0B9F, // ( ட ) TAMIL LETTER TTA
	0x0BA3, // ( ண ) TAMIL LETTER NNA
	0x0BA4, // ( த ) TAMIL LETTER TA
	0x0BA8, // ( ந ) TAMIL LETTER NA
	0x0BA9, // ( ன ) TAMIL LETTER NNNA
	0x0BAA, // ( ப ) TAMIL LETTER PA
	0x0BAE, // ( ம ) TAMIL LETTER MA
	0x0BAF, // ( ய ) TAMIL LETTER YA
	0x0BB0, // ( ர ) TAMIL LETTER RA
	0x0BB1, // ( ற ) TAMIL LETTER RRA
	0x0BB2, // ( ல ) TAMIL LETTER LA
	0x0BB3, // ( ள ) TAMIL LETTER LLA
	0x0BB4, // ( ழ ) TAMIL LETTER LLLA
	0x0BB5, // ( வ ) TAMIL LETTER VA
	0x0BB6, // ( ஶ ) TAMIL LETTER SHA
	0x0BB7, // ( ஷ ) TAMIL LETTER SSA
	0x0BB8, // ( ஸ ) TAMIL LETTER SA
	0x0BB9, // ( ஹ ) TAMIL LETTER HA
// Tamil - Dependent vowel signs
	0x0BBE, // ( ா ) TAMIL VOWEL SIGN AA
	0x0BBF, // ( ி ) TAMIL VOWEL SIGN I
	0x0BC0, // ( ீ ) TAMIL VOWEL SIGN II
	0x0BC1, // ( ு ) TAMIL VOWEL SIGN U
	0x0BC2, // ( ூ ) TAMIL VOWEL SIGN UU
	0x0BC6, // ( ெ ) TAMIL VOWEL SIGN E
	0x0BC7, // ( ே ) TAMIL VOWEL SIGN EE
	0x0BC8, // ( ை ) TAMIL VOWEL SIGN AI
// Tamil - Two-part dependent vowel signs
	0x0BCA, // ( ொ ) TAMIL VOWEL SIGN O
	0x0BCB, // ( ோ ) TAMIL VOWEL SIGN OO
	0x0BCC, // ( ௌ ) TAMIL VOWEL SIGN AU
// Tamil - Various signs
	0x0BCD, // ( ் ) TAMIL SIGN VIRAMA
	0x0BD0, // ( ௐ ) TAMIL OM
	0x0BD7, // ( ௗ ) TAMIL AU LENGTH MARK
// Tamil - Digits
	START_RANGE_PAIR,
	0x0BE6,0x0BEF,
// Tamil - Tamil numerics
	0x0BF0, // ( ௰ ) TAMIL NUMBER TEN
	0x0BF1, // ( ௱ ) TAMIL NUMBER ONE HUNDRED
	0x0BF2, // ( ௲ ) TAMIL NUMBER ONE THOUSAND
// Tamil - Tamil symbols
	0x0BF3, // ( ௳ ) TAMIL DAY SIGN
	0x0BF4, // ( ௴ ) TAMIL MONTH SIGN
	0x0BF5, // ( ௵ ) TAMIL YEAR SIGN
	0x0BF6, // ( ௶ ) TAMIL DEBIT SIGN
	0x0BF7, // ( ௷ ) TAMIL CREDIT SIGN
	0x0BF8, // ( ௸ ) TAMIL AS ABOVE SIGN
// Tamil - Currency symbol
	0x0BF9, // ( ௹ ) TAMIL RUPEE SIGN
// Tamil - Tamil symbol
	0x0BFA, // ( ௺ ) TAMIL NUMBER SIGN
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"செம்புலப் பெயனீர் போல அன்புடை நெஞ்சம் தாங்கலந் தனவே",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Tamil", // Common name
	"தமிழ் அரிச்சுவடி ", // Native name
	0x0B95, // key
	values,
	"கஙசஜஞடணத", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
