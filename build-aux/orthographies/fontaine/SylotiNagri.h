//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// SylotiNagri.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef SYLOTINAGRI
#define SYLOTINAGRI

namespace SylotiNagri{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xA800,0xA82B,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꠀꠁꠂ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Syloti Nagri", // Common name
	"", // Native name
	0xA800, // key
	values,
	"ꠀꠁꠂ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
