with Pace.Queue;

package Pace.Signals.Buffers is
   -----------------------------------------
   -- BUFFERS -- Buffer as a guarded queue
   -----------------------------------------
   -- Uses Pace.Queue to create a buffer for multiple threads of control.
   -- This can be used as an async or synchronized ('in' or 'in out') Put.
   pragma Elaborate_Body;

   type Buffer is limited private;

   --
   --  Put does not block as default
   --
   procedure Put
     (Q     : in out Buffer;
      Obj   : in Pace.Msg'Class;
      Block : in Boolean := False);

   procedure Get
     (Q       : in out Buffer;
      Obj     : out Pace.Channel_Msg;
      Unblock : in Boolean := False);
   -- Channel_Msg is streamable

   function Get
     (Q       : access Buffer;
      Unblock : in Boolean := False)
      return    Pace.Msg'Class;

   function Is_Ready (Q : in Buffer) return Boolean;

   --
   -- Two-way Sync version: Blocking call on Put
   --
   procedure Put_And_Get (Q : in out Buffer; Obj : in out Pace.Msg'Class);

private
   package Queue is new Pace.Queue (Pace.Channel_Msg);

   protected type Buffer is
      procedure Put (Obj : in Pace.Channel_Msg);
      entry Get (Obj : out Pace.Channel_Msg);
      function Is_Ready return Boolean;
   private
      Ready  : Boolean := False;
      Buffer : Queue.Channel_Link;
   end Buffer;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-signals-buffers.ads,v 1.1 09/16/2002 18:18:48 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Signals.Buffers;
