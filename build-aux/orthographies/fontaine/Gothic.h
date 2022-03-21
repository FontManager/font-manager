//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009,2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Gothic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef GOTHIC 
#define GOTHIC

namespace Gothic{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10330,0x1034A,
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
	"Gothic", // Common name
	"𐌲𐌿𐍄𐌹𐍃𐌺", // Native name
	0x10330, // key
	values,
	"𐌰𐌱𐌲𐌳𐌴𐌵", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
