//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Limbu.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef LIMBU
#define LIMBU

namespace Limbu{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1900,0x191C,
	START_RANGE_PAIR,
	0x1920,0x192B,
	START_RANGE_PAIR,
	0x1930,0x193B,
	0x1940,
	START_RANGE_PAIR,
	0x1944,0x194F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᤁᤂᤃ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Limbu", // Common name
	"", // Native name
	0x1901, // key
	values,
	"ᤁᤂᤃ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
