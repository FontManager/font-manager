//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Farsi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef FARSI
#define FARSI

namespace Farsi{

//
// Unicode values -- Only those beyond basic Arabic
//
UINT32 values[]={
	0x067e, // PEH
	0x0686, // TCHEH
	0x0698, // JEH
	0x06a9, // KEHEH
	0x06af, // GAF
	0x06cc, // FARSI YEH
	START_RANGE_PAIR,
	0x06f0,0x06f9, // Farsi numerals ۰-۹
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"من بنده عاصیم رضائی تو کجاست تاریک دلم",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Farsi", // Common name
	"فارسی", // Native name
	0x067e, // ARABIC LETTER PEH
	values,
	"پ چ ژ ک گ ۀ ی", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
