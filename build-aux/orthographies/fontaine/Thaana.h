//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Thaana.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef THAANA
#define THAANA

namespace Thaana{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0780,0x07b0,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	// From http://en.wikipedia.org/wiki/Gaumii_salaam#Thaana:
	"ޤައުމީ މިއެކުވެރިކަން މަތީ ތިބެގެން ކުރީމެ ސަލާމް",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Thaana", // Common name
	"ތާނަ", // Native name
	0x0780, // THAANA LETTER HAA
	values,
	"ހ ށ ނ ރ ބ ޅ ކ އ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
