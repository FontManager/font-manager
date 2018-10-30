//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Arabic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ARABIC
#define ARABIC

namespace Arabic{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0621,0x063a,
	START_RANGE_PAIR,
	0x0640,0x0652,
	// 0x0653, // Missing from AE fonts
	// 0x0654, // Missing from AE fonts
	// 0x0655, // Missing from AE fonts
	START_RANGE_PAIR,
	0x0660,0x0669,
	// 0x0670, // Missing from AE fonts
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"العين لا تعلو على الحاج",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Arabic", // Common name
	"العربية", // Native name
	0x0639, // ARABIC LETTER AIN
	values,
	"ا ب ت ث ج ح خ د ذ ر ز س", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
