//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Siraiki.h -- INCOMPLETE as of 2009.03.11
//

#ifndef ORTHOGRAPHY_DATA
#include "OrthographyData.h"
#endif

#ifndef 
#define 

namespace {

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x,0x,
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
	"", // Common name
	"", // Native name
	0x, // key
	values,
	"", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
