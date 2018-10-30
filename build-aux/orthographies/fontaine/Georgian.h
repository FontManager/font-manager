//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Georgian.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef GEORGIAN
#define GEORGIAN

namespace Georgian{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10d0,0x10f0, // MKHEDRULI
	START_RANGE_PAIR,
	0x10a0,0x10c0, // KHUTSURI MINUS ARCHAIC LETTERS 
	//START_RANGE_PAIR,
	//0x10c1,0x10c5, // KHUTSURI ARCHAIC LETTERS missing in some fonts
	//START_RANGE_PAIR,
	//0x10f1,0x10f6, // MKHEDRULI ARCHAIC LETTERS missing in some fonts
	// 0x10fb, // GEORGIAN PARAGRAPH SEPARATOR missing in some fonts
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ღმერთსი შემვედრე, ნუთუ კვლა დამხსნას სოფლისა შრომასა",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Georgian", // Common name
	"ქართული დამწერლობა", // Native name
	0x10d0, // GEORGIAN LETTER AN 
	values,
	"აბგდვზთი", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
