//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Euro.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef EURO_ORTHOGRAPHY
#define EURO_ORTHOGRAPHY

namespace Euro{

//
// Unicode values 
//
UINT32 values[]={
	0X20AC,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"The euro “€” is the official currency of 15 member states of the European Union.",
	END_OF_DATA
};


//
// data
//
OrthographyData data={
	"Euro",
	"Euro",
	0x20AC, // EURO SYMBOL
	values,
	"€",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
