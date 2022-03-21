//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009,2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// FullCyrillic.h
//
// Contributed by christtrekker
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef FULL_CYRILLIC
#define FULL_CYRILLIC

namespace FullCyrillic{

//
// Unicode values 
//
UINT32 values[]={
        0x0300,
        0x0301,
        0x0306,
        0x0308,
	START_RANGE_PAIR,
        0x0400, 0x0484,
	START_RANGE_PAIR,
        0x0487, 0x052F,
	START_RANGE_PAIR,
        0x1C80, 0x1C88,
        0x1D2B,
        0x1D78,
	START_RANGE_PAIR,
        0x2DE0, 0x2DFF,
	START_RANGE_PAIR,
        0xA640, 0xA69F,
        0xFE2E,
        0xFE2F,
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
	"Full Cyrillic", // Common name
	"Full Cyrillic", // Native name
	0x0414, // CYRILLIC CAPITAL LETTER DE
	values,
	"", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
