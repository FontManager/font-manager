//
// OldItalic.h
//
// Contributed by christtrekker
// 2015.06.30
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef OLD_ITALIC
#define OLD_ITALIC

namespace OldItalic{

//
// Unicode values
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x10300,0x10323,
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
	"Old Italic", // Common name
	"", // Native name
	0x10300, // key
	values,
	"",// Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
