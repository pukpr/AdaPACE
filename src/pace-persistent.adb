with Ada.Streams.Stream_Io;
with Pace.Log;
with Pace.Semaphore;

package body Pace.Persistent is

   M : aliased Pace.Semaphore.Mutex;

   procedure Put (Obj : in Msg'Class) is
      File : Ada.Streams.Stream_Io.File_Type;
      S : Ada.Streams.Stream_Io.Stream_Access;
      L : Pace.Semaphore.Lock (M'Access);
   begin
      Ada.Streams.Stream_Io.Create (File, Name => Pace.Tag (Obj));
      S := Ada.Streams.Stream_Io.Stream (File);
      Msg'Class'Output (S, Obj);
      Ada.Streams.Stream_Io.Close (File);
   exception
      when E : others =>
         Pace.Log.Ex (E);
         raise;
   end Put;
   
   procedure Get (Obj : in out Msg'Class) is
      File : Ada.Streams.Stream_Io.File_Type;
      S : Ada.Streams.Stream_Io.Stream_Access;
      L : Pace.Semaphore.Lock (M'Access);
   begin
      Ada.Streams.Stream_Io.Open
         (File, Ada.Streams.Stream_Io.In_File, Pace.Tag (Obj));
      S := Ada.Streams.Stream_Io.Stream (File);
      Obj := Msg'Class'Input (S);
      Ada.Streams.Stream_Io.Close (File);
   exception
      when E : others =>
         Pace.Log.Ex (E, Pace.Tag (Obj) & " defaulted to in value");
   end Get;

------------------------------------------------------------------------------
-- $id: pace-persistent.adb,v 1.1 09/16/2002 18:18:31 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Persistent;
