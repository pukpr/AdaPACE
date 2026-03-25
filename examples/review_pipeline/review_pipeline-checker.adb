with Pace.Log;

package body Review_Pipeline.Checker is

   --  let checker : !string -> !Verdict = agent { ... }
   --
   --  Receives a Draft and produces either:
   --    verdict = false  ->  map({verdict, commentary}) ; composer
   --    verdict = true   ->  critic
   --
   --  Simulation: iteration 0 is rejected (too brief); iteration >= 1 passes.

   function Id is new Pace.Log.Unit_Id;

   task Agent is
      entry Handle (Obj : in Review_Pipeline.Draft);
   end Agent;

   task body Agent is
      D : Review_Pipeline.Draft;
   begin
      Pace.Log.Agent_Id (Id);
      loop
         --  Short rendezvous: copy message only, do work outside.
         accept Handle (Obj : in Review_Pipeline.Draft) do
            D := Obj;
         end Handle;

         declare
            Iter    : constant Natural  := D.Iteration;
            --  Simulate: reject iteration 0, pass iteration >= 1
            Passed  : constant Boolean  := Iter >= 1;
            Comment : constant String   :=
               (if Passed
                then "Draft is clear and well-structured."
                else "Draft is too brief. Expand with detail and examples.");
         begin
            Pace.Log.Put_Line
               ("Checker [iter" & Natural'Image (Iter) &
                "]: verdict=" & Boolean'Image (Passed) &
                ", commentary: " & Comment);

            if not Passed then
               --  filter(verdict = false) ; map({verdict, commentary}) ; composer
               declare
                  Req : Review_Pipeline.Request;
               begin
                  Req.Prompt    := +("Revise per commentary: " & Comment &
                                     "  Previous draft: " & (-D.Text));
                  Req.Iteration := Iter + 1;
                  Pace.Dispatching.Input (Req);
               end;
            else
               --  filter(verdict = true) ; critic
               declare
                  V : Review_Pipeline.Verdict;
               begin
                  V.Passed     := True;
                  V.Commentary := +Comment;
                  V.Draft_Text := D.Text;
                  V.Iteration  := Iter;
                  Pace.Dispatching.Input (V);
               end;
            end if;
         end;
      end loop;
   exception
      when E : others => Pace.Log.Ex (E);
   end Agent;

   procedure Handle (Obj : in Review_Pipeline.Draft) is
   begin
      Agent.Handle (Obj);
   end Handle;

end Review_Pipeline.Checker;
