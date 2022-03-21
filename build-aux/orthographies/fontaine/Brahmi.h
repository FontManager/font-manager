//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Brahmi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BRAHMI
#define BRAHMI

namespace Brahmi{

//
// Unicode values 
//
UINT32 values[]={
	// Various signs, independent vowels,
	// consonants, dependent vowels, virama,
	// and punctuation marks:
	START_RANGE_PAIR,
	0x11000,0x1104D,
	// Numbers and digits:
	START_RANGE_PAIR,
	0x11052,0x1106F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"𑀩𑀼𑀤𑀥𑀁 𑀲𑀭𑀡𑀁 𑀕𑀘𑀙𑀫𑀺",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Brāhmī", // Common name
	"", // Native name
	0x11005, // key
	values,
	"𑀩𑀼𑀤𑀥𑀁 𑀲𑀭𑀡𑀁 𑀕𑀘𑀙𑀫𑀺", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
