//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// OrthographyData
//
//
#ifndef ORTHOGRAPHY_DATA
#define ORTHOGRAPHY_DATA

#ifndef UINT32
   typedef unsigned int UINT32; 
#endif

#define START_RANGE_PAIR 0x0002 // Using "STX" to demarcate the beginning of a range pair
#define END_OF_DATA 0x0000      // Using NULL to mark the end of a set

//
// OrthographyData
//
class OrthographyData{
	
	public:
	
	const char *commonName;
	const char *nativeName;
	UINT32 key;
	UINT32 *values;
	const char *sampleCharacters;
	const char **sampleSentences;
	
};


#endif
