//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Jamo.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef JAMO
#define JAMO

namespace Jamo{

//
// Unicode values 
//
UINT32 values[]={
	// Typographic Jamo range:
	START_RANGE_PAIR,
	0x1100,0x11FF,
	// Compatability Jamo used when typing in an IME:
	START_RANGE_PAIR,
	0x3131,0x318E,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ㄱㄲㄳㄴㄵㄶㄷㄸㄹㄺ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Korean Jamo", // Common name
	"자모", // Native name
	0x3131, // key
	values,
	"ㄱㄲㄳㄴㄵㄶㄷㄸㄹㄺ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
