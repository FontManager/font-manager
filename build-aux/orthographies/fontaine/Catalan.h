//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Catalan.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CATALAN
#define CATALAN

namespace Catalan{

//
// Unicode values 
//
UINT32 values[]={
	0x00C0,
	0x00E0,
	0x00C7,
	0x00E7,
	0x00C8,
	0x00E8,
	0x00C9,
	0x00E9,
	0x00CD,
	0x00ED,
	0x00CF,
	0x00EF,
	0x013F,
	0x0140,
	0x00D2,
	0x00F2,
	0x00D3,
	0x00F3,
	0x00DA,
	0x00FA,
	0x00DC,
	0x00FC,
	0x00D1,
	0x00F1,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Aqueix betzol, Jan, comprava whisky de figa.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Catalan",
	"Català",
	0x013F, // LATIN CAPITAL LETTER L WITH MIDDLE DOT
	values,
	"ÀàÇçÉéÍíĿŀÚúÑñ",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
