//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Lepcha.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef LEPCHA
#define LEPCHA

namespace Lepcha{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1C00,0x1C37,
	START_RANGE_PAIR,
	0x1C3B,0x1C49,
	START_RANGE_PAIR,
	0x1C4D,0x1C4F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᰀᰁᰂ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Lepcha", // Common name
	"", // Native name
	0x1C00, // key
	values,
	"ᰀᰁᰂ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
