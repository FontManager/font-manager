//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011, 2014 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// MeroiticHieroglyphs.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MEROITIC_HIEROGLYPHS
#define MEROITIC_HIEROGLYPHS

namespace MeroiticHieroglyphs{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10980,0x1099F,
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
	"Meroitic Hieroglyphs", // Common name
	"Meroitic Hieroglyphs", // Native name
	0x10980, // key
	values,
	"𐦀𐦁𐦂𐦃𐦄𐦅", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
