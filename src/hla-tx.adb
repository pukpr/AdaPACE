with Ada.Strings.Unbounded;
with Pace.Log;
with Interfaces.C;

package body Hla.Tx is

   package C renames Interfaces.C;
   subtype C_Array is C.Char_Array (0 .. 99_999); -- matches C for buffer size

   type Get_Tuple_CB is access procedure (Param, Data : out C_Array; 
                                          Length : out C.Size_T);
   pragma Convention (C, Get_Tuple_CB);

   procedure Send_Message (Name : in C.Char_Array;
                           Length : in Integer; 
                           Handle : Gateway;
                           Get_Tuple : in Get_Tuple_CB);
   pragma Import (C, Send_Message, "Send_Message");

   procedure Update_Attributes (Name : in C.Char_Array; 
                                Length : in Integer; 
                                Handle : in Gateway;
                                Get_Tuple : in Get_Tuple_CB);
   pragma Import (C, Update_Attributes, "Update_Attributes");

   Started : Boolean := False;

   procedure Inout (Obj : in out Init_Outgoing) is
   begin
      Started := True;
      Pace.Log.Trace (Obj);
   end Inout;

   procedure Input (Obj : in Interaction) is
      Index : Integer := 1;

      procedure Get_Tuple (Param, Data : out C_Array; Length : out C.Size_T);
      pragma Convention (C, Get_Tuple);
      procedure Get_Tuple (Param, Data : out C_Array; Length : out C.Size_T) is
      begin
         Pace.Log.Put_Line ("===TX GT===" & Ada.Strings.Unbounded.To_String (Obj.Values (Index).Param) & Integer'Image(Index), 9);
         C.To_C (Ada.Strings.Unbounded.To_String (Obj.Values (Index).Param),
                 Param, Length);
         C.To_C (Ada.Strings.Unbounded.To_String (Obj.Values (Index).Data),
                 Data, Length, False);
         Index := Index + 1;
      end Get_Tuple;

      L : Pace.Semaphore.Lock (Hla.Connection'Access);

   begin
      if Started then
         if Obj.Update then
            Update_Attributes (C.To_C (Ada.Strings.Unbounded.To_String (Obj.Name)), 
                               Obj.Length, 
                               Obj.Handle,
                               Get_Tuple'Unrestricted_Access);
         else
            Send_Message (C.To_C (Ada.Strings.Unbounded.To_String (Obj.Name)), 
                          Obj.Length, 
                          Obj.Handle,
                          Get_Tuple'Unrestricted_Access);
         end if;
      end if;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Input;

   procedure Input (Obj : in Entity_State) is
      Msg : Interaction := Interaction(Obj);
   begin
      Msg.Update := True;
      Input (Msg);
   end;

   use Pace.Server.Dispatch;
begin
   Save_Action (Init_Outgoing'(Pace.Msg with Set => Default));
   -- $id: hla-tx.adb,v 1.6 12/08/2003 14:58:39 pukitepa Exp $
end Hla.Tx;
