//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Lao.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef LAO
#define LAO

namespace Lao{

//
// Unicode values 
//
UINT32 values[]={
	0x0e81,
	0x0e82,
	0x0e84,
	0x0e87,
	0x0e88,
	0x0e8a,
	0x0e8d,
	START_RANGE_PAIR,
	0x0e94,0x0e97,
	START_RANGE_PAIR,
	0x0e99,0x0e9f,
	0x0ea1,
	0x0ea2,
	0x0ea3,
	0x0ea5,
	0x0ea7,
	0x0eaa,
	0x0eab,
	START_RANGE_PAIR,
	0x0ead,0x0eb9,
	0x0ebb,
	0x0ebc,
	0x0ebd,
	START_RANGE_PAIR,
	0x0ec0,0x0ec4,
	0x0ec6,
	START_RANGE_PAIR,
	0x0ec8,0x0ecd,
	START_RANGE_PAIR,
	0x0ed0,0x0ed9,
	0x0edc,
	0x0edd,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ຂອບໃຈຫຼາຍໆເດີ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Lao", // Common name
	"ພາສາລາວ", // Native name
	0x0e81, // LAO LETTER KO
	values,
	"ກຂຄງຈຊຍດ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
