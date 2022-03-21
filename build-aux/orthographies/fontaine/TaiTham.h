//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2010 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// TaiTham.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef TAI_THAM
#define TAI_THAM

namespace TaiTham{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1A20,0x1A5E,
	START_RANGE_PAIR,
	0x1A60,0x1A7C,
	START_RANGE_PAIR,
	0x1A7F,0x1A89,
	START_RANGE_PAIR,
	0x1A90,0x1A99,
	START_RANGE_PAIR,
	0x1AA0,0x1AAD,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᨲᩫ᩠ᩅᨾᩮᩥᩬᨦ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Tai Tham (Lanna)", // Common name
	"ᨲᩫ᩠ᩅᨾᩮᩥᩬᨦ", // Native name
	0x1A20, // TAI THAM LETTER HIGH KA
	values,
	"ᨲᩫ᩠ᩅᨾᩮᩥᩬᨦ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
