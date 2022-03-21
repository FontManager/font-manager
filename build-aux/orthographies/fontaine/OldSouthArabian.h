//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// OldSouthArabian.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef OLDSOUTHARABIAN
#define OLDSOUTHARABIAN

namespace OldSouthArabian{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10A60,0x10A7F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"𐩠𐩡𐩢𐩣𐩤𐩥𐩦𐩧𐩨𐩩",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Old South Arabian", // Common name
	"", // Native name
	0x10A60, // key
	values,
	"𐩠𐩡𐩢𐩣𐩤𐩥𐩦𐩧𐩨𐩩", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
