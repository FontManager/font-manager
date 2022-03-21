//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Kharoshthi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef KHAROSHTHI
#define KHAROSHTHI

namespace Kharoshthi{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10A00,0x10A03,
	0x10A05,
	0x10A06,
	START_RANGE_PAIR,
	0x10A0C,0x10A13,
	START_RANGE_PAIR,
	0x10A15,0x10A17,
	START_RANGE_PAIR,
	0x10A19,0x10A33,
	START_RANGE_PAIR,
	0x10A38,0x10A3A,
	0x10A3F,
	START_RANGE_PAIR,
	0x10A40,0x10A47,
	START_RANGE_PAIR,
	0x10A50,0x10A58,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"𐨐𐨑𐨒𐨓",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Kharoshthi", // Common name
	"", // Native name
	0x101A10, // key
	values,
	"𐨐𐨑𐨒𐨓", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
