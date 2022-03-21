//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// MathematicalGreek.h
//
// contributed by christtrekker
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MATH_GREEK
#define MATH_GREEK

namespace MathematicalGreek{

//
// Unicode values 
//
UINT32 values[]={
	0x03F5,
	0x03D1,
	0x03F0,
	0x03D5,
	0x03F1,
	0x03D6,
	0x03DC,
	0x03DD,
	START_RANGE_PAIR,
	0x1D6A8,0x1D7CB,
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
	"Mathematical Greek", // Common name
	"Mathematical Greek", // Native name
	0x1D6D1, // key
	values,
	"", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
