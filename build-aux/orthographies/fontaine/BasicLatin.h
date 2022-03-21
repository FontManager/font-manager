//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// BasicLatin.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BASIC_LATIN
#define BASIC_LATIN

namespace BasicLatin{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0041,0x005A,
	START_RANGE_PAIR,
	0x0061,0x007A,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"How quickly daft jumping zebras vex.",
	"iPhone fanboys love quirky gadgets with just about zero functionality, maximum.",
	"The quick brown fox jumps over the lazy dog.",
	"Bright vixens jump; dozy fowl quack.",
	"Big fjords vex quick waltz nymph.",
	"Portez ce vieux whisky au juge blond qui fume .",
	"Sic surgens, dux, zelotypos quam karus haberis.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Basic Latin",
	"Basic Latin",
	0x0041, // LATIN CAPITAL LETTER A
	values,
	"AaBbCcGgQqRrSsZz",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
