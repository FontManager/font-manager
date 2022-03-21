//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2014 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Emoticons.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef EMOTICONS
#define EMOTICONS

namespace Emoticons{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x2639,0x263B, // Sad & smily faces in the Miscellaneous Symbols block
	START_RANGE_PAIR,
	0x1F600,0x1F640, // Emoticons Block
	START_RANGE_PAIR,
	0x1F645,0x1F64F, // Emoticons Block
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"",
	"",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Emoticons",
	"Emoticons",
	0x263A, // WHITE SMILING FACE
	values,
	"",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif

