//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Math.h
//
// Everything listed as "Symbol, Math" in Unicode is here
//
// Contributions added by christtrekker
// 2015.02.02.ET verified by ET
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MATH_OPERATORS 
#define MATH_OPERATORS

namespace MathematicalOperators{

//
// Unicode values 
//
UINT32 values[]={
	0x002B,
	0x003C,
	0x003D,
	0x003E,
	0x007C,
	0x007E,
	0x00AC,
	0x00B1,
	0x00D7,
	0x00F7,
	0x03F6,
	START_RANGE_PAIR,
	0x0606,0x0608,
	0x2044,
	0x2052,
	START_RANGE_PAIR,
	0x207A,0x207C,
	START_RANGE_PAIR,
	0x208A,0x208C,
	0x2118,
	START_RANGE_PAIR,
	0x2140,0x2144,
	0x214B,
	START_RANGE_PAIR,
	0x2190,0x2194,
	0x219A,
	0x219B,
	0x21A0,
	0x21A3,
	0x21A6,
	0x21AE,
	0x21CE,
	0x21CF,
	0x21D2,
	0x21D4,
	START_RANGE_PAIR,
	0x21F4,0x22FF,
	0x2320,
	0x2321,
	0x237C,
	START_RANGE_PAIR,
	0x239B,0x23B3,
	START_RANGE_PAIR,
	0x23DC,0x23E1,
	0x25B7,
	0x25C1,
	START_RANGE_PAIR,
	0x25F8,0x25FF,
	0x266F,
	START_RANGE_PAIR,
	0x27C0,0x27FF,
	START_RANGE_PAIR,
	0x2900,0x29FF,
	START_RANGE_PAIR,
	0x2A00,0x2AFF,
	START_RANGE_PAIR,
	0x2B30,0x2B44,
	START_RANGE_PAIR,
	0x2B47,0x2B4C,
	0xFB29,
	0xFE62,
	START_RANGE_PAIR,
	0xFE64,0xFE66,
	0xFF0B,
	START_RANGE_PAIR,
	0xFF1C,0xFF1E,
	0xFF5C,
	0xFF5E,
	0xFFE2,
	START_RANGE_PAIR,
	0xFFE9,0xFFEC,
	0x1D6C1,
	0x1D6DB,
	0x1d6FB,
	0x1D715,
	0x1D735,
	0x1D74F,
	0x1D76F,
	0x1D789,
	0x1D7A9,
	0x1D7C3,
	0x1EEF0,
	0x1EEF1,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"∂∈∉∫∬≠⊂⊗⋈⋂",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Mathematical Operators", // Common name
	"Mathematical Operators", // Native name
	0x2208, // key
	values,
	"∂∈∉∫∬≠⊂⊗⋈⋂", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
