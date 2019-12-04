#include <string.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <sys/stat.h>

#include "OrthographyData.h"
#include "fontaine/orthographies.h"

using namespace std;

void print_struct(const char *name, const OrthographyData *p) {

    ofstream outfile;
    ostringstream filename;
    filename << "PROCESSED/" << name;
    outfile.open(filename.str());

    cout << "    _(\"" << p->commonName << "\")" << endl;
    cout << (strlen(p->nativeName) > 0 ? p->nativeName : p->commonName);
    cout << "\" }," << endl;

    outfile << "{" << endl;
    outfile << "    \"" << p->commonName << "\"," << endl;
    outfile << "    \"" << p->nativeName << "\"," << endl;
    outfile << "    0x" << std::hex << p->key << "," << endl;
    outfile << "    \"" << p->sampleCharacters << "\"," << endl;

    outfile << "    { " << endl;

    for(int i = 0; p->sampleSentences[i]; i++)
        outfile << "        \"" << p->sampleSentences[i] << "\", " << endl;

    outfile << "        END_OF_DATA" << endl << "    }," << endl;
    outfile << "    { " << endl;

    for (int i = 0; p->values[i]; i++) {

        if (p->values[i] == START_RANGE_PAIR) {
            outfile << "        FONT_MANAGER_START_RANGE_PAIR," << endl;
            outfile << "        0x" << std::hex << p->values[++i] << ", ";
            outfile << "0x" << std::hex << p->values[++i] << "," << endl;

        } else {
            outfile << "        0x" << std::hex << p->values[i] << "," << endl;
        }
    }

    outfile << "        FONT_MANAGER_END_OF_DATA" << endl << "    }" << endl << "}," << endl << endl;
    outfile.close();
}

int main(int argc, const char *argv[]) {

    //cout << "static const struct {" << endl;
    //cout << "    const gchar *name;" << endl;
    //cout << "    const gchar *native;" << endl;
    //cout << "} " << endl << "Orthographies [] = " << endl << "{" << endl;

    mkdir("PROCESSED", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);

    // for i in *.h; do echo print_struct\(\"${i/.h/}\", ${i/.h/::pData}\)\;; done
    print_struct("Afrikaans", Afrikaans::pData);
    print_struct("Ahom", Ahom::pData);
    print_struct("AleutCyrillic", AleutCyrillic::pData);
    print_struct("AleutLatin", AleutLatin::pData);
    print_struct("Arabic", Arabic::pData);
    print_struct("ArchaicGreekLetters", ArchaicGreekLetters::pData);
    print_struct("Armenian", Armenian::pData);
    print_struct("Astronomy", Astronomy::pData);
    print_struct("Balinese", Balinese::pData);
    print_struct("Baltic", Baltic::pData);
    print_struct("Bamum", Bamum::pData);
    print_struct("BasicCyrillic", BasicCyrillic::pData);
    print_struct("BasicGreek", BasicGreek::pData);
    print_struct("BasicLatin", BasicLatin::pData);
    print_struct("Batak", Batak::pData);
    print_struct("Bengali", Bengali::pData);
    print_struct("Brahmi", Brahmi::pData);
    print_struct("Buginese", Buginese::pData);
    print_struct("CanadianSyllabics", CanadianSyllabics::pData);
    print_struct("Carian", Carian::pData);
    print_struct("Catalan", Catalan::pData);
    print_struct("CentralEuropean", CentralEuropean::pData);
    print_struct("Chakma", Chakma::pData);
    print_struct("Cham", Cham::pData);
    print_struct("Cherokee", Cherokee::pData);
    print_struct("ChessSymbols", ChessSymbols::pData);
    print_struct("ClaudianLetters", ClaudianLetters::pData);
    print_struct("Coptic", Coptic::pData);
    print_struct("Currencies", Currencies::pData);
    print_struct("CypriotSyllabary", CypriotSyllabary::pData);
    print_struct("Devanagari", Devanagari::pData);
    print_struct("Dutch", Dutch::pData);
    print_struct("EgyptianHieroglyphs", EgyptianHieroglyphs::pData);
    print_struct("Emoticons", Emoticons::pData);
    print_struct("Ethiopic", Ethiopic::pData);
    print_struct("Euro", Euro::pData);
    //print_struct("ExtendedArabic", ExtendedArabic::pData);
    print_struct("Farsi", Farsi::pData);
    print_struct("Food", Food::pData);
    print_struct("Georgian", Georgian::pData);
    print_struct("Glagolitic", Glagolitic::pData);
    print_struct("Gothic", Gothic::pData);
    print_struct("Gujarati", Gujarati::pData);
    print_struct("Gurmukhi", Gurmukhi::pData);
    print_struct("Hangul", Hangul::pData);
    print_struct("Hanunoo", Hanunoo::pData);
    print_struct("Hebrew", Hebrew::pData);
    print_struct("HKSCS", HKSCS::pData);
    print_struct("IgboOnwu", IgboOnwu::pData);
    print_struct("IPA", IPA::pData);
    print_struct("Jamo", Jamo::pData);
    print_struct("Javanese", Javanese::pData);
    print_struct("Jinmeiyo", Jinmeiyo::pData);
    print_struct("Joyo", Joyo::pData);
    print_struct("Kaithi", Kaithi::pData);
    print_struct("Kana", Kana::pData);
    print_struct("Kannada", Kannada::pData);
    print_struct("KayahLi", KayahLi::pData);
    print_struct("Kazakh", Kazakh::pData);
    print_struct("Kharoshthi", Kharoshthi::pData);
    print_struct("Khmer", Khmer::pData);
    print_struct("Kokuji", Kokuji::pData);
    print_struct("Lao", Lao::pData);
    print_struct("LatinLigatures", LatinLigatures::pData);
    print_struct("Lepcha", Lepcha::pData);
    print_struct("Limbu", Limbu::pData);
    print_struct("LinearBIdeograms", LinearBIdeograms::pData);
    print_struct("LinearBSyllabary", LinearBSyllabary::pData);
    print_struct("Malayalam", Malayalam::pData);
    print_struct("MathematicalGreek", MathematicalGreek::pData);
    print_struct("MathematicalLatin", MathematicalLatin::pData);
    print_struct("MathematicalNumerals", MathematicalNumerals::pData);
    print_struct("MathematicalOperators", MathematicalOperators::pData);
    print_struct("MeeteiMayak", MeeteiMayak::pData);
    print_struct("MendeKikakui", MendeKikakui::pData);
    print_struct("MeroiticCursive", MeroiticCursive::pData);
    print_struct("MeroiticHieroglyphs", MeroiticHieroglyphs::pData);
    print_struct("Miao", Miao::pData);
    print_struct("Mongolian", Mongolian::pData);
    print_struct("MUFI", MUFI::pData);
    print_struct("Myanmar", Myanmar::pData);
    print_struct("NewTaiLue", NewTaiLue::pData);
    print_struct("Nko", Nko::pData);
    print_struct("Ogham", Ogham::pData);
    print_struct("OlChiki", OlChiki::pData);
    print_struct("OldItalic", OldItalic::pData);
    print_struct("OldSouthArabian", OldSouthArabian::pData);
    print_struct("Oriya", Oriya::pData);
    print_struct("Osmanya", Osmanya::pData);
    print_struct("PanAfricanLatin", PanAfricanLatin::pData);
    print_struct("Pashto", Pashto::pData);
    print_struct("PhagsPa", PhagsPa::pData);
    print_struct("Pinyin", Pinyin::pData);
    print_struct("Polynesian", Polynesian::pData);
    print_struct("PolytonicGreek", PolytonicGreek::pData);
    print_struct("Rejang", Rejang::pData);
    print_struct("Romanian", Romanian::pData);
    print_struct("Runic", Runic::pData);
    print_struct("Saurashtra", Saurashtra::pData);
    print_struct("SimplifiedChinese", SimplifiedChinese::pData);
    print_struct("Sindhi", Sindhi::pData);
    print_struct("Sinhala", Sinhala::pData);
    // Empty data
    //print_struct("Siraiki", Siraiki::pData);
    print_struct("SouthKoreanHanja", SouthKoreanHanja::pData);
    print_struct("Sundanese", Sundanese::pData);
    print_struct("SylotiNagri", SylotiNagri::pData);
    print_struct("Syriac", Syriac::pData);
    print_struct("TaiLe", TaiLe::pData);
    print_struct("TaiTham", TaiTham::pData);
    print_struct("TaiViet", TaiViet::pData);
    print_struct("Tamil", Tamil::pData);
    print_struct("Telugu", Telugu::pData);
    print_struct("Thaana", Thaana::pData);
    print_struct("Thai", Thai::pData);
    print_struct("Tibetan", Tibetan::pData);
    print_struct("Tifinagh", Tifinagh::pData);
    print_struct("TraditionalChinese", TraditionalChinese::pData);
    print_struct("Turkish", Turkish::pData);
    print_struct("Uighur", Uighur::pData);
    print_struct("Urdu", Urdu::pData);
    print_struct("Vai", Vai::pData);
    print_struct("VedicExtensions", VedicExtensions::pData);
    print_struct("Venda", Venda::pData);
    print_struct("Vietnamese", Vietnamese::pData);
    print_struct("WesternEuropean", WesternEuropean::pData);
    print_struct("Yi", Yi::pData);
    print_struct("ZhuYinFuHao", ZhuYinFuHao::pData);

    //cout << "};" << endl;

    return 0;

}
