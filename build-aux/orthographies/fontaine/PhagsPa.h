//
// PhagsPa.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef PHAGSPA
#define PHAGSPA

namespace PhagsPa{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA840,0xA877,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꡀ ꡁ ꡂ ᡃ ꡄ ꡅ ꡆ ꡇ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Phags Pa", // Common name
	"", // Native name
	0xA840, // key
	values,
	"ꡀ ꡁ ꡂ ᡃ ꡄ ꡅ ꡆ ꡇ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
