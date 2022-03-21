//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     

//
// Bamum.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BAMUM
#define BAMUM

namespace Bamum{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA6A0,0xA6F7,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꚠꚡꚢꚣ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Bamum", // Common name
	"ꚠꚡꚢꚣ", // Native name
	0xA6A0, // key
	values,
	"ꚠꚡꚢꚣ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
