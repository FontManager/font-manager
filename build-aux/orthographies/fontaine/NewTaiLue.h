//
// NewTaiLue.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef NEWTAILUE
#define NEWTAILUE

namespace NewTaiLue{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1980,0x19A9,
	START_RANGE_PAIR,
	0x19B0,0x19C9,
	START_RANGE_PAIR,
	0x19D0,0x19D9,
	START_RANGE_PAIR,
	0x19DE,0x19DF,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᦀᦁᦂᦃ ᦖᦰ ᦖᦱ ᦖᦲ ᦖᦳ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"New Tai Lue", // Common name
	"", // Native name
	0x1980, // key
	values,
	"ᦀᦁᦂᦃ ᦖᦰ ᦖᦱ ᦖᦲ ᦖᦳ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
