//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Runic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef RUNIC
#define RUNIC

namespace Runic{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x16A0,0x16F0,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᛏᚡᛆᛋ ᛒᚱᛁᛚᛚᛁᚵ ᛆᚿᛑ ᛏᚼᛂ ᛋᛚᛁᛏᚼᚤ ᛏᚫᚡᛂᛋ ᛑᛁᛑ ᚵᚤᚱᛂ ᛆᚿᛑ ᚵᛁᛘᛒᛚᛂ ᛁᚿ ᛏᚼᛂ ᚡᛆᛒᛂ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Runic", // Common name
	"ᚠᚢᚦᛆᚱᚴ", // Native name
	0x16A0, // key
	values,
	"ᚠᚡᚢᚣᚤᚥꘖᚧ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
