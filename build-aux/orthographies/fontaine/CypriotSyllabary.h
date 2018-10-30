//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011, 2014 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// CypriotSyllabary.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CYPRIOT_SYLLABARY
#define CYPRIOT_SYLLABARY

namespace CypriotSyllabary {

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10800,0x10805,
	0X10808,
	START_RANGE_PAIR,
	0x1080A,0x10835,
	0x10837,
	0x10838,
	0x1083C,
	0x1083F,
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
	"Cypriot Syllabary", // Common name
	"Cypriot Syllabary", // Native name
	0x10800, // key
	values,
	"𐠂𐠁𐠀𐠃𐠄𐠅", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
