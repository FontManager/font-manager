//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     

//
// Ahom.h
// 2015.06.30.ET
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef AHOM
#define AHOM

//
//
//
namespace Ahom{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x11700,0x11719,
	START_RANGE_PAIR,
	0x1171D,0x1172B,
	START_RANGE_PAIR,
	0x11730,0x1173F,
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
	"Ahom",
	"Ahom",
	0x11700, // AHOM LETTER KA
	values,
	"",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
