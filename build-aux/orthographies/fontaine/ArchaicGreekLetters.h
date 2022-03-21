//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// ArchaicGreekLetters.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ARCHAIC_GREEK_LETTERS
#define ARCHAIC_GREEK_LETTERS

namespace ArchaicGreekLetters{

//
// Unicode values 
//
UINT32 values[]={
	0x0370,
	0x0371,
	0x0372,
	0x0373,
	0x0376,
	0x0377,
	START_RANGE_PAIR,
	0x03d8,0x03e1,
	0x03f7,
	0x03f8,
	0x03fa,
	0x03fb,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ϘϙϚϛϜϞϟϠϡ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Archaic Greek Letters", // Common name
	"Archaic Greek Letters", // Native name
	0x03e0, // Greek letter SAMPI
	values,
	"ϘϙϚϛϜϞϟϠϡ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
