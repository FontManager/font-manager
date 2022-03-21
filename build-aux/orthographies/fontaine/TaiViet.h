//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2011 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//

//
// TaiViet.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef  TAIVIET
#define  TAIVIET

namespace TaiViet{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0xAA80,0xAAC2,
	START_RANGE_PAIR,
	0xAADB,0xAADF,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ꪀꪁꪂꪃꪄꪅꪆꪇꪈꪉ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Tai Viet", // Common name
	"", // Native name
	0xAA80, // key
	values,
	"ꪀꪁꪂꪃꪄꪅꪆꪇꪈꪉ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
