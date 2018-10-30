//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Buginese.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BUGINESE
#define BUGINESE

namespace Buginese{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1A00,0x1A1B,
	START_RANGE_PAIR,
	0x1A1E,0x1A1F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᨀᨁᨂᨃᨄᨅᨆᨇᨈᨉ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Buginese", // Common name
	"", // Native name
	0x1A00, // key
	values,
	"ᨀᨁᨂᨃᨄᨅᨆᨇᨈᨉ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
