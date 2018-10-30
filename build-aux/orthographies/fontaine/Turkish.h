//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// turkish.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef TURKISH
#define TURKISH

namespace Turkish{

//
// Unicode values 
//
UINT32 values[]={
	0x00C2,
	0x00E2,
	0x00C7,
	0x00E7,
	0x011E,
	0x011F,
	0x00CE,
	0x00EE,
	0x0130,
	0x0131,
	0x00D6,
	0x00F6,
	0x015E,
	0x015F,
	0x00DB,
	0x00FB,
	0x00DC,
	0x00FC,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Pijamalı hasta, yağız şoföre çabucak güvendi.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Turkish",
	"Türkçe",
	0x0130, // 
	values,
	"ÂâÇçĞğİıÖöŞşÛû",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
