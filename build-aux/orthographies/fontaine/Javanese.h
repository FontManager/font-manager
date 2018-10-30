//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Javanese.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef JAVANESE
#define JAVANESE

namespace Javanese{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA980,0xA9CD,
	START_RANGE_PAIR,
	0xA9CF,0xA9D9,
	START_RANGE_PAIR,
	0xA9DE,0xA9DF,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꦏꦐꦑꦒꦓꦔꦖꦗꦘ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Javanese", // Common name
	"", // Native name
	0xA98F, // key
	values,
	"ꦏꦐꦑꦒꦓꦔꦖꦗꦘ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
