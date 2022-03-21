//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Currencies.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CURRENCIES_ORTHOGRAPHY
#define CURRENCIES_ORTHOGRAPHY

namespace Currencies{

//
// Unicode values 
//
UINT32 values[]={
	0x0024,
	START_RANGE_PAIR,
	0x00A2,0x00A5,
	0x058F,
	0x060B,
	0x09F2,
	0x09F3,
	0x09FB,
	0x0AF1,
	0x0BF9,
	0x0E3F,
	0x17DB,
	START_RANGE_PAIR,
	0x20A0,0x20BD,
	0xA838,
	0xFDFC,
	0xFE69,
	0xFF04,
	0xFFE0,
	0xFFE1,
	0xFFE5,
	0xFFE6,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Unicode currency symbols include $,¢,£,¥,₧,€ and ₭.",
	END_OF_DATA
};


//
// data
//
OrthographyData data={
	"Currencies",
	"Currencies",
	0x20A6, // Naira 
	values,
	"$¢£¥₧€₭",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
