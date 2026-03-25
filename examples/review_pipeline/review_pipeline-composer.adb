with Pace.Log;

package body Review_Pipeline.Composer is

   --  let composer : !string -> !string = agent { ... }
   --
   --  Receives a Request (original prompt or revision feedback) and produces
   --  a Draft, which is forwarded to the Checker via local dispatch.
   --
   --  Simulation: each iteration the draft grows richer, reflecting the
   --  commentary / review feedback carried in the prompt.

   function Id is new Pace.Log.Unit_Id;

   task Agent is
      entry Handle (Obj : in Review_Pipeline.Request);
   end Agent;

   task body Agent is
      Req : Review_Pipeline.Request;
   begin
      Pace.Log.Agent_Id (Id);
      loop
         --  Short rendezvous: copy message only, do work outside.
         accept Handle (Obj : in Review_Pipeline.Request) do
            Req := Obj;
         end Handle;

         declare
            Iter  : constant Natural := Req.Iteration;
            Desc  : constant String  := -Req.Prompt;
            Extra : constant String  :=
               (if Iter >= 1 then " [Detail expanded per commentary.]"  else "") &
               (if Iter >= 2 then " [Examples and structure added per review.]" else "");
            D : Review_Pipeline.Draft;
         begin
            Pace.Log.Put_Line
               ("Composer [iter" & Natural'Image (Iter) &
                "]: composing draft for: " & Desc);
            D.Text      := +("Draft v" & Natural'Image (Iter) &
                              ": " & Desc & Extra);
            D.Iteration := Iter;

            --  filter/route: input ; composer ; checker
            Pace.Dispatching.Input (D);
         end;
      end loop;
   exception
      when E : others => Pace.Log.Ex (E);
   end Agent;

   procedure Handle (Obj : in Review_Pipeline.Request) is
   begin
      Agent.Handle (Obj);
   end Handle;

end Review_Pipeline.Composer;
