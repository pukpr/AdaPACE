with Interfaces.C.Strings;
with System;

-- defines the ada interface to the C functions in libxml2 and libxslt
package Pace.Server.Xslt is
   pragma Linker_Options ("-lxslt");
   pragma Linker_Options ("-lexslt");
   pragma Linker_Options ("-lxml2");
   pragma Linker_Options ("-lm");
   pragma Linker_Options ("-lz");

   use Interfaces.C.Strings;

   type Doc is private; -- xmlDocPtr
   type Style is private; --xsltStylesheetPtr

   -- use this to parse an xml file
   function Xmlparsefile (Document : String) return Doc;
   pragma Import (C, Xmlparsefile, "xmlParseFile");

   -- use this to parse an xml string in memory
   function Xmlparsememory (Buffer : String; Buffer_Len : Integer) return Doc;
   pragma Import (C, Xmlparsememory, "xmlParseMemory");

   function Xsltparsestylesheetfile (Style_Sheet : String) return Style;
   pragma Import (C, Xsltparsestylesheetfile, "xsltParseStylesheetFile");

   function Xsltapplystylesheet
              (S : Style;
               D : Doc;
               Params : System.Address := System.Null_Address) return Doc;
   pragma Import (C, Xsltapplystylesheet, "xsltApplyStylesheet");

   procedure Xsltsaveresulttostring (Xml_Str : access Chars_Ptr;
                                     Xml_Str_Len : access Integer;
                                     D : in Doc;
                                     S : in Style);
   pragma Import (C, Xsltsaveresulttostring, "xsltSaveResultToString");

   procedure Xsltfreestylesheet (S : Style);
   pragma Import (C, Xsltfreestylesheet, "xsltFreeStylesheet");

   procedure Xmlfreedoc (D : Doc);
   pragma Import (C, Xmlfreedoc, "xmlFreeDoc");


private
   type Doc is new System.Address;
   type Style is new System.Address;
end Pace.Server.Xslt;



