//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// OlChiki.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef OLCHIKI
#define OLCHIKI

namespace OlChiki{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1C50,0x1C7F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"᱐᱑᱒",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Ol Chiki", // Common name
	"", // Native name
	0x1C50, // key
	values,
	"᱐᱑᱒", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
