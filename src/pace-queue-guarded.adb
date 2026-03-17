package body Pace.Queue.Guarded is

   protected Shared is
      procedure Put (Obj : in Channel);
      entry Get (Obj : out Channel);
      function Is_Ready return Boolean;
   private
      Ready : Boolean := False;
      Buffer : Channel_Link;
   end Shared;

   protected body Shared is
      procedure Put (Obj : in Channel) is
      begin
         Append (Buffer, Obj);
         Ready := True;
      end Put;

      entry Get (Obj : out Channel) when Ready is
      begin
         Obj := Front (Buffer);
         Pop (Buffer);
         Ready := not Is_Empty (Buffer);
      end Get;

      function Is_Ready return Boolean is
      begin
         return not Is_Empty (Buffer);
      end Is_Ready;
   end Shared;

   procedure Put (Obj : in Channel) is
   begin
      Shared.Put (Obj);
   end Put;

   procedure Get (Obj : out Channel) is
   begin
      Shared.Get (Obj);
   end Get;

   function Is_Ready return Boolean is
   begin
      return Shared.Is_Ready;
   end Is_Ready;

   ------------------------------------------------------------------------------
   -- $id: pace-queue-guarded.adb,v 1.1 09/16/2002 18:18:34 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Queue.Guarded;

