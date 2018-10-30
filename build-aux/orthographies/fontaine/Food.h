//
// Food.h
//
// Contributed by christtrekker
// 2015.06.30
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef FOOD
#define FOOD

namespace Food{

//
// Unicode values
//
UINT32 values[]={
	0x2615,
	0x26FE,
	START_RANGE_PAIR,
	0x1F32D,0x1F32F,
	START_RANGE_PAIR,
	0x1F33D,0x1F33F,
	START_RANGE_PAIR,
	0x1F344,0x1F37F,
	0x1F9C0,
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
	"Food and Drink", // Common name
	"Food and Drink", // Native name
	0x2615, // key
	values,
	"",// Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
