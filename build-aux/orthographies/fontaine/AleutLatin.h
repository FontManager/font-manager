//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// AleutLatin.h
//
// Contributed by christtrekker$
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ALEUT_LATIN
#define ALEUT_LATIN

namespace AleutLatin{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0041,0x0044,
	START_RANGE_PAIR,
	0x0046,0x0049,
	START_RANGE_PAIR,
	0x004B,0x004F,
	START_RANGE_PAIR,
	0x0051,0x005A,
	START_RANGE_PAIR,
	0x0061,0x0064,
	START_RANGE_PAIR,
	0x0066,0x0069,
	START_RANGE_PAIR,
	0x006B,0x006F,
	START_RANGE_PAIR,
	0x0071,0x007A,
	0x011C,
	0x011D,
	0x0302, // no separate codepoint for x with circumflex
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
	"Aleut Latin",
	"Unangan",
	0x0041, // LATIN CAPITAL LETTER A
	values,
	"AaBbFfGgXxRrSsZz",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
