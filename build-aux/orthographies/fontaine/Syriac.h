//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Syriac.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef SYRIAC
#define SYRIAC

namespace Syriac{

//
// Unicode values
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x0710,0x072c,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	// Start of the Gospel of John -- from http://www.aifoundations.org/peshitta/john.html
	"ܒ݁ܪܺܫܺܝܬ݂ ܐܺܝܬ݂ܰܘܗ݈ܝ ܗ݈ܘܳܐ ܡܶܠܬ݂ܳܐ ܘܗܽܘ ܡܶܠܬ݂ܳܐ ܐܺܝܬ݂ܰܘܗ݈ܝ ܗ݈ܘܳܐ ܠܘܳܬ݂ ܐܰܠܳܗܳܐ ܘܰܐܠܳܗܳܐ ܐܺܝܬ݂ܰܘܗ݈ܝ ܗ݈ܘܳܐ ܗܽܘ ܡܶܠܬ݂ܳܐ܂",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Syriac", // Common name
	"ܠܫܢܐ ܣܘܪܝܝܐ", // Native name
	0x0710, // SYRIAC LETTER ALAPH
	values,
	"ܐ ܒ ܓ ܔ ܕ ܩ ܫ ܬ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
