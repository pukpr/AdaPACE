with Pace.Log;
with Ada.Tags;
with Pace.Queue.Guarded;

package body Pace.Surrogates is

   type Surrogate_Range is new Positive;
   Max_Surrogates : constant Surrogate_Range :=
     Surrogate_Range (Pace.Getenv ("PACE_MAX_SURROGATES", 30));

   task type Surrogate (Id : Surrogate_Range) is
      -- pragma Storage_Size ();
   end Surrogate;

   type Surrogate_Access is access Surrogate;

   type Surrogate_Vector is
      array (Surrogate_Range range <>) of Surrogate_Access;

   package Q is new Pace.Queue (Pace.Channel_Msg, Fifo => True);
   package Guarded_Q is new Q.Guarded;

   task body Surrogate is
      Msg : Pace.Channel_Msg;
   begin
      Pace.Log.Agent_ID ("(PACE.SURROGATE.POOL)");
      loop
         Guarded_Q.Get (Msg);
         declare
            Local : Pace.Msg'Class := Pace.To_Msg (Msg);
         begin
            Pace.Log.Agent_ID ("(" & Pace.Tag (Local) & ")");
            Local.Send := Async;
            --Pace.Input (Local);
            Pace.Dispatching.Input (Local);
         exception
            when E: others =>
               Pace.Log.Ex (E, "In surrogate task for " & Pace.Tag (Local));
         end;
         Finalize (Msg);
      end loop;
   end Surrogate;

   SR : Surrogate_Range := Surrogate_Range'First;
   function Id return Surrogate_Range is
   begin
      SR := SR + 1;
      return SR - 1;
   end;

   Surrogates : Surrogate_Vector (1 .. Max_Surrogates) := (others => new Surrogate (Id));

   procedure Input (Obj : in Msg'Class) is
   begin
      Guarded_Q.Put (To_Channel_Msg(Obj));
   end Input;


   package body Asynchronous is

      -- procedure Input_Redispatch (Obj : in Async_Msg) renames Input;

      task body Surrogate is
         Local : Async_Msg;
      begin
         -- Surrogate task agents have parentheses around their name and
         -- are identified by their dispatching message.
         --
         Pace.Log.Agent_ID ("(" & Ada.Tags.External_Tag (Async_Msg'Tag) & ")");
         loop
            select
               accept Input (Obj : in Async_Msg) do
                  Local := Obj;
               end Input;
               Set_Async (Local);
               --Local.Send := Pace.Async;
               -- Input_Redispatch (Local);
               Pace.Dispatching.Input (Local);
            or
               terminate;
            end select;
         end loop;
      exception
         when E: others =>
            Pace.Log.Ex (E, "inside asynchronous surrogate");
      end Surrogate;

   end Asynchronous;

   ------------------------------------------------------------------------------
   -- $id: pace-surrogates.adb,v 1.1 09/16/2002 18:18:56 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Surrogates;
