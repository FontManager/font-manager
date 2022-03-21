//
// Carian.h
//
// Contributed by christtrekker
// 2015.06.30
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CARIAN
#define CARIAN

namespace Carian{

//
// Unicode values
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x102A0,0x102D0,
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
	"Carian", // Common name
	"", // Native name
	0x102A0, // key
	values,
	"",// Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
