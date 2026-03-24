with Ada.Tags;
with Pace.Server.Xml;
with Pace.Client;
with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Hash;
with Pace.Semaphore;
with Pace.Hash_Table;
with Pace.Log;
with Pace.Strings;
with Pace.Xml_Tree;
with Pace.Config;
with Pace.Strings;
with Ada.Calendar;

package body Pace.Server.Dispatch is
   use Pace.Strings;

   package Asu renames Ada.Strings.Unbounded;

   --  package Actions is new Pace.Lookup;
   package Actions is new Pace.Hash_Table.Simple_Htable
     (Element => Channel_Msg,
      No_Element => Null_Channel_Msg,
      Key => Ada.Tags.Tag,
      Hash => Pace.Hash_Table.Hash,
      Equal => Ada.Tags. "=");

   package Cache_Callbacks is new Pace.Hash_Table.Simple_Htable
     (Element => Pace.Server.Http_Caching.Cache_Counter_Ptr,
      No_Element => Pace.Server.Http_Caching.Null_Cache_Counter_Ptr,
      Key => Ada.Tags.Tag,
      Hash => Pace.Hash_Table.Hash,
      Equal => Ada.Tags. "=");

   use type Pace.Channel_Msg;

   Actions_Mutex : aliased Pace.Semaphore.Mutex;
   Cache_Mutex : aliased Pace.Semaphore.Mutex;

   procedure Save_Action (Obj : in Action'Class;
                          Publish_Callback : Pace.Client.Modified_Callback := Pace.Client.Default_Modified_Callback'Access;
                          Counter : Pace.Server.Http_Caching.Cache_Counter_Ptr := Pace.Server.Http_Caching.Null_Cache_Counter_Ptr) is
      use Pace.Server.Http_Caching;
      use Pace.Strings;
      use Pace.Client;
      L1 : Pace.Semaphore.Lock (Actions_Mutex'Access);
      L2 : Pace.Semaphore.Lock (Cache_Mutex'Access);
   begin
      Pace.Display ("Saving Action " & Pace.Tag (Obj) & ".");
      Actions.Set (Obj'Tag, +Obj);
      if Counter /= Null_Cache_Counter_Ptr then
         Cache_Callbacks.Set (Obj'Tag, Counter);
      end if;
      if Publish_Callback /= Pace.Client.Default_Modified_Callback'Access then
         Pace.Client.Add_Action (Pace.Tag (Obj), Publish_Callback);
      end if;
   exception
      when E : others =>
         Pace.Log.Ex (E);
         Pace.Display ("ERROR: Server Dispatch saving Action");
   end Save_Action;

   Not_Found_String : constant String := "@!?#!?!@%";

   function Extract_Set (Params : String) return String is
      Search : constant String := "set=";
      I : Integer := Ada.Strings.Fixed.Index (Params, Search);
   begin
      if I = 0 then
         return Params;
      else
         return Params (I+Search'Length .. Params'Last);
      end if;
   end Extract_Set;

   function Dispatch_To_Action (Name : in String) return String is
      use type Ada.Tags.Tag;
      use Pace.Strings;

      Tag : Ada.Tags.Tag;
      Action_Obj : Pace.Channel_Msg;
      Send_Full_Response : Boolean := True;
      -- Decode_Name : constant String := u2s(CGI.URL_Decode(s2u(Name)));
      Decode_Name : constant String := Decode(Name);
      Full_Name : constant String := Ada.Characters.Handling.To_Upper (Decode_Name);
      Uname : constant String := Pace.Strings.Select_Field (Full_Name, 1, '?');
      Sname : constant String := Pace.Strings.Select_Field (Decode_Name, 2, '?');
      Slash_Index : Integer;
   begin
      -- Pace.Log.Put_Line("#########" & Decode_Name & "#########" & Pace.Server.Value("") & "#########");
      if Uname = "" or Uname = "/" then
         return Not_Found_String;
      end if;
      if Uname (Uname'First) = '/' then
         Slash_Index := Pace.Strings.Count_Fields (Uname, '/');
         Tag := Ada.Tags.Internal_Tag
                  (Pace.Strings.Select_Field (Uname, Slash_Index, '/'));
      else
         Tag := Ada.Tags.Internal_Tag (Uname);
      end if;
      declare
         L : Pace.Semaphore.Lock (Actions_Mutex'Access);
      begin
         Action_Obj := Actions.Get (Tag);
      end;
      if Action_Obj = Null_Channel_Msg then
         Pace.Display
           ("ERROR: Server Dispatch found no Action for " & Name & ".");
         return Not_Found_String;
      end if;

      -- set the etag header only for those action requests which
      -- are cacheable
      declare
         L : Pace.Semaphore.Lock (Cache_Mutex'Access);
      begin
         declare
            use Ada.Characters.Handling;
            use Pace.Server.Http_Caching;
            Etag : Long_Integer;
            Etag_Counter : Cache_Counter_Ptr := Cache_Callbacks.Get (Tag);
         begin
            if Etag_Counter /= Null_Cache_Counter_Ptr then
               Pace.Log.Put_Line ("This is a cacheable action request", 7);
               if Default_Session.Is_Conditional_Get then
                  Etag := Etag_Counter.all.Get_Count;
                  Set_Etag (Default_Session, Etag);
                  Pace.Log.Put_Line ("The request is a conditional get and if_match is " &
                                     B2s (Default_Session.If_Match) &
                                     " and ETag is " & B2s (Default_Session.Etag), 7);
                  Send_Full_Response := To_Lower (B2s (Default_Session.If_Match)) /= To_Lower (B2s (Default_Session.Etag));
                  if Send_Full_Response then
                     Pace.Log.Put_Line ("Out of date.  Sending a full response!", 7);
                  else
                     Pace.Log.Put_Line ("Sending 304 Not Modified Response!", 7);
                     Pace.Server.Put_Content ("text/html", R304);
                  end if;
               end if;
            end if;
         end;
      end;

      if Send_Full_Response then
         declare
            Obj : Action'Class := Action'Class (+Action_Obj);
         begin
            Obj.Set := Asu.To_Unbounded_String
              (Pace.Server.Keys.Value ("set", Extract_Set (Sname)));
            Obj.Id := Pace.Current; -- identify thread that calls dispatch request
            Pace.Display ("Obj.Set input for request " & Name & " is :" & U2s (Obj.Set));
            Inout (Obj);
            if Pace.Server.Key_Exists ("put_data_set") then
               Pace.Server.Put_Data (Asu.To_String (Obj.Set));
            end if;
            return Asu.To_String (Obj.Set);
         end;
      else
         return "";
      end if;
   exception
      when E: Ada.Tags.Tag_Error =>
         Pace.Display ("ERROR: No Server Action Tag for " & Name);
         Pace.Log.Ex (E);
         return Not_Found_String;
      when E: others =>
         Pace.Display ("ERROR: Server Action : " & Name);
         Pace.Log.Ex (E);
         return Not_Found_String;
   end Dispatch_To_Action;

   function Dispatch_To_Action (Name : in String) return Boolean is
   begin
      return Dispatch_To_Action (Name) /= Not_Found_String;
   end Dispatch_To_Action;

   procedure Inout (Obj : in out Show_All) is
      L : Pace.Semaphore.Lock (Actions_Mutex'Access);
      Action_Channel : Pace.Channel_Msg;
      Default_Stylesheet : String := "/eng/show_all.xsl";
      Sorted_Actions : Pace.Strings.Ustr_List.List;
      use Pace.Server;
      use Pace.Strings.Ustr_List;
   begin
      -- put names of tags into Sorted_Actions
      Actions.Iterator.Reset;
      while not Actions.Iterator.Done loop
         Action_Channel := Actions.Iterator.Next;
         if Action_Channel /= Null_Channel_Msg then
            declare
               Action_To_Insert : Asu.Unbounded_String :=
                 Asu.To_Unbounded_String (Pace.Tag
                                          (Action'Class (+Action_Channel)));
            begin
               Append (Sorted_Actions, Action_To_Insert);
            end;
         end if;
      end loop;
      -- sort the list
      Pace.Strings.Ustr_Sort.Sort (Sorted_Actions);

      -- iterate through list and produce output
      declare
         I : Cursor := First (Sorted_Actions);
         Action_Xml : Asu.Unbounded_String;
         use Pace.Server.Xml;
      begin
         while I /= No_Element loop
            Action_Channel := Actions.Get(Ada.Tags.Internal_Tag
                                                (Asu.To_String (Element (I))));
            if Action_Channel /= Null_Channel_Msg then
               declare
                  Action_Obj : Action'Class := Action'Class (+Action_Channel);
               begin
                  Asu.Append
                    (Action_Xml,
                     Item (Element => "Action",
                           Value => Item (Element => "Tag_Name",
                                          Value => Pace.Tag (Action_Obj)) &
                                    Item (Element => "set",
                                          Value => Asu.To_String
                                                     (Action_Obj.Set))));
               exception
                  when E: others =>
                     Pace.Error (Pace.X_Info (E));
               end;
            end if;
            Next (I);
         end loop;
         Pace.Server.Xml.Put_Content (Default_Stylesheet => Default_Stylesheet);
         Pace.Server.Put_Data (Item (Element => "Show_All",
                                     Value => Asu.To_String (Action_Xml)));

      end;
   exception
      when E: others =>
         Pace.Error (Pace.X_Info (E));
   end Inout;

   procedure Inout (Obj : in out Wait) is
      Time_To_Wait : Duration := Duration'Value (Pace.Xml_Tree.Search_Xml (U2s (Obj.Set), "time", "0.0"));
   begin
      Pace.Log.Wait (Time_To_Wait);
   end Inout;

   procedure Append (Obj : in out Action; Text : in String) is
      use Ada.Strings.Unbounded;
   begin
      -- this clears out the set parameter during the initial append
      -- so the Xml_Set string won't appear in the xml output
      if Obj.Set = Xml_Set then
         Obj.Set := Null_Unbounded_String;
      end if;
      Asu.Append (Obj.Set, Text);
   end Append;

   function X (Name, Value : in String) return String is
   begin
      return "&lt;" & Name & "&gt;" & Value & "&lt;/" & Name & "&gt;";
   end X;

begin

   Save_Action (Show_All'(Pace.Msg with Set => Default));
   Save_Action (Wait'(Pace.Msg with Set => S2u (X ("time", "0.0"))));

------------------------------------------------------------------------------
------------------------------------------------------------------------------
end Pace.Server.Dispatch;
