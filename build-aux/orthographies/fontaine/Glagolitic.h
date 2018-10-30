//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     

//
// Glagolitic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef GLAGOLITIC
#define GLAGOLITIC

namespace Glagolitic{

//
// Unicode values 
//
UINT32 values[]={
	// Capital letters:
	START_RANGE_PAIR,
	0x2C00,0x2C2E,
	// Small letters:
	START_RANGE_PAIR,
	0x2C30,0x2C5E,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	// From http://www.obshtezhitie.net/texts/bgf/uni/bgf.html:
	" ⰰⰴⱏⰻⰽⱁ  ⱍ̅ⰽ҃ⱏ  ⱄⰻ  ⱈⱁⱋⰵⱅⱏ  ⱃⰰⰸ[ⱁⱃⰻⱅ] ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Glagolitic", // Common name
	"hlaholika", // Native name
	0x2C00, // key
	values,
	" ⰰⰴⱏⰻⰽⱁ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
