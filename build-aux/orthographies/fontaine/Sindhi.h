//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Sindhi.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef SINDHI
#define SINDHI

namespace Sindhi{

//
// Unicode values 
//
UINT32 values[]={
	0x067a,
	0x067b,
	0x067d,
	0x067e,
	0x067f,
	0x0680,
	0x0683,
	0x0684,
	0x0686,
	0x0687,
	0x068a,
	0x068c,
	0x068d,
	0x068e,
	0x068f,
	0x0699,
	0x06a6,
	0x06af,
	0x06b1,
	0x06b2,
	0x06b3,
	0x06b4,
	0x06bb,
	0x06cd,
	0x06d0,
	0x06fd,
	0x06fe,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Sindhi", // Common name
	"سنڌي", // Native name
	0x067a, // ARABIC LETTER TTEHEH (TEH w/ 2 vertical dots)
	values,
	"ٺ ٻ ٽ ٿ ڀ ڃ ڄ ڇ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
