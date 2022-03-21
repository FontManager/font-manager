//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Yi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef YI_SYLLABLES
#define YI_SYLLABLES

namespace Yi{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA000,0xA48C,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꀀꀁꀂꀃꀄꀅꀆꀇ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Yi", // Common name
	"ꆈꌠꁱꂷ", // Native name
	0xA000, // key
	values,
	"ꀀꀁꀂꀃꀄꀅꀆꀇ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
