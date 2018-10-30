//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011, 2014 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// LinearBIdeograms.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef LINEAR_B_IDEOGRAMS
#define LINEAR_B_IDEOGRAMS

namespace LinearBIdeograms{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10080,0x100FA,
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
	"Linear B Ideograms", // Common name
	"Linear B Ideograms", // Native name
	0x10080, // key
	values,
	"𐂀𐂁𐂂𐂃𐂄𐂅", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
