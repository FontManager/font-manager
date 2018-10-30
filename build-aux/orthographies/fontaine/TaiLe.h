//
// TaiLe.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef TAILE
#define TAILE

namespace TaiLe{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1950,0x196D,
	START_RANGE_PAIR,
	0x1970,0x1974,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᥐᥑᥒᥓ ᥣᥤᥥᥦ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Tai Le", // Common name
	"", // Native name
	0x1950, // key
	values,
	"ᥐᥑᥒᥓ ᥣᥤᥥᥦ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
