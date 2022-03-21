//
// Ethiopic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef ETHIOPIC
#define ETHIOPIC

namespace Ethiopic{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1200,0x1248,
	START_RANGE_PAIR,
	0x124A,0x124D,
	START_RANGE_PAIR,
	0x1250,0x1256,
	0x1258,
	START_RANGE_PAIR,
	0x125A,0x125D,
	START_RANGE_PAIR,
	0x1260,0x1288,
	START_RANGE_PAIR,
	0x128A,0x128D,
	START_RANGE_PAIR,
	0x1290,0x12B0,
	START_RANGE_PAIR,
	0x12B2,0x12B5,
	START_RANGE_PAIR,
	0x12B8,0x12BE,
	0x12C0,
	START_RANGE_PAIR,
	0x12C2,0x12C5,
	START_RANGE_PAIR,
	0x12C8,0x12D6,
	START_RANGE_PAIR,
	0x12D8,0x1310,
	START_RANGE_PAIR,
	0x1312,0x1315,
	START_RANGE_PAIR,
	0x1318,0x135A,
	START_RANGE_PAIR,
	0x135F,0x137C,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"፤ ምድርም ሁሉ በአንድ ቋንቋና በአንድ ንግግር ነበረች።",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Ethiopic", // Common name
	"ግዕዝ", // Native name
	0x1210, // key
	values,
	"ሀ ሁ ሂ ሃ ሄ ህ ሆ ሐ ሑ ሒ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
