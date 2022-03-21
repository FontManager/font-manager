//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Urdu.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef URDU
#define URDU

namespace Urdu{

//
// Unicode values -- Only those beyond basic Arabic
//
UINT32 values[]={
	0x0679, // TTEH
	0x067e, // PEH
	0x0686, // TCHEH
	0x0688, // DDAL
	// 0x0690, // DAL WITH FOUR DOTS ABOVE -- ONLY IN OLD URDU, NOT CURRENT
	0x0691, // RREH
	0x0698, // JEH
	0x06a9, // KEHEH
	0x06af, // GAF
	0x06ba, // NOON GHUNNA (DOTLESS TERMINAL NOON)
	0x06be, // HEH DOACHASHMEE
	0x06c0, // HEH WITH YEH ABOVE
	0x06c1, // HEH GOAL
	0x06c2, // HEH GOAL WITH HAMZA (LIGATURE)
	0x06c3, // TEH MARBUTA GOAL
	0x06cc, // FARSI YEH
	0x06d2, // YEH BAREE
	0x06d3, // YEH BAREE WITH HAMZA (LIGATURE)
	0x06d4, // URDU FULL STOP (PUNCTUATION)
	START_RANGE_PAIR,
	0x06f0,0x06f9,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"تمام انسان آزاد اور حقوق و عزت کے اعتبار سے برابر پیدا ہوۓ ہیں۔",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Urdu", // Common name
	"اُردو", // Native name
	0x0679, // ARABIC LETTER TTEH : ṭe
	values,
	"ٹ پ چ ڈ ڐ ژ ڙ ے", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
