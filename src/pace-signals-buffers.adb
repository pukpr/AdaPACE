with Pace.Signals.Tid;

package body Pace.Signals.Buffers is

   protected body Buffer is
      procedure Put (Obj : in Pace.Channel_Msg) is
      begin
         Queue.Append (Buffer, Obj);
         Ready := True;
      end Put;

      entry Get (Obj : out Pace.Channel_Msg) when Ready is
      begin
         Obj := Queue.Front (Buffer);
         Queue.Pop (Buffer);
         Ready := not Queue.Is_Empty (Buffer);
      end Get;

      function Is_Ready return Boolean is
      begin
         return not Queue.Is_Empty (Buffer);
      end Is_Ready;
   end Buffer;

   procedure Put
     (Q     : in out Buffer;
      Obj   : in Pace.Msg'Class;
      Block : Boolean := False)
   is
      Ch : Pace.Channel_Msg := Pace.To_Channel_Msg (Obj);
   begin
      Q.Put (Ch);
      if Block then
         Pace.Signals.Tid.Wait; -- waits on current Task_ID
      end if;
   end Put;

   procedure Put_And_Get (Q : in out Buffer; Obj : in out Pace.Msg'Class) is
      Ch : Pace.Channel_Msg;
   begin
      Put (Q, Obj, Block => True);
      Get (Q, Ch, Unblock => True);
      Obj := Pace.To_Msg (Ch);
   end Put_And_Get;

   procedure Get
     (Q       : in out Buffer;
      Obj     : out Pace.Channel_Msg;
      Unblock : in Boolean := False)
   is
   begin
      Q.Get (Obj);
      if Unblock then -- signals waiting Task_ID
         Pace.Signals.Tid.Signal (Pace.To_Msg (Obj).Id);
      end if;
   end Get;

   function Get
     (Q       : access Buffer;
      Unblock : in Boolean := False)
      return    Pace.Msg'Class
   is
      Ch : Pace.Channel_Msg;
   begin
      Q.Get (Ch);
      declare
         Obj : Pace.Msg'Class := Pace.To_Msg (Ch);
      begin
         if Unblock then -- signals waiting Task_ID
            Pace.Signals.Tid.Signal (Obj.Id);
            Obj.Send := Pace.Sync;
         else
            Obj.Send := Pace.Async;
         end if;
         return Obj;
      end;
   end Get;

   function Is_Ready (Q : in Buffer) return Boolean is
   begin
      return Q.Is_Ready;
   end Is_Ready;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-signals-buffers.adb,v 1.1 09/16/2002 18:18:47 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Signals.Buffers;
