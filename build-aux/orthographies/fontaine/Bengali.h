//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Bengali.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BENGALI
#define BENGALI

namespace Bengali{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0981,0x0983,
	START_RANGE_PAIR,
	0x0985,0x098c,
	START_RANGE_PAIR,
	0x098f,0x0990,
	START_RANGE_PAIR,
	0x0993,0x09a8,
	START_RANGE_PAIR,
	0x09aa,0x09b0,
	0x09b2,
	START_RANGE_PAIR,
	0x09b6,0x09b9,
	0x09bc,
	START_RANGE_PAIR,
	0x09be,0x09c4,
	START_RANGE_PAIR,
	0x09c7,0x09c8,
	START_RANGE_PAIR,
	0x09cb,0x09cd,
	0x09d7,
	START_RANGE_PAIR,
	0x09dc,0x09dd,
	START_RANGE_PAIR,
	0x09df,0x09e3,
	START_RANGE_PAIR,
	0x09e6,0x09fa,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"না মামা থেকে কানা মামা ভাল।",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Bengali", // Common name
	"বাংলা", // Native name
	0x0985, // key অ
	values,
	"অ আ ই ঈ উ এ ঐ ও ঔ ক খ গ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
