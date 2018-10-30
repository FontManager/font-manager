//
// Osmanya.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef OSMANYA
#define OSMANYA

namespace Osmanya{

//
// Unicode values 
//
UINT32 values[]={
	// Osmanya - Letters
	0x10480, // ( 𐒀 ) OSMANYA LETTER ALEF
	0x10481, // ( 𐒁 ) OSMANYA LETTER BA
	0x10482, // ( 𐒂 ) OSMANYA LETTER TA
	0x10483, // ( 𐒃 ) OSMANYA LETTER JA
	0x10484, // ( 𐒄 ) OSMANYA LETTER XA
	0x10485, // ( 𐒅 ) OSMANYA LETTER KHA
	0x10486, // ( 𐒆 ) OSMANYA LETTER DEEL
	0x10487, // ( 𐒇 ) OSMANYA LETTER RA
	0x10488, // ( 𐒈 ) OSMANYA LETTER SA
	0x10489, // ( 𐒉 ) OSMANYA LETTER SHIIN
	0x1048A, // ( 𐒊 ) OSMANYA LETTER DHA
	0x1048B, // ( 𐒋 ) OSMANYA LETTER CAYN
	0x1048C, // ( 𐒌 ) OSMANYA LETTER GA
	0x1048D, // ( 𐒍 ) OSMANYA LETTER FA
	0x1048E, // ( 𐒎 ) OSMANYA LETTER QAAF
	0x1048F, // ( 𐒏 ) OSMANYA LETTER KAAF
	0x10490, // ( 𐒐 ) OSMANYA LETTER LAAN
	0x10491, // ( 𐒑 ) OSMANYA LETTER MIIN
	0x10492, // ( 𐒒 ) OSMANYA LETTER NUUN
	0x10493, // ( 𐒓 ) OSMANYA LETTER WAW
	0x10494, // ( 𐒔 ) OSMANYA LETTER HA
	0x10495, // ( 𐒕 ) OSMANYA LETTER YA
	0x10496, // ( 𐒖 ) OSMANYA LETTER A
	0x10497, // ( 𐒗 ) OSMANYA LETTER E
	0x10498, // ( 𐒘 ) OSMANYA LETTER I
	0x10499, // ( 𐒙 ) OSMANYA LETTER O
	0x1049A, // ( 𐒚 ) OSMANYA LETTER U
	0x1049B, // ( 𐒛 ) OSMANYA LETTER AA
	0x1049C, // ( 𐒜 ) OSMANYA LETTER EE
	0x1049D, // ( 𐒝 ) OSMANYA LETTER OO
	// Osmanya - Digits
	0x104A0, // ( 𐒠 ) OSMANYA DIGIT ZERO
	0x104A1, // ( 𐒡 ) OSMANYA DIGIT ONE
	0x104A2, // ( 𐒢 ) OSMANYA DIGIT TWO
	0x104A3, // ( 𐒣 ) OSMANYA DIGIT THREE
	0x104A4, // ( 𐒤 ) OSMANYA DIGIT FOUR
	0x104A5, // ( 𐒥 ) OSMANYA DIGIT FIVE
	0x104A6, // ( 𐒦 ) OSMANYA DIGIT SIX
	0x104A7, // ( 𐒧 ) OSMANYA DIGIT SEVEN
	0x104A8, // ( 𐒨 ) OSMANYA DIGIT EIGHT
	0x104A9, // ( 𐒩 ) OSMANYA DIGIT NINE
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"𐒀 𐒁 𐒂 𐒃 𐒄 𐒅 𐒆 𐒇",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Osmanya", // Common name
	"𐒋𐒘𐒈𐒑𐒛𐒒𐒕𐒀", // Native name
	0x10480, // key
	values,
	"𐒀 𐒁 𐒂 𐒃 𐒄 𐒅 𐒆 𐒇", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
