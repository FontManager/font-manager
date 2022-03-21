//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Armenian.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ARMENIAN
#define ARMENIAN

namespace Armenian{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0531,0x0556,
	START_RANGE_PAIR,
	0x0559,0x055f,
	START_RANGE_PAIR,
	0x0561,0x0587,
	0x589,0x58a,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"շատ շնորհակալ եմ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Armenian", // Common name
	"Հայերեն", // Native name
	0x0561, // ARMENIAN SMALL LETTER AYB
	values,
	"ԱաԲբԳգԴդ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
