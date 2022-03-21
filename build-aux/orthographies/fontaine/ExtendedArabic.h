//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// ExtendedArabic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef EXTENDED_ARABIC
#define EXTENDED_ARABIC

namespace ExtendedArabic{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0672,0x06d3,
	0x06d5,
	START_RANGE_PAIR,
	0x06f0,0x06f9,
	START_RANGE_PAIR,
	0x06fa,0x06fc,
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
	"Extended Arabic", // Common name
	"العربية", // Native name
	0x0686, // ARABIC LETTER TCHEH
	values,
	"ٹ پ څ چ ږ گ ړ ۍ ژ ټ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
