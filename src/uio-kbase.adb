with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Pace.Rule_Process;
with Pace.Log;
with Pace.Server;
with Pace.Config;
with Pace.Server.Html;
with Pace.Server.Dispatch;
with Pace.Server.Kbase_Utilities;
with Pace.Strings;

package body Uio.Kbase is

   use Pace.Strings;

   Kb : Pace.Rule_Process.Agent_Type (100_000);

   function Replace is new Pace.Server.Html.Template
                             ("<?set ", "?>", Pace.Server.Dispatch.
                                                Dispatch_To_Action);


   type Assertion is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Assertion);

   procedure Inout (Obj : in out Assertion) is
      use Pace.Server.Dispatch;
   begin
      Kb.Assert (U2s (Obj.Set));
   end Inout;

   type Listing is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Listing);

   procedure Inout (Obj : in out Listing) is
      use Pace.Server.Dispatch;
      use Pace.Rule_Process;
      V : Variables (1 .. 0);
   begin
      Kb.Query ("listing", V);
   end Inout;


   function Get_String (Name : in String) return String is
      use Pace.Rule_Process;
      V : Variables (1 .. 1);
   begin
      Kb.Query (Name, V);
      return U2s (V (1));
   end Get_String;

   function Get_String (Name : in String; Id : in String) return String is
      use Pace.Rule_Process;
      V : Variables (1 .. 2);
   begin
      V (1) := S2u (Id);
      Kb.Query (Name, V);
      return U2s (V (2));
   end Get_String;

   function Get_String (Name : in String; Id, Aux : in String) return String is
      use Pace.Rule_Process;
      V : Variables (1 .. 3);
   begin
      V (1) := S2u (Id);
      V (2) := S2u (Aux);
      Kb.Query (Name, V);
      return U2s (V (3));
   end Get_String;

   function Get_Integer (Name : in String; Id : in String) return Integer is
   begin
      return Integer'Value (Get_String (Name, Id));
   end Get_Integer;

   procedure Load (File_Path : in String) is
   begin
      Kb.Load (File_Path);
   exception
      when Pace.Rule_Process.No_Match =>
         Pace.Log.Put_Line ("File Not Loaded " & File_Path);
   end Load;


   function Parse (Tag_Name : in String) return String is
      use Ada.Strings.Fixed, Ada.Strings.Maps, Ada.Characters.Handling;
   begin
      return Translate (To_Lower (Tag_Name), To_Mapping (".", ","));
   end Parse;

   procedure Load (Obj : in Pace.Server.Dispatch.Action'Class) is
      use Pace.Server.Html;
   begin
      Pace.Log.Put_Line (Pace.Tag (Obj) & " loading page");

      Pace.Server.Put_Data (Replace
                              (Read_File (Get_String
                                            ("page", Parse (Pace.Tag (Obj))))));
   exception
      when Pace.Rule_Process.No_Match =>
         Pace.Log.Put_Line (Pace.Tag (Obj) & " not found");
   end Load;

   procedure Get_String (Obj : in out Pace.Server.Dispatch.Action'Class) is
      use Pace.Server.Dispatch;
   begin
      Pace.Log.Put_Line (Pace.Tag (Obj) & " getting template string component");
      if U2s(Obj.Set) = U2s(Default) then
         Obj.Set := S2u (Pace.Server.Html.Read_File
                         (Get_String ("template", Parse (Pace.Tag (Obj)))));
      else
         Obj.Set := S2u (Pace.Server.Html.Read_File
                         (Get_String
                          ("template", Parse (Pace.Tag (Obj)), U2s (Obj.Set))));
      end if;
   exception
      when Pace.Rule_Process.No_Match =>
         Obj.Set := S2u ("EMPTY");
   end Get_String;

   procedure Get_File (Obj : in out Pace.Server.Dispatch.Action'Class) is
      use Pace.Server.Dispatch;
   begin
      Pace.Log.Put_Line (Pace.Tag (Obj) & " getting template file component");
      if U2s(Obj.Set) = U2s(Default) then
         Obj.Set := S2u (Get_String ("template", Parse (Pace.Tag (Obj))));
      else
         Obj.Set := S2u (Get_String ("template", Parse (Pace.Tag (Obj)), U2s (Obj.Set)));
      end if;
   exception
      when Pace.Rule_Process.No_Match =>
         Obj.Set := S2u ("EMPTY");
   end Get_File;

   procedure Callback (Obj : in out Stored_Image; Data : in String) is
   begin
      Pace.Server.Put_Data (Data, True, True);
   end Callback;

   procedure Serve_Image (Obj : in out Stored_Image'Class;
                          Send : in Boolean := True) is
   begin
      Pace.Server.Put_Content (Content => "image/gif");
      Img.Image_Gif (Obj);
      if Send then
         null; -- Pace.Server.S end_Data ("");
      else
         Pace.Server.Put_Data ("");
      end if;
   end Serve_Image;

   type Query is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Query);


   procedure Inout (Obj : in out Query) is
      use Pace.Server.Dispatch;
   begin
      Pace.Server.Kbase_Utilities.Query_Kbase (Kb, Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

begin
   Kb.Init (Ini_File => "",
            Console => False,
            Screen => Pace.Getenv ("PACE_UIO_DEBUG", 0) = 1,
            Ini => (Clause => 1000,
                    Hash => 507,
                    In_Toks => 500,
                    Out_Toks => 500,
                    Frames => 4000,
                    Goals => 6000,
                    Subgoals => 300,
                    Trail => 5000,
                    Control => 700));

   declare
      use Pace.Server.Dispatch;
   begin
      Save_Action (Assertion'(Pace.Msg with Set => Default));
      Save_Action (Listing'(Pace.Msg with Set => Default));
      Save_Action (Query'(Pace.Msg with Set => S2u ("listing")));
   end;

end Uio.Kbase;
