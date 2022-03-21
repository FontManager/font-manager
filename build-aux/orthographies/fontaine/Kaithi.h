//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Kaithi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef KAITHI
#define KAITHI

namespace Kaithi{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x11080,0x110C1,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"𑂍𑂎𑂏",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Kaithi", // Common name
	"", // Native name
	0x1108D, // key
	values,
	"𑂍𑂎𑂏", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
