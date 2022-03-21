//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     

//
// MendeKikakui.h
// 2015.06.30.ET
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MENDE_KIKAKUI
#define MENDE_KIKAKUI

//
//
//
namespace MendeKikakui{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1E800,0x1E8C4,
	START_RANGE_PAIR,
	0x1E8C7,0x1E8D6,
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
	"Mende Kikakui",
	"",
	0x1E800, // MENDE KIKAKUI SYLLABLE M001 KI
	values,
	"",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
