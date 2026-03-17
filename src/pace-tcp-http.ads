package Pace.Tcp.Http is
   --------------------------------
   -- HTTP -- Client side interface
   --------------------------------
   -- Call contains the return page as does the return String on Get
   -- Init contains an optional initail HTTP GET parameter i.e. GET /[Init]Item

   pragma Elaborate_Body;

   type Initialize is access function return String;
   function Null_Init return String;

   type Callback is access procedure (Page : in String);
   procedure Null_Call (Page : in String);

   -- Communication_Error : exception; inherited

   function Get (Url : in String;
                 Item : in String;
                 Call : in Callback := Null_Call'Access;
                 Init : in Initialize := Null_Init'Access) return String;

   function Get (Host : in String;
                 Port : in Integer;
                 Item : in String;
                 Call : in Callback := Null_Call'Access;
                 Init : in Initialize := Null_Init'Access) return String;

   procedure Get (Url : in String;
                  Item : in String;
                  Call : in Callback := Null_Call'Access;
                  Init : in Initialize := Null_Init'Access);

   procedure Get (Host : in String;
                  Port : in Integer;
                  Item : in String;
                  Call : in Callback := Null_Call'Access;
                  Init : in Initialize := Null_Init'Access);

   generic
      with procedure Parse_Line (Line : in String);
   procedure Parse_Get (Page : in String);


   function Binary_Get (Host : in String;
                        Port : in Integer;
                        Item : in String;
                        Header_Discard : in Boolean := False) return String;

   function Post (Url : in String;
                  Item : in String;
                  Raw_Data : in String;
                  Content_Type : in String := "text/xml") return String;

------------------------------------------------------------------------------
-- $Id: pace-tcp-http.ads,v 1.2 2006/04/06 23:27:46 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Tcp.Http;
