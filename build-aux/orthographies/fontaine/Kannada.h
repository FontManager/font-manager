//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Kannada.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef KANNADA
#define KANNADA

namespace Kannada{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0c82,0x0c83,
	START_RANGE_PAIR,
	0x0c85,0x0c8c,
	START_RANGE_PAIR,
	0x0c8e,0x0c90,
	START_RANGE_PAIR,
	0x0c92,0x0ca8,
	START_RANGE_PAIR,
	0x0caa,0x0cb3,
	START_RANGE_PAIR,
	0x0cb5,0x0cb9,
	START_RANGE_PAIR,
	0x0cbe,0x0cc4,
	START_RANGE_PAIR,
	0x0cc6,0x0cc8,
	START_RANGE_PAIR,
	0x0cca,0x0ccd,
	START_RANGE_PAIR,
	0x0cd5,0x0cd6,
	0x0cde,
	START_RANGE_PAIR,
	0x0ce0,0x0ce1,
	START_RANGE_PAIR,
	0x0ce6,0x0cef,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ಹೂವಿನ ಜೊತೆ ನಾರು ಸ್ವರ್ಗ ಸೇರಿಥು.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Kannada", // Common name
	"ಕನ್ನಡ", // Native name
	0x0cb9, // ಹ
	values,
	"ವ ಶ ಷ ಸ ಹ ಒ ಓ ಔ ಕ ಖ ಗ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
