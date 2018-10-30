//
// The Fontaine Font Analysis Project 
// 
// Copyright (c) 2009 by Edward H. Trager
// All Rights Reserved
// 
// Released under the GNU GPL version 2.0 or later.
//     


//
// ChessSymbols.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef CHESS_SYMBOLS
#define CHESS_SYMBOLS

namespace ChessSymbols{

//
// Unicode values 
//
UINT32 values[]={
	START_RANGE_PAIR,
	0x2654,0x265F,
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"♔♕♖♗♘♙♚♛♜♝♞♟",
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Chess Symbols", // Common name
	"Chess Symbols", // Native name
	0x2659, // WHITE CHESS PAWN
	values,
	"♔♕♖♗♘♙♚♛♜♝♞♟", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif
