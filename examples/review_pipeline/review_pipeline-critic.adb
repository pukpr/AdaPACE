with Pace.Log;

package body Review_Pipeline.Critic is

   --  let critic : !Verdict -> !Review = agent { ... }
   --
   --  Receives a Verdict (passed) and produces either:
   --    score < 85   ->  map({score, review}) ; composer
   --    score >= 85  ->  .draft ; output
   --
   --  Simulation: score improves each iteration.
   --    iter 1 -> score 70  (needs work)
   --    iter 2 -> score 85  (approved -> pipeline terminates)

   function Id is new Pace.Log.Unit_Id;

   task Agent is
      entry Input (Obj : in Review_Pipeline.Verdict);
   end Agent;

   task body Agent is
      V : Review_Pipeline.Verdict;
   begin
      Pace.Log.Agent_Id (Id);
      loop
         --  Short rendezvous: trace synchronous handshake, then copy message.
         accept Input (Obj : in Review_Pipeline.Verdict) do
            Pace.Log.Trace (Obj);
            V := Obj;
         end Input;

         declare
            Iter        : constant Natural := V.Iteration;
            --  Simulate: iter 1 -> 70, iter 2 -> 85, iter 3+ -> 90
            Score       : constant Integer :=
               (if Iter <= 1 then 70 elsif Iter = 2 then 85 else 90);
            Review_Text : constant String  :=
               (if Score < 85
                then "Score:" & Integer'Image (Score) &
                     ". Needs more depth and stronger examples."
                else "Score:" & Integer'Image (Score) &
                     ". Excellent: clear, well-structured, and comprehensive.");
         begin
            Pace.Log.Put_Line
               ("Critic  [iter" & Natural'Image (Iter) &
                "]: " & Review_Text);

            if Score < 85 then
               --  filter(score < 85) ; map({score, review}) ; composer
               declare
                  Req : Review_Pipeline.Request;
               begin
                  Req.Prompt    := +("Improve per review (" & Review_Text &
                                     ").  Previous draft: " & (-V.Draft_Text));
                  Req.Iteration := Iter + 1;
                  Pace.Dispatching.Input (Req);
               end;
            else
               --  filter(score >= 85).draft ; output
               Review_Pipeline.Pipeline_Output.Publish (-V.Draft_Text);
            end if;
         end;
      end loop;
   exception
      when E : others => Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Review_Pipeline.Verdict) is
   begin
      Agent.Input (Obj);
   end Input;

end Review_Pipeline.Critic;
