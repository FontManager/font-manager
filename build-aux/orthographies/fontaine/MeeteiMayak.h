//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// MeeteiMayak.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MEETEIMAYAK
#define MEETEIMAYAK

namespace MeeteiMayak{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xABC0,0xABED,
	START_RANGE_PAIR,
	0xABF0,0xABF9,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꯀꯁꯂ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Meetei Mayak", // Common name
	"", // Native name
	0xABC0, // key
	values,
	"ꯀꯁꯂ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
