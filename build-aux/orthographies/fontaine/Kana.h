//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Kana.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef KANA
#define KANA

namespace Kana{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x3041,0x3094,
	START_RANGE_PAIR,
	0x3099,0x309e,
	START_RANGE_PAIR,
	0x30A1,0x30FE,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"いろはにほへと ちりぬるを わかよたれそ つねならむ うゐのおくやま けふこえて あさきゆめみし ゑひもせす",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Japanese Kana",
	"仮名",
	0x3042, // HIRAGANA LETTER A
	values,
	"いろはにほへと",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
