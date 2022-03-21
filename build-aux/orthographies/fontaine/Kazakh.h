//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Kazakh.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef KAZAKH
#define KAZAKH

namespace Kazakh{

//
// Unicode values -- beyond basic Arabic only: 
//
UINT32 values[]={
	0x0674, // HIGH HAMZA
	0x0675,
	0x0676,
	0x0677,
	0x0678,
	0x067e,
	0x0686,
	0x06ad,
	0x06af,
	0x06c6,
	0x06c9,
	0x06cb,
	0x06d5,
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
	"Kazakh", // Common name
	"قازاق", // Native name
	0x06ad, // key
	values,
	"ٴ ٵ ٷ ٸ پ چ ڭ گ ۆ ۉ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
