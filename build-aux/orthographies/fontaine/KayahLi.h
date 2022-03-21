//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// KayahLi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef KAYAHLI
#define KAYAHLI

namespace KayahLi{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA900,0xA92F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꤊꤋꤌꤍꤎꤏꤐꤑꤒ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Kayah Li", // Common name
	"", // Native name
	0xA90A, // key
	values,
	"ꤊꤋꤌꤍꤎꤏꤐꤑꤒ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
