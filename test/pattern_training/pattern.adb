with Pace.Log;
with Pace.Msg_Io;
with Pace.Notify;
with Pace.Queue;
with Pace.Queue.Guarded;
with Pace.Signals;
with Pace.Signals.Tid;
with Pace.Signals.Buffers;
with Pace.Surrogates;
with Pace.Socket.Publisher;
with Ada.Tags;
with Pace.Persistent;
with Pace.Semaphore;

package body Pattern is

   Checksum : Integer := 0;
   M : aliased Pace.Semaphore.Mutex;
   
   procedure Add_To_Checksum(N : Integer) is
      use Pace.Semaphore;
      L : Lock(M'Access);
   begin
     Checksum := Checksum + N;
   end Add_To_Checksum;
  

   -- Agent Task for training purposes
   task Agent is 
      pragma Task_Name ("Pattern_Agent");
      -- 1b Synchronizes Message Passing Command Pattern
      entry Input (Obj : in Synch_Command);
      -- entry Quit;
   end Agent;



   -- 2 Msg_IO instance
   type Connection_Range is range 1 .. 10;
   package M_IO is new Pace.Msg_Io (Connections => Connection_Range);

   -- 4 Guarded Queue instance
   package Q_Parent is new Pace.Queue (Pace.Channel_Msg);
   package Q is new Q_Parent.Guarded;

   -- 5 Signals Event
   Ev : Pace.Signals.Event;

   -- 6 Signals Multiple
   type Sig_Enum is (S1, S2);
   package M_Sig is new Pace.Signals.Multiple (Sig_Enum);

   -- 7 Signals Shared
   Shared_Obj : aliased Shared_Wakeup;
   Shared : Pace.Signals.Shared_Data (Shared_Obj'Access);

   -- 8 Pace.Signals.TID
   Task_ID : Pace.Thread;
   
   -- 10 Buffered Command
   B_Queue : Pace.Signals.Buffers.Buffer;

   -- 12 Publish-Subscribe
   List : Pace.Socket.Publisher.Subscription_List(10);
   
   task body Agent is
      use type Ada.Tags.Tag;
      Local_Status : Status;
   begin
      Pace.Log.Agent_Id ("Pattern_Agent");
      Task_ID := Pace.Current;
      
      accept Input (Obj : in Synch_Command);
      Pace.Log.Put_Line ("Agent Ready");

      loop
         -- 2 Msg_IO
         declare
            Msg : Msg_IO;
            Recv : Boolean;
         begin
            M_IO.Await (Msg, Recv, Wait => True);
            Add_To_Checksum(Msg.Data);
            Pace.Log.Put_Line ("Agent received Msg_IO: " & Integer'Image(Msg.Data));
         end;

         -- 3 Notify Subscription
         declare
            S : Sub;
         begin
            Pace.Notify.Subscribe (S);
            Add_To_Checksum(S.Data);
            Pace.Log.Put_Line ("Agent subscribed to Sub: " & Integer'Image(S.Data));
         end;

         -- 4 Guarded Queue
         declare
            C_Msg : Pace.Channel_Msg;
         begin
            Q.Get (C_Msg);
            declare
               Msg : GC := GC(Pace.To_Msg(C_Msg));
            begin
               Add_To_Checksum(Msg.Data);
               Pace.Log.Put_Line ("Agent got from Queue: " & Integer'Image(Msg.Data));
            end;
         end;

         -- 5 Signals Event
         Pace.Log.Put_Line ("Agent suspending on Event...");
         Ev.Suspend;
         Pace.Log.Put_Line ("Agent resumed from Event.");

         -- 6 Signals Multiple
         Pace.Log.Put_Line ("Agent awaiting Signal S2...");
         M_Sig.Await (S2);
         Pace.Log.Put_Line ("Agent received Signal S2.");

         -- 7 Signals Shared
         declare
            Msg : Shared_Wakeup;
         begin
            Shared.Read (Msg);
            Pace.Log.Put_Line ("Agent read from Shared.");
         end;

         -- 8 Signals TID
         Pace.Log.Put_Line ("Agent waiting on TID...");
         Pace.Signals.Tid.Wait;
         Pace.Log.Put_Line ("Agent resumed on TID.");

         -- 9 Channel
         declare
            Msg : Chan;
            Recv : Boolean;
         begin
            M_IO.Await (Msg, Recv, Wait => True);
            Pace.Log.Put_Line ("Agent received Chan Msg.");
         end;

         -- 10 Buffered Command
         declare
            C_Msg : Pace.Channel_Msg;
         begin
            Pace.Signals.Buffers.Get (B_Queue, C_Msg);
            declare
               Msg : Pattern.Buffer := Pattern.Buffer(Pace.To_Msg(C_Msg));
            begin
               Pace.Log.Put_Line ("Agent got from Buffer: " & Msg.Char);
            end;
         end;
         
         Pace.Log.Wait(2.0);
         
         --12 Publish-Subscribe
         Local_Status.Data := 1_000_000;
         Pace.Socket.Publisher.Publish(List, Local_Status);
         
         Local_Status.Data := 1_000;
         Pace.Socket.Publisher.Publish(List, Local_Status);

         Pace.Log.Put_Line ("Agent cycle complete.");
         --exit;
      end loop;
   exception
      when E : others =>
         Pace.Log.Ex (E);
   end Agent;

   -- 1 Command Pattern
   procedure Input (Obj : in Command) is
   begin
      Pace.Log.Put_Line ("Input Command");
   end;
   procedure Inout (Obj : in out Command) is
   begin
      Pace.Log.Put_Line ("Inout Command");
   end;
   procedure Output(Obj : out Command) is
   begin
      Pace.Log.Put_Line ("Output Command");
   end;

   -- 1b Synchronizes Message Passing Command Pattern
   procedure Input (Obj : in Synch_Command) is
   begin
      Pace.Log.Put_Line ("Input Synch Command");
      Agent.Input(Obj);
      Pace.Log.Put_Line ("Input Synched");
   end;

   -- 1c Asynchronous Message Passing Command Pattern
   procedure Input (Obj : in Asynch_Command) is
   begin
      Pace.Log.Put_Line ("Input Asynch Command");
   end;

   -- 2 Msg_IO
   procedure Input (Obj : in Msg_IO) is
   begin
      M_IO.Send (Obj);
   end;
   procedure Output(Obj : out Msg_IO) is
   begin
      null;
   end;

   -- 3 Pace.Notify.Subscription
   procedure Input (Obj : in Sub) is
   begin
      Pace.Notify.Publish (Obj);
   end;
   procedure Inout (Obj : in out Sub) is
   begin
      Pace.Notify.Subscribe (Obj);
   end;

   -- 4 Pace.Guarded.Queue
   procedure Input (Obj : in GC) is
   begin
      Q.Put (Pace.To_Channel_Msg(Obj));
   end;
   procedure Output (Obj : out GC) is
   begin
      null;
   end;

   -- 5 Pace.Signals.Event
   procedure Input (Obj : in Suspend) is
   begin
      Ev.Suspend;
   end;
   procedure Input (Obj : in Wakeup) is
   begin
      while not Ev.Waiting loop
         delay 0.1;
      end loop;
      Ev.Signal;
   end;

   -- 6 Pace.Signals.Multiple
   procedure Input (Obj : in Await) is
   begin
      M_Sig.Await (S1);
   end;
   procedure Input (Obj : in Signal) is
   begin
      M_Sig.Signal (S2);
   end;

   -- 7 Pace.Signals.Shared
   procedure Input (Obj : in Shared_Wakeup) is
   begin
      Shared.Write (Obj);
   end;
   procedure Inout (Obj : in out Shared_Wakeup) is
   begin
      Shared.Read (Obj);
   end;

   -- 8 Pace.Signals.TID
   procedure Input (Obj : in Task_Wakeup) is
   begin
      Pace.Signals.TID.Signal(Task_ID);
   end;

   -- 9 Channel Pattern
   procedure Input (Obj : in Chan) is
   begin
      M_IO.Send (Obj);
   end;

   -- 10 Buffered Command Pattern
   procedure Input (Obj : in Pattern.Buffer) is
   begin
      Pace.Signals.Buffers.Put (B_Queue, Obj);
   end;

   -- 11 Surrogate (Asynchronus) Pattern
   procedure Input (Obj : in Proxy) is
   begin
      Add_To_Checksum(Obj.Data);
      Pace.Log.Put_Line ("Surrogate Input: " & Integer'Image(Obj.Data));
   end;

   -- 12 Publish-Subscribe
   procedure Input (Obj : in Status) is
   begin
      Pace.Socket.Publisher.Subscribe(List, Obj);
      Pace.Log.Put_Line ("PubSub Subscribe " & Pace.Tag(Obj) );
   end;

   procedure Input (Obj : in My_Status) is
   begin
      Add_To_Checksum(Obj.Data);
      Pace.Log.Put_Line ("PubSub Received a pub " & Integer'Image(Obj.Data) );
   end;


   -- 13  Callback Command Pattern
   procedure Input (Obj : in CB) is
      use type Pace.Channel_Msg;
   begin
      Pace.Dispatching.Input(+Obj.Callback);
      Pace.Log.Put_Line ("Callback Command complete");
   end;

   -- 14  Persistent Command Pattern
   procedure Input (Obj : in Store) is
      Copy : Store;
   begin
      Pace.Persistent.Put(Obj);
      Pace.Persistent.Get(Copy);
      Pace.Log.Put_Line ("Stored " & Pace.Tag(Copy) );
   end;

   --procedure Input (Obj : in Lookup_Msg) is
   --begin
   --   Pace.Log.Put_Line ("Looked-up  Msg");
   --end;
   


   -- 100 CS
   procedure Output (Obj : out CS) is
   begin
      Obj.N := Checksum;
      Pace.Log.Put_Line ("CS");
   end;


end Pattern;
