//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     

//
// Chakma.h
// 2015.06.30.ET
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CHAKMA
#define CHAKMA

//
//
//
namespace Chakma{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x11100,0x11134,
	START_RANGE_PAIR,
	0x11136,0x11143,
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
	"Chakma",
	"",
	0x11107, // CHAKMA LETTER KAA
	values,
	"",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
