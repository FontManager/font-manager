//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// MathematicalLatin.h
//
// contributed by christtrekker
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MATH_LATIN
#define MATH_LATIN

namespace MathematicalLatin{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1D400,0x1D454,
	0x210E,
	START_RANGE_PAIR,
	0x1D456,0x1D49C,
	0x212C,
	0x1D49E,
	0x1D49F,
	0x2130,
	0x2131,
	0x1D4A2,
	0x210B,
	0x2110,
	0x1D4A5,
	0x1D4A6,
	0x2112,
	0x2133,
	START_RANGE_PAIR,
	0x1D4A9,0x1D4AC,
	0x211B,
	START_RANGE_PAIR,
	0x1D4AE,0x1D4B9,
	0x212F,
	0x1D4BB,
	0x210A,
	START_RANGE_PAIR,
	0x1D4BD,0x1D4C3,
	0x2134,
	START_RANGE_PAIR,
	0x1D4C5,0x1D505,
	0x212D,
	START_RANGE_PAIR,
	0x1D507,0x1D50A,
	0x210C,
	0x2111,
	START_RANGE_PAIR,
	0x1D50D,0x1D514,
	0x211C,
	START_RANGE_PAIR,
	0x1D516,0x1D51C,
	0x2128,
	START_RANGE_PAIR,
	0x1D51E,0x1D539,
	0x2102,
	START_RANGE_PAIR,
	0x1D53B,0x1D53E,
	0x210D,
	START_RANGE_PAIR,
	0x1D540,0x1D544,
	0x2115,
	0x1D546,
	0x2119,
	0x211A,
	0x211D,
	START_RANGE_PAIR,
	0x1D54A,0x1D550,
	0x2124,
	START_RANGE_PAIR,
	0x1D552,0x1D56B,
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
	"Mathematical Latin", // Common name
	"Mathematical Latin", // Native name
	0x2102, // key
	values,
	"", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
