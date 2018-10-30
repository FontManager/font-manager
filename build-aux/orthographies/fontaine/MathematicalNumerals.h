//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// MathematicalNumerals.h
//
// contributed by christtrekker
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MATH_NUMERALS
#define MATH_NUMERALS

namespace MathematicalNumerals{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1D7CE,0x1D7FF,
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
	"Mathematical Numerals", // Common name
	"Mathematical Numerals", // Native name
	0x1D7D1, // key
	values,
	"", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
