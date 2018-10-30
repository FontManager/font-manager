//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Saurashtra.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef SAURASHTRA
#define SAURASHTRA

namespace Saurashtra{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA880,0xA8C4,
	START_RANGE_PAIR,
	0xA8CE,0xA8D9,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꢂꢃꢄ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Saurashtra", // Common name
	"", // Native name
	0xA882, // key
	values,
	"ꢂꢃꢄ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
