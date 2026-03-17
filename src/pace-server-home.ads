package Pace.Server.Home is
   -----------------------------------------
   -- HOME -- Home screen default processing
   -----------------------------------------
   pragma Elaborate_Body;

   procedure Create
     (Number_Of_Readers       : in Integer;
      Storage_Size_Per_Reader : in Integer);

   ------------------
   -- Building Blocks
   ------------------

   -- Callback URL Request
   procedure Page (Exec : in String);

   -- Test parser, Get_Data sent to Page
   type Basic is new Pace.Server.Session_Type with null record;
   procedure Get_Data (Obj : access Basic; Text : in String);

   procedure Set_Home_Page (Home : in String);

   Basic_Session : Pace.Server.Session_Access := new Basic;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-server-home.ads,v 1.1 09/16/2002 18:18:41 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Server.Home;
