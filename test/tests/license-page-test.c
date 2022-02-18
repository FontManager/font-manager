#include "test-application.h"
#include "font-manager-license-page.h"

const gchar *URL = "https://scripts.sil.org/OFL_web";

const gchar *OFL = "SIL OPEN FONT LICENSE \n \nVersion 1.1 - 26 February 2007 \n \nPREAMBLE \nThe "\
"goals of the Open Font License (OFL) are to stimulate worldwide \ndevelopment of collaborative font "\
"projects, to support the font creation \nefforts of academic and linguistic communities, and to "\
"provide a free and \nopen framework in which fonts may be shared and improved in partnership \nwith "\
"others. \n \nThe OFL allows the licensed fonts to be used, studied, modified and \nredistributed "\
"freely as long as they are not sold by themselves. The \nfonts, including any derivative works, "\
"can be bundled, embedded,  \nredistributed and/or sold with any software provided that any reserved "\
"\nnames are not used by derivative works. The fonts and derivatives, \nhowever, cannot be released "\
"under any other type of license. The \nrequirement for fonts to remain under this license does not "\
"apply \nto any document created using the fonts or their derivatives. \n \nDEFINITIONS \n\"Font "\
"Software\" refers to the set of files released by the Copyright \nHolder(s) under this license and "\
"clearly marked as such. This may \ninclude source files, build scripts and documentation. "\
"\n \n\"Reserved Font Name\" refers to any names specified as such after the \ncopyright statement(s). "\
"\n \n\"Original Version\" refers to the collection of Font Software components as \ndistributed by "\
"the Copyright Holder(s). \n \n\"Modified Version\" refers to any derivative made by adding to, "\
"deleting, \nor substituting — in part or in whole — any of the components of the \nOriginal Version, "\
"by changing formats or by porting the Font Software to a \nnew environment. \n \n\"Author\" refers "\
"to any designer, engineer, programmer, technical \nwriter or other person who contributed to the Font "\
"Software. \n \nPERMISSION & CONDITIONS \nPermission is hereby granted, free of charge, to any person "\
"obtaining \na copy of the Font Software, to use, study, copy, merge, embed, modify, \nredistribute, "\
"and sell modified and unmodified copies of the Font \nSoftware, subject to the following conditions: "\
"\n \n1) Neither the Font Software nor any of its individual components, \nin Original or Modified "\
"Versions, may be sold by itself. \n \n2) Original or Modified Versions of the Font Software may be "\
"bundled, \nredistributed and/or sold with any software, provided that each copy \ncontains the above "\
"copyright notice and this license. These can be \nincluded either as stand-alone text files, "\
"human-readable headers or \nin the appropriate machine-readable metadata fields within text or "\
"\nbinary files as long as those fields can be easily viewed by the user. \n \n3) No Modified Version "\
"of the Font Software may use the Reserved Font \nName(s) unless explicit written permission is "\
"granted by the corresponding \nCopyright Holder. This restriction only applies to the primary font "\
"name as \npresented to the users. \n \n4) The name(s) of the Copyright Holder(s) or the Author(s) "\
"of the Font \nSoftware shall not be used to promote, endorse or advertise any \nModified Version, "\
"except to acknowledge the contribution(s) of the \nCopyright Holder(s) and the Author(s) or with "\
"their explicit written \npermission. \n \n5) The Font Software, modified or unmodified, in part or "\
"in whole, \nmust be distributed entirely under this license, and must not be \ndistributed under "\
"any other license. The requirement for fonts to \nremain under this license does not apply to any "\
"document created \nusing the Font Software. \n \nTERMINATION \nThis license becomes null and void "\
"if any of the above conditions are \nnot met. \n \nDISCLAIMER \nTHE FONT SOFTWARE IS PROVIDED "\
"\"AS IS\", WITHOUT WARRANTY OF ANY KIND, \nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY "\
"WARRANTIES OF \nMERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT \nOF "\
"COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE \nCOPYRIGHT HOLDER BE LIABLE "\
"FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, \nINCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, "\
"OR CONSEQUENTIAL \nDAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING \nFROM, "\
"OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM \nOTHER DEALINGS IN THE FONT SOFTWARE.";

void
on_changed (GtkComboBox *control, gpointer user_data)
{
    if (gtk_combo_box_get_active(control) == 0) {
        font_manager_license_page_set_fsType(FONT_MANAGER_LICENSE_PAGE(user_data), 0);
        font_manager_license_page_set_license_data(FONT_MANAGER_LICENSE_PAGE(user_data), OFL);
        font_manager_license_page_set_license_url(FONT_MANAGER_LICENSE_PAGE(user_data), URL);
    } else {
        font_manager_license_page_set_fsType(FONT_MANAGER_LICENSE_PAGE(user_data), 2);
        font_manager_license_page_set_license_data(FONT_MANAGER_LICENSE_PAGE(user_data), NULL);
        font_manager_license_page_set_license_url(FONT_MANAGER_LICENSE_PAGE(user_data), NULL);
    }
    return;
}


G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "License Page", 600, 500);
    GtkWidget *license_pane = font_manager_license_page_new();
    GtkWidget *control = gtk_combo_box_text_new();
    gtk_combo_box_text_append(GTK_COMBO_BOX_TEXT(control), "OFL", "OFL License");
    gtk_combo_box_text_append(GTK_COMBO_BOX_TEXT(control), "NONE", "No License Data");
    g_signal_connect(control, "changed", G_CALLBACK(on_changed), license_pane);
    gtk_combo_box_set_active(GTK_COMBO_BOX(control), 0);
    test_dialog_append(dialog, license_pane);
    test_dialog_append_control(dialog, control);
    return dialog;
}
