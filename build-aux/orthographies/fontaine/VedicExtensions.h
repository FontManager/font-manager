//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// VedicExtensions.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef VEDICEXTENSIONS
#define VEDICEXTENSIONS

namespace VedicExtensions{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1CD0,0x1CF2,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"᳐᳑᳒",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Vedic Extensions", // Common name
	"", // Native name
	0x1CD0, // key
	values,
	"᳐᳑᳒", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
