//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// ZhuYinFuHao.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ZHUYINFUHAO
#define ZHUYINFUHAO

namespace ZhuYinFuHao{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x3105,0x312c,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ㄅㄆㄇㄈ ㄉㄊㄋㄌ ㄍㄎㄏ ㄐㄑㄒ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Chinese Zhuyin Fuhao",
	"注音符號",
	0x3105, // BOPOMOFO LETTER B "ㄅ"
	values,
	"ㄅㄆㄇㄈㄉㄊㄋㄌ",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
