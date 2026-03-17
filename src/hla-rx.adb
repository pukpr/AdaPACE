with Ada.Characters.Handling;
with Pace.Hash_Table;
with Interfaces.C.Strings;
with Pace.Log;
with Hla.KB;

package body Hla.Rx is

   function Id is new Pace.Log.Unit_Id;

   task Agent is pragma Task_Name (Pace.Log.Name);
      pragma Storage_Size (100_000_000);
      entry Inout (Obj : in out Init_Incoming);
   end Agent;

   pragma Warnings (Off);
   -- the warning is:
   --hla-rx.adb:21:17: warning: type of argument "Callback_Message.Data" is unconstrained array
   --hla-rx.adb:21:17: warning: foreign caller must pass bounds explicitly

   type CB_Type is access procedure 
     (Name, Parameter : in Interfaces.C.Strings.Chars_Ptr;
      Data : in Interfaces.C.Char_Array;
      Length : in Interfaces.C.Size_T;
      Counter : in Long_Integer);
   pragma Convention (C, CB_Type);
   --pragma Export (C, Callback_Message, "Callback_Message");


--    function Register_Interaction (Index : Integer) return Interfaces.C.Strings.Chars_Ptr;
--    pragma Export (C, Register_Interaction, "Register_Interaction");

   procedure Callback_Message
               (Name, Parameter : in Interfaces.C.Strings.Chars_Ptr;
                Data : in Interfaces.C.Char_Array;
                Length : in Interfaces.C.Size_T;
                Counter : in Long_Integer);
   pragma Convention (C, Callback_Message);
   pragma Warnings (On);

   procedure Callback_Message
               (Name, Parameter : in Interfaces.C.Strings.Chars_Ptr;
                Data : in Interfaces.C.Char_Array;
                Length : in Interfaces.C.Size_T;
                Counter : in Long_Integer) is
      use type Interfaces.C.Size_T;
      Act : constant String := Interfaces.C.Strings.Value (Name);
      Attr : constant String := Interfaces.C.Strings.Value (Parameter);
      Dat : constant String := Interfaces.C.To_Ada
                                 (Data (0 .. Length - 1), False);
   begin
      Pace.Log.Put_Line ("===RX CB===" & Act & Counter'Img, 8);
      Dispatch_To_Action (Act, Attr, Dat, Long_Integer (Counter));
   end Callback_Message;


   procedure Receive_Message (Handle : in Gateway;
                              CB : in CB_Type);
   pragma Import (C, Receive_Message, "Receive_Message");

   task body Agent is
      use Pace.Log;
      Handle : Gateway;
   begin
      Pace.Log.Agent_Id (Id);
      accept Inout (Obj : in out Init_Incoming) do
         Pace.Log.Trace (Obj);
         Handle := Obj.Handle;
      end Inout;
      Put_Line (Id & " started!");
      loop
         delay 0.5;
         declare
            L : Pace.Semaphore.Lock (Hla.Connection'Access);
         begin
            Receive_Message (Handle, Callback_Message'Access);
         end;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   -- Dispatching to clients

   type Channel is access all Action'Class;

   package Table is new Pace.Hash_Table.Simple_Htable (
                  Element => Channel,
                  No_Element => null,
                  Key => Ada.Tags.Tag,
                  Hash => Pace.Hash_Table.Hash,
                  Equal => Ada.Tags."=");

   protected Db is
      procedure Save_Action (Obj : in Action'Class);
      -- Saves the Class-wide object for later processing.
      procedure Dispatch_To_Action (Name, Parameter, Data : in String;
                                    Counter : in Long_Integer);
   end Db;

   protected body Db is

      procedure Save_Action (Obj : in Action'Class) is
      begin
         Table.Set (Obj'Tag, new Action'Class'(Obj));
      end Save_Action;

      procedure Dispatch_To_Action (Name, Parameter, Data : in String;
                                    Counter : in Long_Integer) is
         Msg : constant String := Ada.Characters.Handling.To_Upper (Name);
         Action_Obj : Channel;
         function Test_Factory return Channel is
         begin
            return Table.Get (Ada.Tags.Internal_Tag (Msg & ".A"));
         exception
            when Ada.Tags.Tag_Error =>
               return Table.Get (Ada.Tags.Internal_Tag (Msg));
         end Test_Factory;
      begin
         Action_Obj := Test_Factory;
         if Action_Obj = null then
            raise Not_Registered;
         end if;
         Input (Action_Obj.all, Parameter, Data, Counter);
      end Dispatch_To_Action;
   end Db;

   procedure Dispatch_To_Action (Name, Parameter, Data : in String;
                                 Counter : in Long_Integer) is
   begin
      Db.Dispatch_To_Action (Name, Parameter, Data, Counter);
   end Dispatch_To_Action;

   package body Factory is

      procedure Input (Obj : in A; Parameter, Data : in String;
                       Counter : in Long_Integer) is
      begin
         Process (Parameter, Data, ID, Counter);
      end Input;

      function Name return String is
      begin
         return ID; -- Hla.Kb.Class_Name(ID);
      end Name;

      function Name return Ada.Strings.Unbounded.Unbounded_String is
      begin
         return Hla.Name(ID); -- Hla.Kb.Class_Name(ID));
      end Name;

   begin
      Db.Save_Action (A'(Action with null record));
   end Factory;

   procedure Save_Action (Obj : in Action'Class) is
   begin
      Db.Save_Action (Obj);
   end;

   -- Dispatching from web server

   use Pace.Server.Dispatch;

   procedure Inout (Obj : in out Init_Incoming) is
   begin
      Agent.Inout (Obj);
   end Inout;

begin
   Save_Action (Init_Incoming'(Pace.Msg with Set => Default, Handle => Null_Gateway));
   -- $Id: hla-rx.adb,v 1.16 2006/03/16 21:41:54 pukitepa Exp $
end Hla.Rx;
