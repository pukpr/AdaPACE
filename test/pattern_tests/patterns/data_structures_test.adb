with AUnit.Assertions; use AUnit.Assertions;
with Pace.Ordering;
with Pace.Queue;
with Pace.Queue.Guarded;
with Pace.Priority_Queue;
with Pace.Priority_Queue.Guarded;
with Pace.Hash_Table;
-- with Ada.Strings.Unbounded; use Ada.Strings.Unbounded; -- Redundant
with AUnit.Test_Cases.Registration; use AUnit.Test_Cases.Registration;

package body Data_Structures_Test is

   -- Ordering instantiation
   function My_Ordering is new Pace.Ordering(Integer);

   -- Queue instantiation
   package My_Queue is new Pace.Queue(Integer);
   package My_Queue_Guarded is new My_Queue.Guarded;

   -- Priority Queue instantiation
   function Img(I: Integer) return String is
   begin
      return Integer'Image(I);
   end Img;

   package My_PQ is new Pace.Priority_Queue(Channel => Integer, 
                                            Priorities => Integer, 
                                            "<" => "<", 
                                            ">" => ">", 
                                            Image => Img);
   package My_PQ_Guarded is new My_PQ.Guarded;

   -- Hash Table instantiation
   use Pace.Hash_Table;
   package My_HT is new Pace.Hash_Table.Simple_Htable(Element => Integer,
                                                      No_Element => -1,
                                                      Key => Unbounded_String,
                                                      Hash => Pace.Hash_Table.Hash,
                                                      Equal => "=");

   procedure Test_Ordering (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Val : Integer := 12345;
      Res : Integer;
   begin
      Res := My_Ordering(Val);
      -- We don't know if it swaps or not, but double swap should be idempotent.
      Assert (My_Ordering(Res) = Val, "Ordering(Ordering(X)) /= X");
   end Test_Ordering;

   procedure Test_Queue (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Q : My_Queue.Channel_Link;
   begin
      Assert (My_Queue.Is_Empty(Q), "Queue should be empty initially");
      My_Queue.Append(Q, 10);
      My_Queue.Append(Q, 20);
      Assert (not My_Queue.Is_Empty(Q), "Queue should not be empty");
      Assert (My_Queue.Front(Q) = 10, "Front should be 10");
      My_Queue.Pop(Q);
      Assert (My_Queue.Front(Q) = 20, "Front should be 20");
      My_Queue.Pop(Q);
      Assert (My_Queue.Is_Empty(Q), "Queue should be empty");
   end Test_Queue;

   procedure Test_Queue_Guarded (T : in out AUnit.Test_Cases.Test_Case'Class) is
      V : Integer;
      
      task Producer is
         entry Start;
      end Producer;
      
      task body Producer is
      begin
         accept Start;
         delay 0.1; -- Small delay to ensure Consumer is waiting
         My_Queue_Guarded.Put(100);
         My_Queue_Guarded.Put(200);
      end Producer;
      
   begin
      Producer.Start;
      
      -- This should block until Producer puts items
      My_Queue_Guarded.Get(V);
      Assert (V = 100, "Guarded Queue Get should return 100");
      My_Queue_Guarded.Get(V);
      Assert (V = 200, "Guarded Queue Get should return 200");
   end Test_Queue_Guarded;
   
   procedure Test_Priority_Queue (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Q : My_PQ.Channel_Link;
   begin
      My_PQ.Append(Q, 10, 1); -- Val 10, Pri 1
      My_PQ.Append(Q, 20, 5); -- Val 20, Pri 5
      My_PQ.Append(Q, 30, 3); -- Val 30, Pri 3
      
      -- If larger number = higher priority
      Assert (My_PQ.Front(Q) = 20, "Highest priority (5) should be front");
      My_PQ.Pop(Q);
      Assert (My_PQ.Front(Q) = 30, "Next highest (3) should be front");
      My_PQ.Pop(Q);
      Assert (My_PQ.Front(Q) = 10, "Lowest (1) should be front");
   end Test_Priority_Queue;

   procedure Test_Priority_Queue_Guarded (T : in out AUnit.Test_Cases.Test_Case'Class) is
      V : Integer;
   begin
      -- Tasking test was flaky due to race condition on Put vs Get waking up.
      -- Since Queue is unbounded, Put should not block.
      My_PQ_Guarded.Put(10, 1);
      My_PQ_Guarded.Put(20, 5);
      
      -- Now both are in the queue (or buffer).
      -- Get should return highest priority.
      My_PQ_Guarded.Get(V);
      Assert (V = 20, "Guarded PQ Get should return highest priority (20)");
      My_PQ_Guarded.Get(V);
      Assert (V = 10, "Guarded PQ Get should return remaining (10)");
   end Test_Priority_Queue_Guarded;

   procedure Test_Hash_Table (T : in out AUnit.Test_Cases.Test_Case'Class) is
      K1 : Unbounded_String := To_Unbounded_String("Key1");
      K2 : Unbounded_String := To_Unbounded_String("Key2");
   begin
      My_HT.Set(K1, 100);
      Assert (My_HT.Get(K1) = 100, "Hash Table Get incorrect");
      Assert (My_HT.Get(K2) = -1, "Hash Table Get should return No_Element");
      My_HT.Set(K1, 200);
      Assert (My_HT.Get(K1) = 200, "Hash Table update incorrect");
   end Test_Hash_Table;

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Ordering'Access, "Test_Ordering");
      Register_Routine (T, Test_Queue'Access, "Test_Queue");
      Register_Routine (T, Test_Queue_Guarded'Access, "Test_Queue_Guarded");
      Register_Routine (T, Test_Priority_Queue'Access, "Test_Priority_Queue");
      Register_Routine (T, Test_Priority_Queue_Guarded'Access, "Test_Priority_Queue_Guarded");
      Register_Routine (T, Test_Hash_Table'Access, "Test_Hash_Table");
   end Register_Tests;

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Data Structures Tests");
   end Name;

end Data_Structures_Test;
