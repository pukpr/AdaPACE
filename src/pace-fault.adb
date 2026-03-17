with Pace.Queue.Guarded;
with Pace.Socket;
with Ada.Strings.Fixed;
with Ada.Exceptions;

package body Pace.Fault is

   package Q is new Pace.Queue (ID);
   package Q_Fault is new Q.Guarded;

   procedure Input (Obj : in ID) is
   begin
      Pace.Display
        ("*** LOGGING Fault as " &
         Ada.Strings.Unbounded.To_String (Obj.Name));
      Q_Fault.Put (Obj);
   end Input;

   procedure Output (Obj : out ID) is
   begin
      Q_Fault.Get (Obj);
   end Output;

   procedure Send (Name : in String; Instance : in Integer := 1) is
      Msg : ID;
   begin
      Msg.Name     := To_Name (Name);
      Msg.Instance := Instance;
      Pace.Socket.Send (Msg);
   end Send;

   procedure Report (Instance : in Integer := 1) is
      E : exception;
      S : constant String := Ada.Exceptions.Exception_Name (E'Identity);
      P : Integer         := S'Last;
   begin
      for I in  1 .. 2 loop
         P :=
           Ada.Strings.Fixed.Index (S (1 .. P), ".", Ada.Strings.Backward) -
           1;
      end loop;
      P := Ada.Strings.Fixed.Index (S (1 .. P), "GP", Ada.Strings.Backward) -
           1;
      Send (S (1 .. P), Instance);
   end Report;

   ----------------------------------------------------------------------------
   ----
   -- $id: pace-fault.adb,v 1.1 09/16/2002 18:18:24 pukitepa Exp $
   ----------------------------------------------------------------------------
   ----
end Pace.Fault;
