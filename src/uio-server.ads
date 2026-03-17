package Uio.Server is
   --
   -- Web and P4 server
   --
   pragma Elaborate_Body;

   procedure Create (Number_Of_Readers : in Integer := 10;
                     Storage_Size_Per_Reader : in Integer := 100_000;
                     P4_On : in Boolean := True);


   -- Web interface to local host
   --  example call:  URL( Query => "ANT.MAN.BEE", 
   --                     Params => p("a",1) + p("b","yes"))
   --
   function "+" (L, R : in String) return String;
   function P (Key, Value : in String) return String;
   function P (Key : in String; Value : in Integer) return String;
   function P (Key : in String; Value : in Float) return String;
   function Url (Query : in String; Params : in String := "") return String;
   function Url (Host : in String; Port : in Integer; Query : in String)
                return String;

   -- Call to dispatching command, bypassing URL / CGI
   procedure Call (Query : in String; Params : in String := "");

-- $id: uio-server.ads,v 1.5 02/04/2003 14:25:39 pukitepa Exp $

end Uio.Server;
