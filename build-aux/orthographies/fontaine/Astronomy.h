//
// Astronomy.h
//
// Contributed by christtrekker
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ASTRONOMY
#define ASTRONOMY

namespace Astronomy{

//
// Unicode values 
//
UINT32 values[]={
	0x2605,
	0x2606,
	START_RANGE_PAIR,
	0x2609,0x260D,
	START_RANGE_PAIR,
	0x263D,0x2644,
	START_RANGE_PAIR,
	0x2646,0x2653,
	START_RANGE_PAIR,
	0x26B3,0x26B7,
	0x26CE,
	0x26E2,
	START_RANGE_PAIR,
	0x2B50,0x2B52,
	0x1F30C,
	START_RANGE_PAIR,
	0x1F311,0x1F320,
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
	"Astronomy", // Common name
	"Astronomy", // Native name
	0x2605, // key
	values,
	"",// Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
