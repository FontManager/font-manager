//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Rejang.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef  REJANG
#define  REJANG

namespace Rejang{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA930,0xA953,
	0xA95F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꤰꤱꤲꤳᤴꤵꤶꤷꤸꤹ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Rejang", // Common name
	"", // Native name
	0xA930, // key
	values,
	"ꤰꤱꤲꤳᤴꤵꤶꤷꤸꤹ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
