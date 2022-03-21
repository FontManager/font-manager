//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Batak.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BATAK
#define BATAK

namespace Batak{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1BC0,0x1BF3,
	START_RANGE_PAIR,
	0x1BFC,0x1BFF,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᯀᯁᯂᯃᯄᯅᯆᯇᯈᯉ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Surat Batak", // Common name
	"", // Native name
	0x1BC0, // key
	values,
	"ᯀᯁᯂᯃᯄᯅᯆᯇᯈᯉ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
