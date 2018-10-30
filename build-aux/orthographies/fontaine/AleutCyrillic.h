//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009,2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// AleutCyrillic.h
//
// Contributed by christtrekker
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ALEUT_CYRILLIC
#define ALEUT_CYRILLIC

namespace AleutCyrillic{

//
// Unicode values 
//
UINT32 values[]={
	0x0311,
	0x0406,
	0x040E,
	START_RANGE_PAIR,
	0x0410,0x044f,
	0x0456,
	0x045E,
	START_RANGE_PAIR,
	0x0472,0x0475,
	0x04A4,
	0x04A5,
	0x051E,
	0x051F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Aleut Cyrillic", // Common name
	"Aleut Cyrillic", // Native name
	0x0414, // CYRILLIC CAPITAL LETTER DE
	values,
	"", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
