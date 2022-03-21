//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// BasicGreek.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef BASICGREEK
#define BASICGREEK

namespace BasicGreek{

//
// Unicode values 
//
UINT32 values[]={
	0x0386,
	0x0388,
	0x0389,
	0x038a,
	0x038c,
	0x038e,
	0x038f,
	0x0390,
	START_RANGE_PAIR,
	0x0391,0x03a1,
	START_RANGE_PAIR,
	0x03a3,0x03a9,
	START_RANGE_PAIR,
	0x03aa,0x03b0,
	START_RANGE_PAIR,
	0x03b1,0x03c9,
	START_RANGE_PAIR,
	0x03ca,0x03ce,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"Γαζίες καὶ μυρτιὲς δὲν θὰ βρῶ πιὰ στὸ χρυσαφὶ ξέφωτο.",
	"Ξεσκεπάζω τὴν ψυχοφθόρα βδελυγμία. ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Basic Greek", // Common name
	"Ελληνικό αλφάβητο", // Native name
	0x03a9, // GREEK CAPITAL LETTER OMEGA
	values,
	"ΑαΒβΓγΔδΕεΞξΩω", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
