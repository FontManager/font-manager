//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Baltic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BALTIC
#define BALTIC

namespace Baltic{

//
// Unicode values 
//
UINT32 values[]={
	0x0100,
	0x0101,
	0x0104,
	0x0105,
	0x010C,
	0x010D,
	0x0112,
	0x0113,
	0x0116,
	0x0117,
	0x0118,
	0x0119,
	0x0122,
	0x0123,
	0x012A,
	0x012B,
	0x012E,
	0x012F,
	0x0136,
	0x0137,
	0x013B,
	0x013C,
	0x0145,
	0x0146,
	0x0160,
	0x0161,
	0x016A,
	0x016B,
	0x017D,
	0x017E,
	0x014C,
	0x014D,
	0x0156,
	0x0157,
	0x016A,
	0x016B,
	0x0172,
	0x0173,
	0x017D,
	0x017E,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Įlinkdama fechtuotojo špaga sublykčiojusi pragręžė apvalų arbūzą.",
	"Sarkanās jūrascūciņas peld pa jūru.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Baltic",
	"Baltic",
	0x0136, // LATIN CAPITAL LETTER K WITH CEDILLA
	values,
	"ĀāĄąčĖęīĶļŅšž",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
