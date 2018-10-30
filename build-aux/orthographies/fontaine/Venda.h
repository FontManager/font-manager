//
// Venda.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef VENDA
#define VENDA

namespace Venda{

//
// Unicode values 
//
UINT32 values[]={
	0x1E12,
	0x1E13,
	0x1E3C,
	0x1E3D,
	0x1E4A,
	0x1E4B,
	0x1E44,
	0x1E45,
	0x1E70,
	0x1E71,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Ḓ ḓ Ḽ ḽ Ṋ ṋ Ṅ ṅ Ṱ ṱ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Venda", // Common name
	"Tshivenḓa", // Native name
	0x1E12, // key
	values,
	"Ḓ ḓ Ḽ ḽ Ṋ ṋ Ṅ ṅ Ṱ ṱ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
