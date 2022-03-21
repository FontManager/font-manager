//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// Cham.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CHAM 
#define CHAM

namespace Cham{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xAA00,0xAA36,
	START_RANGE_PAIR,
	0xAA40,0xAA4D,
	START_RANGE_PAIR,
	0xAA50,0xAA59,
	START_RANGE_PAIR,
	0xAA5C,0xAA5F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꨀꨁꨂꨃꨄꨅꨆꨇꨉ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Cham", // Common name
	"", // Native name
	0xAA00, // key
	values,
	"ꨀꨁꨂꨃꨄꨅꨆꨇꨉ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
