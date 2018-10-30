//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Ogham.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef OGHAM
#define OGHAM

namespace Ogham{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1680,0x169c,
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
	"Ogham", // Common name
	"Ogham", // Native name
	0x1681, // key
	values,
	"ᚁᚂᚃᚄᚋᚌᚍᚎ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
