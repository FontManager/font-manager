//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Cyrillic.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BASIC_CYRILLIC
#define BASIC_CYRILLIC

namespace BasicCyrillic{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0410,0x044f,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"В чащах юга жил-был цитрус...—да, но фальшивый экземпляръ!",
	"Эх, чужак! Общий съём цен шляп (юфть) — вдрызг!",
	"Эй, жлоб! Где туз? Прячь юных съёмщиц в шкаф.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Basic Cyrillic", // Common name
	"Кири́ллица", // Native name
	0x0414, // CYRILLIC CAPITAL LETTER DE
	values,
	"АБВГДЕЖЗИЙКЛ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
