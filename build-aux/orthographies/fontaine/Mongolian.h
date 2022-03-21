//
// Mongolian.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MONGOLIAN
#define MONGOLIAN

namespace Mongolian{

//
// Unicode values 
//
UINT32 values[]={
	// Punctuation
	START_RANGE_PAIR,
	0x1800,0x180A,
	// Format Controls
	START_RANGE_PAIR,
	0x180B,0x180E,
	// Digits
	START_RANGE_PAIR,
	0x1810,0x1819,
	// Letters
	START_RANGE_PAIR,
	0x1820,0x1877,
	// Letters for Sanskrit and Tibetan
	START_RANGE_PAIR,
	0x1880,0x18AA,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᠠᠡᠢᠣᠤᠥᠦᠧ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Mongolian", // Common name
	"", // Native name
	0x1820, // key
	values,
	"ᠠᠡᠢᠣᠤᠥᠦᠧ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
