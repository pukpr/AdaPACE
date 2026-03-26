with Pace;
with Pace.Notify;

package Pattern is
   pragma Elaborate_Body;

   -- 1 Command Pattern
   type Command is new Pace.Msg with null record;
   procedure Input (Obj : in     Command);
   procedure Inout (Obj : in out Command);
   procedure Output(Obj :    out Command);

   -- 1b Synchronizes Message Passing Command Pattern
   type Synch_Command is new Pace.Msg with null record;
   procedure Input (Obj : in Synch_Command);

   -- 1c Asynchronous Message Passing Command Pattern
   type Asynch_Command is new Pace.Msg with null record;
   procedure Input (Obj : in Asynch_Command);

   -- 2  Pace.Msg_IO
   type Msg_IO is new Pace.Msg with 
     record
         Data : Integer;
     end record;
   procedure Input (Obj : in     Msg_IO);
   procedure Output(Obj :    out Msg_IO);
   
   -- 3  Pace.Notify.Subscription
   type Sub is new Pace.Notify.Subscription with 
     record
         Data : Integer;
     end record;
   procedure Input (Obj : in     Sub);
   procedure Inout (Obj : in out Sub);

   -- 4  Pace.Guarded.Queue
   type GC is new Pace.Msg with 
     record
         Data : Integer;
     end record;
   procedure Input (Obj : in     GC);
   procedure Output(Obj :    out GC);

   -- 5  Pace.Signals.Event
   type Suspend is new Pace.Msg with null record;
   procedure Input (Obj : in Suspend);
   type Wakeup is new Pace.Msg with null record;
   procedure Input (Obj : in Wakeup);
     
   -- 6  Pace.Signals.Multiple
   type Await is new Pace.Msg with null record;
   procedure Input (Obj : in Await);
   type Signal is new Pace.Msg with null record;
   procedure Input (Obj : in Signal);
   
   -- 7  Pace.Signals.Shared
   type Shared_Wakeup is new Pace.Msg with null record;
   procedure Input (Obj : in     Shared_Wakeup);
   procedure Inout (Obj : in out Shared_Wakeup);
   
   -- 8 Pace.Signals.TID
   type Task_Wakeup is new Pace.Msg with null record;
   procedure Input (Obj : in  Task_Wakeup);

   -- 9 Channel Pattern
   type Chan is new Pace.Msg with null record;
   procedure Input (Obj : in  Chan);
   
   -- 10 Buffered Command Pattern
   type Buffer is new Pace.Msg with 
     record
         Char : Character;
      end record;
   procedure Input (Obj : in Buffer);
   
   -- 11 Surrogate (Asynchronus) Pattern
   type Proxy is new Pace.Msg with 
     record
         Data : Integer;
     end record;
   procedure Input (Obj : in Proxy);

   -- 12  Publish-Subscribe
   type Status is new Pace.Msg with 
     record
         Data : Integer;
     end record;
   procedure Input (Obj : in Status);
   
   type My_Status is new Status with null record;
   procedure Input (Obj : in My_Status);
   

   -- 13  Callback Command Pattern
   type CB is new Pace.Msg with 
     record
         Callback : Pace.Channel_Msg;
     end record;
   procedure Input (Obj : in CB);

   -- 14  Persistent Command Pattern
   type Store is new Pace.Msg with null record;
   procedure Input (Obj : in Store);

   -- 99  Message Lookup(Hash table)
   --package Hash is new Pace.Lookup(479);
   --type Lookup_Msg is new Pace.Msh with null record;
   --procedure Input (Obj : in Lookup_Msg);

   -- 100 Quit
   type Quitter is new Pace.Msg with null record;
   procedure Input (Obj : in Quitter);


end Pattern;
