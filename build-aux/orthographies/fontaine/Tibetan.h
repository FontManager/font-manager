//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Tibetan.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef TIBETAN
#define TIBETAN

namespace Tibetan{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0f00,0x0f47,
	START_RANGE_PAIR,
	0x0f49,0x0f6a,
	START_RANGE_PAIR,
	0x0f71,0x0f7f,
	START_RANGE_PAIR,
	0x0f80,0x0f8b,
	START_RANGE_PAIR,
	0x0f90,0x0f97,
	START_RANGE_PAIR,
	0x0f99,0x0fbc,
	START_RANGE_PAIR,
	0x0fbe,0x0fcc,
	0x0fcf,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"བོད་སྐད་",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Tibetan", // Common name
	"དབུ་ཅན་", // Native name
	0x0f40, // TIBETAN LETTER KA
	values,
	"ཀ ཁ ག གྷ ང	ཅ ཆ ཇ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
