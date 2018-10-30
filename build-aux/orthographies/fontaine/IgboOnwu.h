//
// IgboOnwu.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef IGBOONWU
#define IGBOONWU

namespace IgboOnwu{

//
// Unicode values 
//
UINT32 values[]={
	// Vowels with dots below:
	0x1ECA,
	0x1ECB,
	0x1ECC,
	0x1ECD,
	0x1EE4,
	0x1EE5,
	// N with dot above is preferred for consistency
	// with the vowels:
	0x1E44,
	0x1E45,
	// 
	// Wikipedia shows N with Tilde however:
	// Any good Latin font must have N with Tilde,
	// so no harm including it here:
	// 
	0x00D1,
	0x00F1,
	//
	// Vowels with tone marks: Tone marks are
	// sometimes written, so we include these here:
	// 
	0x00C1,
	0x00E1,
	0x00C0,
	0x00E0,
	0x00C9,
	0x00E9,
	0x00C8,
	0x00E8,
	0x00CD,
	0x00ED,
	0x00CC,
	0x00EC,
	0x00D3,
	0x00F3,
	0x00D2,
	0x00F2,
	0x00DA,
	0x00FA,
	0x00D9,
	0x00F9,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Asụsụ Igbo",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Igbo Onwu", // Common name
	"Asụsụ Igbo", // Native name
	0x1ECA, // key
	values,
	"Ịị Ụụ Ọọ Ṅṅ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
