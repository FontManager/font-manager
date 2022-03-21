//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Uighur.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef UIGHUR
#define UIGHUR

namespace Uighur{

//
// Unicode values 
//
UINT32 values[]={
	0x06ad,
	0x06c6,
	0x06c8,
	0x06cb,
	0x06d0,
	0x06d5,
	0x067e,
	0x0686,
	0x0698,
	0x06af,
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
	"Uighur", // Common name
	"ئۇيغۇر", // Native name
	0x06ad, // ARABIC LETTER NG
	values,
	"ڛ ۆ ڭ ە پ چ ژ گ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
