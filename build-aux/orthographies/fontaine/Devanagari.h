//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Devanagari.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef DEVANAGARI
#define DEVANAGARI

namespace Devanagari{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0905,0x0914, // Independent vowels
	START_RANGE_PAIR,
	0x0915,0x0939, // Consonants
	START_RANGE_PAIR,
	0x093f,0x094c, // Dependent vowel signs
	0x094d, // virama
	START_RANGE_PAIR,
	0x0958,0x095f, // Additional consonants
	START_RANGE_PAIR,
	0x0960,0x0965, // Generic additions
	START_RANGE_PAIR,
	0x0966,0x096f, // Digits
	0x0970, // Abbreviation sign
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"आप भला तो सब भला ।",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Devanagari", // Common name
	"देवनागरी", // Native name
	0x0915, // 
	values,
	"क ख ग घ ङ च छ ज झ ञ ट", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
