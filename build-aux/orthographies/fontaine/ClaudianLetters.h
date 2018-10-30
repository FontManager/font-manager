//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// ClaudianLetters.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CLAUDIAN_LETTERS
#define CLAUDIAN_LETTERS

namespace ClaudianLetters{

//
// Unicode values 
//
UINT32 values[]={
	0x2132,
	0x214E,
	0x2183,
	0x2184,
	0x2C75,
	0x2C76,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ℲⅎↃↄⱵⱶ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Claudian Letters",
	"Claudian Letters",
	0x2183, // CLAUDIAN LETTER 
	values,
	"ℲⅎↃↄⱵⱶ",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
