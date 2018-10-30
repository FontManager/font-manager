//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// CanadianSyllabics.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CANADIAN_SYLLABICS
#define CANADIAN_SYLLABICS

namespace CanadianSyllabics{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1401,0x1676,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	// First sentence of a story collected by ᑎᓇ ᐎᓐ (Tina Wynne) entitled 
	// ᐎᓴᑫᒐᒃ ᐁᑯ ᒪᑲ ᒪᐃᑲᓇᒃ (Wesakaychak and the Wolves). It is written in the 
	// orthographical style of the Moose Cree. 
	// http://www.languagegeek.com/algon/cree/mcr_example.html
	"ᐅᒪ ᐊᑕᓗᑫᐎᓐ ᐊᓕᒧᒪᑲᓋᓐ ᓇᐯᐤ ᐎᓴᑫᒐᒃ ᐁ ᐃᔑᓂᑲᓱᑦ᙮ ᑭᒋ ᐌᔅᑲᒡ ᒪᑲ, ᑭ ᐃᑕᑯᐸᓐ ᓇᐯᐤ ᐎᓴᑫᒐᒃ ᐁ ᐃᔑᓂᑲᓱᑦ᙮",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Unified Canadian Aboriginal Syllabics", // Common name
	"Unified Canadian Aboriginal Syllabics", // Native name
	0x1433, // CANADIAN SYLLABICS PO
	values,
	"ᐁᐂᐃᐄ ᑌᑍᑎᑏ ᓀᓁᓂᓃ ᕿᖀᖁᖂ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
