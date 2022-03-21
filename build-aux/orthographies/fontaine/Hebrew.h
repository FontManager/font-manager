//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Hebrew.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef HEBREW
#define HEBREW

namespace Hebrew{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x05d0,0x05ea,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"זה כיף סתם לשמוע איך תנצח קרפד עץ טוב בגן",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Hebrew", // Common name
	"עִבְרִית", // Native name
	0x05d0, // HEBREW ALEF
	values,
	"א ב ד ה ו ז ח ט י", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
