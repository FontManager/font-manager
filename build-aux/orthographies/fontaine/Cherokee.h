//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// Cherokee.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CHEROKEE
#define CHEROKEE

namespace Cherokee{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x13A0,0x13F4,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ᏏᏉᏯ ᎤᎾᏅᏛ ᏥᏄᏍᏗ ᏣᏥ ᎢᏰᎵᏍᏗ, ᎠᏓᏩᏛᎯᏙᎯ ᎠᎴ ᎠᎴᏂᏙᎲ, ᏥᏄᏍᏛᎩ ᏣᎳᎩ ᎠᏕᎸ ᎤᏁᎬ ᎠᏥᏅᏏᏓᏍᏗ ᎦᎪ ᎪᎷᏩᏛᏗ ᎯᎠ ᏣᎳᎩ ᏗᎪᏪᎵ, ᎯᎠ ᎢᏴ ᎠᏓᏠᎯᏍᏗ ᎾᏍᎩ ᎠᏍᎦᏯ ᏀᎾᎢ ᏀᎾ ᎯᎠ ᏙᎪᏩᎸ ᎪᎷᏩᏛᏗ ᎠᏃᏪᎵᏍᎬ ᎢᏯᏛᏁᎵᏓᏍᏗ.",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Cherokee", // Common name
	"ᏣᎳᎩ", // Native name
	0x13E3, // Cherokee letter TSA
	values,
	"ᎠᎣᎤᎴᎺᎾᏃᏆᏒᏔᏣᏫᏲᏴ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
