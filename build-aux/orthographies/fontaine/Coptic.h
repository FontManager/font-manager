//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Coptic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef COPTIC
#define COPTIC

namespace Coptic{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x03e2,0x03ef, // Demotic Coptic letters in Greek block
	START_RANGE_PAIR,
	0x2c80,0x2cb1, // Bohairic Coptic
	START_RANGE_PAIR,
	0x2cb2,0x2cdb, // Old Coptic & Dialect letters
	START_RANGE_PAIR,
	0x2cdc,0x2ce3, // Old Nubian
	START_RANGE_PAIR,
	0x2ce4,0x2cea, // Symbols
	START_RANGE_PAIR,
	0x2cf9,0x2cfc, // Old Nubian Punctuation
	0x2cfd,
	0x2cfe,
	0x2cff,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Ϯⲉⲕ'ⲕⲗⲏⲥⲓⲁ 'ⲛⲣⲉⲙ'ⲛⲭⲏⲙⲓ 'ⲛⲟⲣⲑⲟⲇⲟⲝⲟⲥ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Coptic", // Common name
	"Ⲙⲉⲧⲣⲉⲙ̀ⲛⲭⲏⲙⲓ", // Native name
	0x03E2, // COPTIC CAPITAL LETTER SHEI
	values,
	"ϢϣⲀⲁⲲⲳⳜⳝⳤ⳥", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
