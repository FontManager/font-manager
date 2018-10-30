//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Thai.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef THAI
#define THAI

namespace Thai{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0e01,0x0e3a,
	START_RANGE_PAIR,
	0x0e3f,0x0e5b,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"มื่อชั่วพ่อขุนรามคำแหง เมืองสุโขทัยนี้ดี ในน้ำมีปลา ในนามีข้าว",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Thai", // Common name
	"ภาษาไทย", // Native name
	0x0e01, // THAI CHARACTER KO KAI
	values,
	"ฟหกดสวงท", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
