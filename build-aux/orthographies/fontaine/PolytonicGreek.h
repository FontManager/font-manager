//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// PolytonicGreek.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef POLYTONIC_GREEK
#define POLYTONIC_GREEK

namespace PolytonicGreek{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x1f00,0x1f15,
	START_RANGE_PAIR,
	0x1f18,0x1f1d,
	START_RANGE_PAIR,
	0x1f20,0x1f45,
	START_RANGE_PAIR,
	0x1f48,0x1f4d,
	START_RANGE_PAIR,
	0x1f50,0x1f57,
	0x1f59,
	0x1f5b,
	0x1f5d,
	START_RANGE_PAIR,
	0x1f5f,0x1f7d,
	START_RANGE_PAIR,
	0x1f80,0x1fb4,
	START_RANGE_PAIR,
	0x1fb6,0x1fbc,
	START_RANGE_PAIR,
	0x1fc2,0x1fc4,
	START_RANGE_PAIR,
	0x1fc6,0x1fd3,
	START_RANGE_PAIR,
	0x1fd6,0x1fdb,
	START_RANGE_PAIR,
	0x1fe0,0x1fec,
	START_RANGE_PAIR,
	0x1ff2,0x1ff4,
	START_RANGE_PAIR,
	0x1ff6,0x1ffc,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ἡἔἂὄὗὥᾏᾟ",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Polytonic Greek", // Common name
	"Polytonic Greek", // Native name
	0x1f21, // GREEK SMALL LETTER ETA WITH DASIA
	values,
	"ἡἔἂὄὗὥᾏᾟ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
