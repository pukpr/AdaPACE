with Pace.Server.Dispatch;
with Text_Io;
with Pace.Notify;
with GNAT.Expect;
with System;
with Ada.Strings.Fixed;
with Pace.Semaphore;
with Pace.Log.System;
with Pace.Signals;
with Pace.Ses.Launch;

package body Pace.Ses.Pipe_Server is

   type P4_Is_Ready is new Pace.Notify.Subscription with null record;

   use GNAT.Expect;
   Process : Process_Descriptor;
   Result : Expect_Match;
   Status : Integer;

   Web : Boolean := False;
   
   M : aliased Pace.Semaphore.Mutex;
   
   procedure Output_Filter 
      (Descriptor : Process_Descriptor'Class;
       Str        : String;
       User_Data  : System.Address) is
   begin
      if Web then
         Text_Io.Put (Text_Io.Standard_Error, Str);
         Pace.Server.Put_Data (Str);
      else
         Text_Io.Put (Str);
      end if;
   end;

   procedure P4_Wakeup is
      Msg : P4_Is_Ready;
   begin -- don't want to block
      Msg.Ack := False;
      Input (Msg);
   end;

   procedure Set_Web is
   begin
      Pace.Ses.Launch.Register_Startup_Callback (P4_Wakeup'Access);
   end;


   procedure Set_Pipe (Exec, Args : in String) is
   begin
      Non_Blocking_Spawn   
       (Process, Exec, Pace.Log.System.Make_List(Args), Err_To_Out => True);
      Add_Filter (Process, Output_Filter'Access, Output);
 
      loop
         Expect (Process, Result, "All groups released");
         exit when Result /= Expect_Timeout;
      end loop;

      P4_Wakeup;

      loop
         declare
            L : Pace.Semaphore.Lock (M'Access);
         begin
            Expect (Process, Result, ".+"); -- Add a shorter timeout, default=10s
         end;
      end loop;

   exception
      when Process_Died =>
         Text_Io.Put_Line (Text_Io.Standard_Error,
                           "Session closed ... exiting");
         Close (Process, Status);
   end Set_Pipe;

   procedure Close_Pipe is
   begin
      Close (Process, Status);
   end Close_Pipe;


   type Wait_For_P4_Is_Ready is new
     Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Wait_For_P4_Is_Ready);
   procedure Inout (Obj : in out Wait_For_P4_Is_Ready) is
   begin
      declare
         Msg : P4_Is_Ready;
      begin
         Inout (Msg);
      end;
   end Inout;


   type Pp is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Pp);
   for Pp'External_Tag use "PP";


   procedure Inout (Obj : in out Pp) is
      Action : constant String := Pace.Server.Value ("");
   begin
      Pace.Server.Put_Content ("text/plain");
      Pace.Ses.Launch.Post (Action);
      Pace.Server.Put_Data ("PP action sent: " & Action);
   end Inout;

--    procedure Inout (Obj : in out Pp) is
--       L : Pace.Semaphore.Lock (M'Access);
--    begin
--       Send (Process, Pace.Server.Value (""));
--       Pace.Server.Put_Content ("text/plain");
--       Web := True;
--       Expect (Process, Result, Ses.Output_Marker);
--       Web := False;
--    exception
--       when Process_Died =>
--          Close_Pipe;
--          Text_Io.Put_Line (Text_Io.Standard_Error,
--                            "Session closed during action request ... exiting");
--          Ses.Os_Exit (0);
--    end Inout;

   use Pace.Server.Dispatch;

begin
   Save_Action (Pp'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   Save_Action (Wait_For_P4_Is_Ready'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
end Pace.Ses.Pipe_Server;
