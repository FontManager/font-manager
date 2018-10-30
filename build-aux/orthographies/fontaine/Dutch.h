//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Dutch.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef DUTCH
#define DUTCH

namespace Dutch{

//
// Unicode values 
//
UINT32 values[]={
	0x00C1,
	0x00E1,
	0x00C2,
	0x00E2,
	0x00C8,
	0x00E8,
	0x00C9,
	0x00E9,
	0x00CA,
	0x00EA,
	0x00CB,
	0x00EB,
	0x00CD,
	0x00ED,
	0x00CF,
	0x00EF,
	0x0132,
	0x0133,
	0x00D3,
	0x00F3,
	0x00D4,
	0x00F4,
	0x00D6,
	0x00F6,
	0x00DA,
	0x00FA,
	0x00DB,
	0x00FB,
	0x00C4,
	0x00E4,
	0x00DC,
	0x00FC,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"De export blijvt qua omvang typisch zwak.",
	"Catz' elixer bij Aquavit gemengd: je proeft whiskey!",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Dutch",
	"Nederlands",
	0x0132, // LATIN CAPITAL LIGATURE IJ
	values,
	"ÁáËëĲĳÛû",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
