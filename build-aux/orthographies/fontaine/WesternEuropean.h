//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// WesternEuropean.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef WESTERN_EUROPEAN
#define WESTERN_EUROPEAN

namespace WesternEuropean{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x00C0,0x00CF, // Western Latin
	START_RANGE_PAIR,
	0x00D0,0x00D6, // Western Latin
	START_RANGE_PAIR,
	0x00D8,0x00DF, // Western Latin
	START_RANGE_PAIR,
	0x00E0,0x00EF, // Western Latin
	START_RANGE_PAIR,
	0x00F0,0x00F6, // Western Latin
	START_RANGE_PAIR,
	0x00F8,0x00FF, // Western Latin
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Falsches Üben von Xylophonmusik quält jeden größeren Zwerg.",
	"Vår sære Zulu fra badeøya spilte jo whist og quickstep i min taxi.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Western European",
	"Western European",
	0x00C0, // LATIN CAPITAL LETTER A WITH GRAVE
	values,
	"ÁàåÇçæÐðéîñöœßþÿ",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
