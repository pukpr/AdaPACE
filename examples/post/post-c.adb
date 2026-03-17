with Post.A;
with Pace.Log;

package body Post.C is

   -- Test app for post-processing utils

   function Id is new Pace.Log.Unit_Id;

   task Agent is
      entry Input (Obj : in Start);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         accept Input (Obj : in Start) do
            Pace.Log.Wait (1.0);
            Pace.Log.Trace (Obj);
         end Input;
         Pace.Dispatching.Input (First'(Pace.Msg with null record));
         Pace.Dispatching.Input (Op'(Pace.Msg with null record));
      end loop;
   exception
      when E : others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Start) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in First) is
   begin
      Pace.Log.Wait (1.0);
      Pace.Dispatching.Input (Second'(Pace.Msg with null record));
   end Input;

   procedure Input (Obj : in Second) is
   begin
      Pace.Log.Wait (1.0);
      Pace.Dispatching.Input (Third'(Pace.Msg with null record));
   end Input;

   procedure Input (Obj : in Third) is
   begin
      Pace.Log.Wait (1.0);
      Pace.Dispatching.Input (Fourth'(Pace.Msg with null record));
   end Input;

   procedure Input (Obj : in Fourth) is
   begin
      Pace.Log.Wait (1.0);
      Pace.Dispatching.Input (Post.A.Start'(Pace.Msg with null record));
   end Input;

   procedure Input (Obj : in Op) is
   begin
      Pace.Log.Wait (3.0);
   end Input;

end Post.C;
