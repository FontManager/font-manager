//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Balinese.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BALINESE
#define BALINESE

namespace Balinese{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1B00,0x1B4B,
	START_RANGE_PAIR,
	0x1B50,0x1B7C,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᬅᬆᬇᬈᬉᬊᬋᬌ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Balinese", // Common name
	"", // Native name
	0x1B05, // key
	values,
	"ᬅᬆᬇᬈᬉᬊᬋᬌ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
