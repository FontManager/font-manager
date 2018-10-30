//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Romanian.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ROMANIAN
#define ROMANIAN

namespace Romanian{

//
// Unicode values -- Only those needed beyond basic Latin 
//
UINT32 values[]={
	0x00C2,
	0x00E2,
	0x0102,
	0x0103,
	0x00CE,
	0x00EE,
	0x0218,
	0x0219,
	0x021A,
	0x021B,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Gheorghe, obezul, a reușit să obțină jucându-se un flux în Quebec de o mie kilowațioră.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Romanian",
	"Română",
	0x021A, // 
	values,
	"ÂâĂăÎîȘșȚț",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
