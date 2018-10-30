//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Pinyin.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef PINYIN
#define PINYIN

namespace Pinyin{

//
// Unicode values 
//
UINT32 values[]={
	0x0101,
	0x00E1,
	0x01CE,
	0x00E0,
	0x0113,
	0x00E9,
	0x011B,
	0x00E8,
	0x012B,
	0x00ED,
	0x01D0,
	0x00EC,
	0x014D,
	0x00F3,
	0x01D2,
	0x00F2,
	0x016B,
	0x00FA,
	0x01D4,
	0x00F9,
	0x01D6,
	0x01D8,
	0x01DA,
	0x01DC,
	0x00FC,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"hàn yǔ pīn yīn",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Pinyin",
	"汉语拼音",
	0x01DA, // 3RD TONE U WITH UMLAUT
	values,
	"āáǎàēéěèǘǚǜü",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
