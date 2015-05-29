# Font Manager, a font management application for the GNOME desktop
#
# generated with intltool-extract --type=gettext/glade <filename>

import config

_("About Font Manager");
_("Add new font collection");
_("Close search box");
_("Custom Text");
_("Custom Text ");
_("Detailed Font Information");
_("Disable selected collection");
_("Disable selected fonts");
_("Enable selected collection");
_("Enable selected fonts");
_("Export collection");
_("Font Information");
_("Font Size:");
_("Help");
_("Manage Fonts");
_("Remove selected collection");
_("Remove selected fonts from list");
_("Rename Collection");
_("Sample Text");
_("Search through font listing");
_("Set application preferences");
_("Set font preferences");
_("Total Fonts: ");

# generated with Glade 3

ui="""<?xml version="1.0"?>
<interface>
  <requires lib="gtk+" version="2.16"/>
  <!-- interface-naming-policy project-wide -->
  <object class="GtkWindow" id="window">
    <property name="icon_name">preferences-desktop-font</property>
    <child>
      <object class="GtkVBox" id="top_box">
        <property name="visible">True</property>
        <property name="border_width">5</property>
        <property name="orientation">vertical</property>
        <child>
          <object class="GtkHBox" id="main_box">
            <property name="visible">True</property>
            <child>
              <object class="GtkVBox" id="collections_list_box">
                <property name="visible">True</property>
                <property name="border_width">5</property>
                <property name="orientation">vertical</property>
                <child>
                  <placeholder/>
                </child>
                <child>
                  <object class="GtkNotebook" id="collection_buttons_frame">
                    <property name="visible">True</property>
                    <property name="can_focus">True</property>
                    <property name="show_tabs">False</property>
                    <child>
                      <object class="GtkHBox" id="collections_button_box">
                        <property name="visible">True</property>
                        <property name="homogeneous">True</property>
                        <child>
                          <object class="GtkButton" id="new_collection">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Add new font collection</property>
                            <property name="image">add_collection_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_new_collection"/>
                          </object>
                          <packing>
                            <property name="position">0</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="remove_collection">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Remove selected collection</property>
                            <property name="image">collections_remove_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_remove_collection"/>
                          </object>
                          <packing>
                            <property name="position">1</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="enable_collection">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Enable selected collection</property>
                            <property name="image">collections_apply_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_enable_collection"/>
                          </object>
                          <packing>
                            <property name="position">2</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="disable_collection">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Disable selected collection</property>
                            <property name="image">collections_disable_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_disable_collection"/>
                          </object>
                          <packing>
                            <property name="position">3</property>
                          </packing>
                        </child>
                      </object>
                    </child>
                    <child type="tab">
                      <object class="GtkLabel" id="null1">
                        <property name="visible">True</property>
                      </object>
                      <packing>
                        <property name="tab_fill">False</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">4</property>
                    <property name="pack_type">end</property>
                    <property name="position">1</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkHBox" id="align1">
                    <property name="visible">True</property>
                    <child>
                      <placeholder/>
                    </child>
                    <child>
                      <object class="GtkButton" id="rename_collection">
                        <property name="label" translatable="yes">Rename Collection</property>
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                        <property name="receives_default">False</property>
                        <property name="relief">half</property>
                        <signal name="clicked" handler="on_rename_collection"/>
                      </object>
                      <packing>
                        <property name="padding">2</property>
                        <property name="position">1</property>
                      </packing>
                    </child>
                    <child>
                      <placeholder/>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">1</property>
                    <property name="pack_type">end</property>
                    <property name="position">0</property>
                  </packing>
                </child>
              </object>
              <packing>
                <property name="expand">False</property>
                <property name="fill">False</property>
                <property name="padding">1</property>
                <property name="position">0</property>
              </packing>
            </child>
            <child>
              <object class="GtkVBox" id="fonts_list_box">
                <property name="visible">True</property>
                <property name="border_width">5</property>
                <property name="orientation">vertical</property>
                <child>
                  <placeholder/>
                </child>
                <child>
                  <object class="GtkNotebook" id="fonts_button_frame">
                    <property name="visible">True</property>
                    <property name="can_focus">True</property>
                    <property name="show_tabs">False</property>
                    <child>
                      <object class="GtkHBox" id="fonts_button_box">
                        <property name="visible">True</property>
                        <child>
                          <object class="GtkButton" id="remove_font">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Remove selected fonts from list</property>
                            <property name="image">remove_font_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_remove_font"/>
                          </object>
                          <packing>
                            <property name="position">0</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="enable_font">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Enable selected fonts</property>
                            <property name="image">fonts_enable_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_enable_font"/>
                          </object>
                          <packing>
                            <property name="position">1</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="disable_font">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Disable selected fonts</property>
                            <property name="image">fonts_disable_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_disable_font"/>
                          </object>
                          <packing>
                            <property name="position">2</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="find_button">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Search through font listing</property>
                            <property name="image">find_icon</property>
                            <property name="relief">none</property>
                            <signal name="clicked" handler="on_find_button"/>
                          </object>
                          <packing>
                            <property name="position">3</property>
                          </packing>
                        </child>
                      </object>
                    </child>
                    <child type="tab">
                      <object class="GtkLabel" id="null2">
                        <property name="visible">True</property>
                      </object>
                      <packing>
                        <property name="tab_fill">False</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">4</property>
                    <property name="pack_type">end</property>
                    <property name="position">3</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkNotebook" id="find_box">
                    <property name="visible">True</property>
                    <property name="can_focus">True</property>
                    <property name="show_tabs">False</property>
                    <child>
                      <object class="GtkHBox" id="find_container">
                        <property name="visible">True</property>
                        <child>
                          <object class="GtkEntry" id="find_entry">
                            <property name="visible">True</property>
                            <property name="can_focus">True</property>
                            <property name="invisible_char">&#x25CF;</property>
                            <property name="secondary_icon_stock">gtk-clear</property>
                            <property name="secondary_icon_activatable">True</property>
                            <property name="secondary_icon_sensitive">True</property>
                            <signal name="icon_press" handler="on_find_entry_icon"/>
                          </object>
                          <packing>
                            <property name="position">0</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="close_find">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="tooltip_text" translatable="yes">Close search box</property>
                            <property name="image">close_find_icon</property>
                            <signal name="clicked" handler="on_close_find"/>
                          </object>
                          <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                            <property name="position">1</property>
                          </packing>
                        </child>
                      </object>
                    </child>
                    <child type="tab">
                      <object class="GtkLabel" id="null3">
                        <property name="visible">True</property>
                      </object>
                      <packing>
                        <property name="tab_fill">False</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="pack_type">end</property>
                    <property name="position">2</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkHBox" id="align2">
                    <property name="visible">True</property>
                    <child>
                      <placeholder/>
                    </child>
                    <child>
                      <object class="GtkButton" id="manage_fonts">
                        <property name="label" translatable="yes">Manage Fonts</property>
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                        <property name="receives_default">False</property>
                        <property name="relief">half</property>
                        <signal name="clicked" handler="on_manage_fonts"/>
                      </object>
                      <packing>
                        <property name="padding">2</property>
                        <property name="position">1</property>
                      </packing>
                    </child>
                    <child>
                      <placeholder/>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">1</property>
                    <property name="pack_type">end</property>
                    <property name="position">0</property>
                  </packing>
                </child>
              </object>
              <packing>
                <property name="expand">False</property>
                <property name="fill">False</property>
                <property name="padding">1</property>
                <property name="position">1</property>
              </packing>
            </child>
            <child>
              <object class="GtkVBox" id="font_preview_box">
                <property name="visible">True</property>
                <property name="border_width">2</property>
                <property name="orientation">vertical</property>
                <child>
                  <object class="GtkHBox" id="font_size_box">
                    <property name="visible">True</property>
                    <property name="border_width">2</property>
                    <child>
                      <object class="GtkHBox" id="combo_button_box">
                        <property name="visible">True</property>
                        <child>
                          <object class="GtkButton" id="compare">
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="image">compare_icon</property>
                            <property name="relief">half</property>
                          </object>
                          <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                            <property name="position">0</property>
                          </packing>
                        </child>
                        <child>
                          <object class="GtkButton" id="color_select">
                            <property name="can_focus">False</property>
                            <property name="receives_default">False</property>
                            <property name="image">color_icon</property>
                            <property name="relief">half</property>
                            <property name="focus_on_click">False</property>
                          </object>
                          <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                            <property name="position">1</property>
                          </packing>
                        </child>
                        <child>
                          <placeholder/>
                        </child>
                      </object>
                      <packing>
                        <property name="position">2</property>
                      </packing>
                    </child>
                    <child>
                      <object class="GtkLabel" id="font_size_label">
                        <property name="visible">True</property>
                        <property name="xalign">1</property>
                        <property name="xpad">3</property>
                        <property name="label" translatable="yes">Font Size:</property>
                      </object>
                      <packing>
                        <property name="pack_type">end</property>
                        <property name="position">1</property>
                      </packing>
                    </child>
                    <child>
                      <object class="GtkSpinButton" id="font_size_spinbutton">
                        <property name="visible">True</property>
                        <property name="can_focus">True</property>
                        <property name="invisible_char">&#x25CF;</property>
                        <property name="adjustment">size_adjustment</property>
                      </object>
                      <packing>
                        <property name="expand">False</property>
                        <property name="fill">False</property>
                        <property name="pack_type">end</property>
                        <property name="position">0</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">3</property>
                    <property name="position">0</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkScrolledWindow" id="scroll">
                    <property name="visible">True</property>
                    <property name="can_focus">True</property>
                    <property name="border_width">4</property>
                    <property name="hscrollbar_policy">automatic</property>
                    <property name="vscrollbar_policy">automatic</property>
                    <property name="shadow_type">etched-in</property>
                    <child>
                      <object class="GtkTextView" id="font_preview">
                        <property name="visible">True</property>
                        <property name="can_focus">True</property>
                        <property name="pixels_above_lines">1</property>
                        <property name="editable">False</property>
                        <property name="left_margin">6</property>
                        <property name="right_margin">6</property>
                        <property name="cursor_visible">False</property>
                      </object>
                    </child>
                  </object>
                  <packing>
                    <property name="position">1</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkNotebook" id="size_slider_frame">
                    <property name="visible">True</property>
                    <property name="border_width">4</property>
                    <property name="show_tabs">False</property>
                    <child>
                      <object class="GtkHScale" id="font_size_slider">
                        <property name="visible">True</property>
                        <property name="adjustment">size_adjustment</property>
                        <property name="draw_value">False</property>
                      </object>
                    </child>
                    <child type="tab">
                      <object class="GtkLabel" id="null4">
                        <property name="visible">True</property>
                      </object>
                      <packing>
                        <property name="tab_fill">False</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">1</property>
                    <property name="position">2</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkHBox" id="extended_preview_options_box">
                    <property name="visible">True</property>
                    <child>
                      <object class="GtkLabel" id="spacer">
                        <property name="visible">True</property>
                        <property name="label" translatable="yes"> </property>
                      </object>
                      <packing>
                        <property name="expand">False</property>
                        <property name="fill">False</property>
                        <property name="position">0</property>
                      </packing>
                    </child>
                    <child>
                      <object class="GtkButton" id="font_info">
                        <property name="label" translatable="yes">Detailed Font Information</property>
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                        <property name="receives_default">False</property>
                        <property name="relief">half</property>
                        <signal name="clicked" handler="on_font_info"/>
                      </object>
                      <packing>
                        <property name="position">1</property>
                      </packing>
                    </child>
                    <child>
                      <object class="GtkToggleButton" id="custom_text">
                        <property name="label" translatable="yes">Custom Text</property>
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                        <property name="receives_default">False</property>
                        <property name="relief">half</property>
                        <signal name="toggled" handler="on_custom_text"/>
                      </object>
                      <packing>
                        <property name="position">2</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">4</property>
                    <property name="position">3</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkHBox" id="preview_options_box">
                    <property name="visible">True</property>
                    <property name="border_width">3</property>
                    <child>
                      <object class="GtkRadioButton" id="sample_radio">
                        <property name="label" translatable="yes">Sample Text</property>
                        <property name="visible">True</property>
                        <property name="can_focus">True</property>
                        <property name="receives_default">False</property>
                        <property name="active">True</property>
                        <property name="draw_indicator">True</property>
                      </object>
                      <packing>
                        <property name="pack_type">end</property>
                        <property name="position">2</property>
                      </packing>
                    </child>
                    <child>
                      <object class="GtkRadioButton" id="font_info_radio">
                        <property name="label" translatable="yes">Font Information</property>
                        <property name="visible">True</property>
                        <property name="can_focus">True</property>
                        <property name="receives_default">False</property>
                        <property name="active">True</property>
                        <property name="draw_indicator">True</property>
                      </object>
                      <packing>
                        <property name="pack_type">end</property>
                        <property name="position">1</property>
                      </packing>
                    </child>
                    <child>
                      <object class="GtkRadioButton" id="custom_radio">
                        <property name="label" translatable="yes">Custom Text </property>
                        <property name="visible">True</property>
                        <property name="can_focus">True</property>
                        <property name="receives_default">False</property>
                        <property name="active">True</property>
                        <property name="draw_indicator">True</property>
                      </object>
                      <packing>
                        <property name="pack_type">end</property>
                        <property name="position">0</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="padding">3</property>
                    <property name="position">4</property>
                  </packing>
                </child>
              </object>
              <packing>
                <property name="padding">1</property>
                <property name="pack_type">end</property>
                <property name="position">2</property>
              </packing>
            </child>
          </object>
          <packing>
            <property name="position">0</property>
          </packing>
        </child>
        <child>
          <object class="GtkHBox" id="bottom_box">
            <property name="visible">True</property>
            <child>
              <object class="GtkHBox" id="align4">
                <property name="visible">True</property>
                <property name="homogeneous">True</property>
                <child>
                  <object class="GtkButton" id="about_button">
                    <property name="visible">True</property>
                    <property name="can_focus">True</property>
                    <property name="receives_default">True</property>
                    <property name="tooltip_text" translatable="yes">About Font Manager</property>
                    <property name="image">about_icon</property>
                    <property name="relief">half</property>
                    <signal name="clicked" handler="on_about_button"/>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="padding">2</property>
                    <property name="position">0</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkButton" id="help">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="receives_default">False</property>
                    <property name="tooltip_text" translatable="yes">Help</property>
                    <property name="image">help_icon</property>
                    <property name="relief">half</property>
                    <signal name="clicked" handler="on_help"/>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="position">1</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkButton" id="app_prefs">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="receives_default">False</property>
                    <property name="tooltip_text" translatable="yes">Set application preferences</property>
                    <property name="image">options_icon</property>
                    <property name="relief">half</property>
                    <signal name="clicked" handler="on_app_prefs"/>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="position">2</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkButton" id="font_preferences">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="receives_default">False</property>
                    <property name="tooltip_text" translatable="yes">Set font preferences</property>
                    <property name="image">font_prefs_icon</property>
                    <property name="relief">half</property>
                    <signal name="clicked" handler="on_font_preferences"/>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="position">3</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkButton" id="export">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="receives_default">False</property>
                    <property name="tooltip_text" translatable="yes">Export collection</property>
                    <property name="image">export_icon</property>
                    <property name="relief">half</property>
                    <signal name="clicked" handler="on_export"/>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="position">4</property>
                  </packing>
                </child>
              </object>
              <packing>
                <property name="expand">False</property>
                <property name="fill">False</property>
                <property name="padding">4</property>
                <property name="position">0</property>
              </packing>
            </child>
            <child>
              <object class="GtkHBox" id="align3">
                <property name="visible">True</property>
                <child>
                  <object class="GtkLabel" id="total_fonts">
                    <property name="visible">True</property>
                    <property name="label" translatable="yes">Total Fonts: </property>
                  </object>
                  <packing>
                    <property name="position">0</property>
                  </packing>
                </child>
              </object>
              <packing>
                <property name="expand">False</property>
                <property name="fill">False</property>
                <property name="padding">10</property>
                <property name="position">1</property>
              </packing>
            </child>
          </object>
          <packing>
            <property name="expand">False</property>
            <property name="fill">False</property>
            <property name="position">1</property>
          </packing>
        </child>
      </object>
    </child>
  </object>
  <object class="GtkImage" id="collections_apply_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-apply</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="collections_disable_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-no</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="fonts_enable_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-apply</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="fonts_disable_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-no</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkAdjustment" id="size_adjustment">
    <property name="value">12</property>
    <property name="lower">6</property>
    <property name="upper">97</property>
    <property name="step_increment">1</property>
    <property name="page_increment">6</property>
    <property name="page_size">1</property>
    <signal name="value_changed" handler="on_size_adjustment_value_changed"/>
  </object>
  <object class="GtkImage" id="collections_remove_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-remove</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="add_collection_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-add</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="close_find_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-close</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="find_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-find</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="remove_font_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-remove</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="color_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-select-color</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="about_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-about</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="help_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-help</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="font_prefs_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-select-font</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="options_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-preferences</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="export_icon">
    <property name="visible">True</property>
    <property name="icon_name">media-floppy</property>
    <property name="icon-size">1</property>
  </object>
  <object class="GtkImage" id="compare_icon">
    <property name="visible">True</property>
    <property name="stock">gtk-goto-first</property>
    <property name="icon-size">1</property>
  </object>
</interface>
"""
