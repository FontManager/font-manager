//
// Hanunoo.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef HANUNOO
#define HANUNOO

namespace Hanunoo{

//
// Unicode values 
//
UINT32 values[]={
	// Hanunoo - Independent vowels
	0x1720, // ( ᜠ ) HANUNOO LETTER A
	0x1721, // ( ᜡ ) HANUNOO LETTER I
	0x1722, // ( ᜢ ) HANUNOO LETTER U
	// Hanunoo - Consonants
	0x1723, // ( ᜣ ) HANUNOO LETTER KA
	0x1724, // ( ᜤ ) HANUNOO LETTER GA
	0x1725, // ( ᜥ ) HANUNOO LETTER NGA
	0x1726, // ( ᜦ ) HANUNOO LETTER TA
	0x1727, // ( ᜧ ) HANUNOO LETTER DA
	0x1728, // ( ᜨ ) HANUNOO LETTER NA
	0x1729, // ( ᜩ ) HANUNOO LETTER PA
	0x172A, // ( ᜪ ) HANUNOO LETTER BA
	0x172B, // ( ᜫ ) HANUNOO LETTER MA
	0x172C, // ( ᜬ ) HANUNOO LETTER YA
	0x172D, // ( ᜭ ) HANUNOO LETTER RA
	0x172E, // ( ᜮ ) HANUNOO LETTER LA
	0x172F, // ( ᜯ ) HANUNOO LETTER WA
	0x1730, // ( ᜰ ) HANUNOO LETTER SA
	0x1731, // ( ᜱ ) HANUNOO LETTER HA
	// Hanunoo - Dependent vowel signs
	0x1732, // ( ᜲ ) HANUNOO VOWEL SIGN I
	0x1733, // ( ᜳ ) HANUNOO VOWEL SIGN U
	// Hanunoo - Virama
	0x1734, // ( ᜴ ) HANUNOO SIGN PAMUDPOD
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᜣ ᜤ ᜥ ᜦ ᜧ ᜨ ᜩ ᜪ", // Using sample characters for now ...
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Hanunó'o", // Common name
	"", // Native name
	0x1723, // key: LETTER KA
	values,
	"ᜣ ᜤ ᜥ ᜦ ᜧ ᜨ ᜩ ᜪ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
