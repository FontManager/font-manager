//
// Miao.h
//
// Contributed by christtrekker
// 2015.06.30
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef MIAO
#define MIAO

namespace Miao{

//
// Unicode values
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x16F00,0x16F44,
	START_RANGE_PAIR,
	0x16F50,0x16F7E,
	START_RANGE_PAIR,
	0x16F8F,0x16F9F,
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
	"Miao", // Common name
	"", // Native name
	0x16F00, // key
	values,
	"",// Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
