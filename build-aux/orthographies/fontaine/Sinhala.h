//
// Sinhala.h
//

#ifndef ORTHOGRAPHY_DATA
#include "../OrthographyData.h"
#endif

#ifndef SINHALA
#define SINHALA

namespace Sinhala{

//
// Unicode values 
//
UINT32 values[]={
	// Sinhala - Various signs
	0x0D82 , // ( ං ) SINHALA SIGN ANUSVARAYA
	0x0D83 , // ( ඃ ) SINHALA SIGN VISARGAYA
	// Sinhala - Independent vowels
	0x0D85 , // ( අ ) SINHALA LETTER AYANNA
	0x0D86 , // ( ආ ) SINHALA LETTER AAYANNA
	0x0D87 , // ( ඇ ) SINHALA LETTER AEYANNA
	0x0D88 , // ( ඈ ) SINHALA LETTER AEEYANNA
	0x0D89 , // ( ඉ ) SINHALA LETTER IYANNA
	0x0D8A , // ( ඊ ) SINHALA LETTER IIYANNA
	0x0D8B , // ( උ ) SINHALA LETTER UYANNA
	0x0D8C , // ( ඌ ) SINHALA LETTER UUYANNA
	0x0D8D , // ( ඍ ) SINHALA LETTER IRUYANNA
	0x0D8E , // ( ඎ ) SINHALA LETTER IRUUYANNA
	0x0D8F , // ( ඏ ) SINHALA LETTER ILUYANNA
	0x0D90 , // ( ඐ ) SINHALA LETTER ILUUYANNA
	0x0D91 , // ( එ ) SINHALA LETTER EYANNA
	0x0D92 , // ( ඒ ) SINHALA LETTER EEYANNA
	0x0D93 , // ( ඓ ) SINHALA LETTER AIYANNA
	0x0D94 , // ( ඔ ) SINHALA LETTER OYANNA
	0x0D95 , // ( ඕ ) SINHALA LETTER OOYANNA
	0x0D96 , // ( ඖ ) SINHALA LETTER AUYANNA
	// Sinhala - Consonants
	0x0D9A , // ( ක ) SINHALA LETTER ALPAPRAANA KAYANNA
	0x0D9B , // ( ඛ ) SINHALA LETTER MAHAAPRAANA KAYANNA
	0x0D9C , // ( ග ) SINHALA LETTER ALPAPRAANA GAYANNA
	0x0D9D , // ( ඝ ) SINHALA LETTER MAHAAPRAANA GAYANNA
	0x0D9E , // ( ඞ ) SINHALA LETTER KANTAJA NAASIKYAYA
	0x0D9F , // ( ඟ ) SINHALA LETTER SANYAKA GAYANNA
	0x0DA0 , // ( ච ) SINHALA LETTER ALPAPRAANA CAYANNA
	0x0DA1 , // ( ඡ ) SINHALA LETTER MAHAAPRAANA CAYANNA
	0x0DA2 , // ( ජ ) SINHALA LETTER ALPAPRAANA JAYANNA
	0x0DA3 , // ( ඣ ) SINHALA LETTER MAHAAPRAANA JAYANNA
	0x0DA4 , // ( ඤ ) SINHALA LETTER TAALUJA NAASIKYAYA
	0x0DA5 , // ( ඥ ) SINHALA LETTER TAALUJA SANYOOGA NAAKSIKYAYA
	0x0DA6 , // ( ඦ ) SINHALA LETTER SANYAKA JAYANNA
	0x0DA7 , // ( ට ) SINHALA LETTER ALPAPRAANA TTAYANNA
	0x0DA8 , // ( ඨ ) SINHALA LETTER MAHAAPRAANA TTAYANNA
	0x0DA9 , // ( ඩ ) SINHALA LETTER ALPAPRAANA DDAYANNA
	0x0DAA , // ( ඪ ) SINHALA LETTER MAHAAPRAANA DDAYANNA
	0x0DAB , // ( ණ ) SINHALA LETTER MUURDHAJA NAYANNA
	0x0DAC , // ( ඬ ) SINHALA LETTER SANYAKA DDAYANNA
	0x0DAD , // ( ත ) SINHALA LETTER ALPAPRAANA TAYANNA
	0x0DAE , // ( ථ ) SINHALA LETTER MAHAAPRAANA TAYANNA
	0x0DAF , // ( ද ) SINHALA LETTER ALPAPRAANA DAYANNA
	0x0DB0 , // ( ධ ) SINHALA LETTER MAHAAPRAANA DAYANNA
	0x0DB1 , // ( න ) SINHALA LETTER DANTAJA NAYANNA
	0x0DB3 , // ( ඳ ) SINHALA LETTER SANYAKA DAYANNA
	0x0DB4 , // ( ප ) SINHALA LETTER ALPAPRAANA PAYANNA
	0x0DB5 , // ( ඵ ) SINHALA LETTER MAHAAPRAANA PAYANNA
	0x0DB6 , // ( බ ) SINHALA LETTER ALPAPRAANA BAYANNA
	0x0DB7 , // ( භ ) SINHALA LETTER MAHAAPRAANA BAYANNA
	0x0DB8 , // ( ම ) SINHALA LETTER MAYANNA
	0x0DB9 , // ( ඹ ) SINHALA LETTER AMBA BAYANNA
	0x0DBA , // ( ය ) SINHALA LETTER YAYANNA
	0x0DBB , // ( ර ) SINHALA LETTER RAYANNA
	0x0DBD , // ( ල ) SINHALA LETTER DANTAJA LAYANNA
	0x0DC0 , // ( ව ) SINHALA LETTER VAYANNA
	0x0DC1 , // ( ශ ) SINHALA LETTER TAALUJA SAYANNA
	0x0DC2 , // ( ෂ ) SINHALA LETTER MUURDHAJA SAYANNA
	0x0DC3 , // ( ස ) SINHALA LETTER DANTAJA SAYANNA
	0x0DC4 , // ( හ ) SINHALA LETTER HAYANNA
	0x0DC5 , // ( ළ ) SINHALA LETTER MUURDHAJA LAYANNA
	0x0DC6 , // ( ෆ ) SINHALA LETTER FAYANNA
	// Sinhala - Sign
	0x0DCA , // ( ් ) SINHALA SIGN AL-LAKUNA
	// Sinhala - Dependent vowel signs
	0x0DCF , // ( ා ) SINHALA VOWEL SIGN AELA-PILLA
	0x0DD0 , // ( ැ ) SINHALA VOWEL SIGN KETTI AEDA-PILLA
	0x0DD1 , // ( ෑ ) SINHALA VOWEL SIGN DIGA AEDA-PILLA
	0x0DD2 , // ( ි ) SINHALA VOWEL SIGN KETTI IS-PILLA
	0x0DD3 , // ( ී ) SINHALA VOWEL SIGN DIGA IS-PILLA
	0x0DD4 , // ( ු ) SINHALA VOWEL SIGN KETTI PAA-PILLA
	0x0DD6 , // ( ූ ) SINHALA VOWEL SIGN DIGA PAA-PILLA
	0x0DD8 , // ( ෘ ) SINHALA VOWEL SIGN GAETTA-PILLA
	0x0DD9 , // ( ෙ ) SINHALA VOWEL SIGN KOMBUVA
	0x0DDA , // ( ේ ) SINHALA VOWEL SIGN DIGA KOMBUVA
	0x0DDB , // ( ෛ ) SINHALA VOWEL SIGN KOMBU DEKA
	// Sinhala - Two-part dependent vowel signs
	0x0DDC , // ( ො ) SINHALA VOWEL SIGN KOMBUVA HAA AELA-PILLA
	0x0DDD , // ( ෝ ) SINHALA VOWEL SIGN KOMBUVA HAA DIGA AELA-PILLA
	0x0DDE , // ( ෞ ) SINHALA VOWEL SIGN KOMBUVA HAA GAYANUKITTA
	// Sinhala - Dependent vowel sign
	0x0DDF , // ( ෟ ) SINHALA VOWEL SIGN GAYANUKITTA
	// Sinhala - Additional dependent vowel signs
	0x0DF2 , // ( ෲ ) SINHALA VOWEL SIGN DIGA GAETTA-PILLA
	0x0DF3 , // ( ෳ ) SINHALA VOWEL SIGN DIGA GAYANUKITTA
	// Sinhala - Punctuation
	0x0DF4 , // ( ෴ ) SINHALA PUNCTUATION KUNDDALIYA
	END_OF_DATA
};

//
// Sample sentences
// 
const char *sentences[]={
	"ක ඛ ග ඝ ඞ ඟ ච ඡ", // using sample letters for now ...
	END_OF_DATA
};


//
// 
//
OrthographyData data={
	"Sinhala", // Common name
	"සිංහල", // Native name
	0x0D9A, // key
	values,
	"ක ඛ ග ඝ ඞ ඟ ච ඡ", // Sample characters
	sentences
};

const OrthographyData *pData = &data;

}; // end of namespace

#endif