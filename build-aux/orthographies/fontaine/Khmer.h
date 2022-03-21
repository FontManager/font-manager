//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Khmer.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef KHMER
#define KHMER

namespace Khmer{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1780,0x17dc, // Letters, vowels, etc.
	START_RANGE_PAIR,
	0x17E0,0x17E9, // Digits
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ជំរាបសួរស្ដី",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Khmer", // Common name
	"អក្សរខ្មែរ", // Native name
	0x1780, // key
	values,
	"កខគឃងចឆជ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
