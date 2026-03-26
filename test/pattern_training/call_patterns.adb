with Pace;
with Pace.Log;
with Pattern;
with Pace.Surrogates;
with Pace.Notify;

procedure Call_Patterns is
   package Proxy_S is new Pace.Surrogates.Asynchronous(Pattern.Proxy);
begin
   Pace.Dispatching.Set_Trace_Call (Pace.Log.Trace'Access);
   Pace.Log.Agent_Id;

   --Pattern.Agent.Ready; -- Synchronize start
   Pace.Log.Put_Line ("Starting Pattern Training Sequence");

   -- 1 Command Pattern
   declare
      Msg : Pattern.Command;
   begin
      Pace.Log.Put_Line ("1. Command Pattern " & Pace.Tag(Msg));
      Pattern.Input (Msg);
      Pattern.Inout (Msg);
      Pattern.Output (Msg);
   end;

   -- 1a Dispatching Command Pattern
   declare
      Msg : Pattern.Command;
   begin
      Pace.Log.Put_Line ("1a. Dispatching Command Pattern "  & Pace.Tag(Msg));
      Pace.Dispatching.Input (Msg);
      Pattern.Inout (Msg);
      Pattern.Output (Msg);
   end;

   -- 1b Task synchronized Command Pattern
   declare
      Msg : Pattern.Synch_Command;
   begin
      Pace.Log.Put_Line ("1b. Synchronized Message Passing Command Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;

   -- 1c Task asynchronous Command Pattern
   declare
      Msg : Pattern.Asynch_Command;
   begin
      Pace.Log.Put_Line ("1c. Asynchronous Message Passing Command Pattern "  & Pace.Tag(Msg));
      Pace.Surrogates.Input (Msg);
   end;


   -- 2 Pace.Msg_IO
   declare
      Msg : Pattern.Msg_IO;
   begin
      Msg.Data := 42;
      Pace.Log.Put_Line ("2. Msg_IO Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;

   -- 3 Pace.Notify.Subscription
   declare
      Msg : Pattern.Sub;
   begin
      Msg.Data := 100;
      Pace.Log.Put_Line ("3. Notify Subscription Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg); -- This publishes, agent is subscribing
   end;

   -- 4 Pace.Guarded.Queue
   declare
      Msg : Pattern.GC;
   begin
      Msg.Data := 200;
      Pace.Log.Put_Line ("4. Guarded Queue Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;

   -- 5 Pace.Signals.Event
   declare
      Msg : Pattern.Wakeup;
   begin
      Pace.Log.Put_Line ("5. Signals Event Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg); -- Signal the agent
   end;

   -- 6 Signals Multiple
   declare
      Msg : Pattern.Signal;
   begin
      Pace.Log.Put_Line ("6. Signals Multiple Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg); -- Signal S2
   end;

   -- 7 Signals Shared
   declare
      Msg : Pattern.Shared_Wakeup;
   begin
      Pace.Log.Put_Line ("7. Signals Shared Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;

   Pace.Log.Wait(0.1);

   -- 8 Pace.Signals.TID
   declare
      Msg : Pattern.Task_Wakeup;
   begin
      Pace.Log.Put_Line ("8. Signals TID Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;

   -- 9 Channel Pattern
   declare
      Msg : Pattern.Chan;
   begin
      Pace.Log.Put_Line ("9. Channel Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;

   -- 10 Buffered Command Pattern
   declare
      Msg : Pattern.Buffer;
   begin
      Msg.Char := 'A';
      Pace.Log.Put_Line ("10. Buffered Command Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;

   -- 11 Proxy (Socket) Pattern
   declare
      Msg : Pattern.Proxy;
   begin
      Msg.Data := 999;
      Pace.Log.Put_Line ("11. Proxy Pattern "  & Pace.Tag(Msg));
      Proxy_S.Surrogate.Input(Msg);
   end;

   -- 12 Pace.Socket.Publisher
   declare
      Msg : Pattern.My_Status;
   begin
      Pace.Log.Put_Line ("12. Socket Publisher Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Pattern.Status(Msg));
   end;

   -- 13 Callback Command Pattern
   declare
      CB : Pattern.Command;
      Msg : Pattern.CB;
   begin
      Pace.Log.Put_Line ("13. Callback Command Pattern "  & Pace.Tag(Msg));
      Msg.Callback := Pace.To_Callback(CB);
      Pattern.Input (Msg);
   end;

   -- 14 Persistent Command Pattern
   declare
      Msg : Pattern.Store;
   begin
      Pace.Log.Put_Line ("14. Pesistent Pattern "  & Pace.Tag(Msg));
      Pattern.Input (Msg);
   end;
   
   -- 99 Mesage Lookuo
--   declare
--      Msg : Pattern.Lookup_Msg;
--   begin
--      Pattern.Hash.Table.Set(Msg'Class'Tag, +Msg);
--      Pace.Log.Put_Line ("13. Hash Lookup Pattern "  & Pace.Tag(Msg));
--      Pace.Dispatching.Input (Pattern.Hash.Table.Get(Msg'Class'Tag);
--   end;


   Pace.Log.Put_Line ("Pattern Training Sequence Complete");
   Pace.Log.Wait(3.0);
   
   declare
      Msg : Pattern.CS;
      Regression : constant Integer := 1002341;
   begin
      Pattern.Output (Msg);
      Pace.Log.Put_Line("Checksum match" & Regression'Img  & Msg.N'Img);
      
      if Regression = Msg.N then
         Pace.Log.Os_Exit(0);
      else
         Pace.Log.Os_Exit(1);
      end if;
      
   end;
   
  
end Call_Patterns;

