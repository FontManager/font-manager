//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Myanmar.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MYANMAR
#define MYANMAR

namespace Myanmar{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1000,0x1021,
	START_RANGE_PAIR,
	0x1023,0x1027,
	0x1029,
	0x102a,
	START_RANGE_PAIR,
	0x102c,0x1032,
	START_RANGE_PAIR,
	0x1036,0x1039,
	START_RANGE_PAIR,
	0x1040,0x1059,
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
	"Myanmar", // Common name
	"မြန်မာအက္ခရာ", // Native name
	0x1000, // MYANMAR LETTER KA
	values,
	"ကခဂဃငစဆဇ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
