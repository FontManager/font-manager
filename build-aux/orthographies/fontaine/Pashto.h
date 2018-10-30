//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Pashto.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef PASHTO
#define PASHTO

namespace Pashto{

//
// Unicode values 
//
UINT32 values[]={
	0x067c,
	0x067e,
	0x0681,
	// 0x0682, // Not used in modern Pashto
	0x0685,
	0x0686,
	0x0689,
	0x0693,
	0x0696,
	0x0698,
	0x069a,
	0x06ab,
	0x06bc,
	0x06cd,
	0x06d0,
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
	"Pashto", // Common name
	"پښتو", // Native name
	0x685, // HEH WITH THREE DOTS ABOVE 
	values,
	"ټ پ ځ ڂ څ چ ډ ړ ګ ې", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
