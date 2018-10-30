//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011, 2014 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// LinearBSyllbary.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef LINEAR_B_SYLLABARY
#define LINEAR_B_SYLLABARY

namespace LinearBSyllabary {

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10000,0x1000B,
	START_RANGE_PAIR,
	0x1000D,0x10026,
	START_RANGE_PAIR,
	0x10028,0x1003A,
	0x1003C,
	0x1003D,
	START_RANGE_PAIR,
	0x1003F,0x1004D,
	START_RANGE_PAIR,
	0x10050,0x1005D,
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
	"Linear B Syllabary", // Common name
	"Linear B Syllabary", // Native name
	0x10000, // key
	values,
	"𐀀𐀁𐀂𐀃𐀄𐀅", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
