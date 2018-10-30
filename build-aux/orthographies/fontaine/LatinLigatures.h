//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// LatinLigatures.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef LATIN_LIGATURES
#define LATIN_LIGATURES

namespace LatinLigatures{

//
// Unicode values 
//
UINT32 values[]={
	0xFB00,
	0xFB01,
	0xFB02,
	0xFB03,
	0xFB04,
	0xFB05,
	0xFB06,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Aﬀable ﬁnanciers ﬂowered with eﬃcacious aﬄuence in the ﬅalwart ﬆrata.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Latin Ligatures",
	"Latin Ligatures",
	0xFB06, // LOWER CASE ST LIGATURE
	values,
	"ﬀ ﬁ ﬂ ﬃ ﬄ ﬅ ﬆ",
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
