//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011, 2014 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// EgyptianHieroglyphs.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef EGYTIAN_HIEROGLYPHS
#define EGYTIAN_HIEROGLYPHS

namespace EgyptianHieroglyphs{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x13000,0x1342E,
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
	"Egyptian Hieroglyphs", // Common name
	"Egyptian Hieroglyphs", // Native name
	0x13000, // key
	values,
	"𓀀𓃜𓁾𓆫𓆧𓎸", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
