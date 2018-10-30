//
// The Fontaine Font Analysis Project
//
// Copyright (c) 2009, 2015 by Edward H. Trager
// All Rights Reserved
//
// Released under the GNU GPL version 2.0 or later.
//
//
// Polynesian.h
//
// Contributed by christtrekker$
// 2015.06.30
//
#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif
#ifndef POLYNESIAN
#define POLYNESIAN
namespace Polynesian{
//
// Unicode values
// Hawai'ian : AĀEĒIĪOŌUŪHKLMNPWʻ
// Tahitian :  AĀEĒFHIĪMNOŌPRTUŪVʻ
// Maori :     AĀEĒHIĪKMNOŌPRUŪWG
// Rapa Nui :  AEIOUHKMNGPRTVʻ
// Samoan :    AĀEĒIĪOŌUŪFGLMNPSTVʻ
//
UINT32 values[]={
	0x0041, 0x0061,
	0x0100, 0x0101, // A macron
	0x0045, 0x0065,
	0x0112, 0x0113, // E macron
	0x0049, 0x0069,
	0x012A, 0x012B, // I macron
	0x004F, 0x006F,
	0x014C, 0x014D, // O macron
	0x0055, 0x0075,
	0x016A, 0x016B, // U macron
	START_RANGE_PAIR,
	0x0046, 0x0048,
	START_RANGE_PAIR,
	0x0066, 0x0068,
	START_RANGE_PAIR,
	0x004B, 0x004E,
	START_RANGE_PAIR,
	0x006B, 0x006E,
	0x0050, 0x0070,
	START_RANGE_PAIR,
	0x0052, 0x0054,
	START_RANGE_PAIR,
	0x0072, 0x0074,
	0x0056, 0x0076,
	0x0057, 0x0077,
	0x02BB, 0x0027, // 2BB preferred for glottal stop in Hawai'ian, ASCII apostrophe is acceptable in some other languages
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
"Polynesian",
"",
0x0100, // LATIN CAPITAL LETTER A WITH MACRON
values,
"AāeēiīOōuūhkLmnpwʻ",
sentences
};
const OrthographyData *pData = &data;
}; // end of namespace
#endif 
