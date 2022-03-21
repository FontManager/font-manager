//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011, 2014 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// MeroiticCursive.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MEROITIC_CURSIVE
#define MEROITIC_CURSIVE

namespace MeroiticCursive{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x109A0,0x109B7,
	0x109BE,
	0x109BF,
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
	"MeroiticCursive", // Common name
	"MeroiticCursive", // Native name
	0x109A0, // key
	values,
	"𐦠𐦡𐦢𐦣𐦤𐦥", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
