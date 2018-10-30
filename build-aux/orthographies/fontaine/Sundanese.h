//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Sundanese.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef  SUNDANESE
#define SUNDANESE

namespace Sundanese{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1B80,0x1BAA,
	START_RANGE_PAIR,
	0x1BAE,0x1BB9,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᮊᮋᮌᮍᮎᮏᮐᮑᮒ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Sundanese", // Common name
	"", // Native name
	0x1B8A, // key
	values,
	"ᮊᮋᮌᮍᮎᮏᮐᮑᮒ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
