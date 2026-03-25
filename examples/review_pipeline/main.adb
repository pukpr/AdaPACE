with Review_Pipeline;
with Review_Pipeline.Composer;
with Review_Pipeline.Checker;
with Review_Pipeline.Critic;
with Pace.Log;

procedure Main is
   --  Single-executable review pipeline.
   --  Withing the three agent packages here ensures their bodies are
   --  elaborated (tasks started) before Main begins executing.

   function Id is new Pace.Log.Unit_Id;

   use Review_Pipeline;

   Req    : Request;
   Output : Ustring;

begin
   Pace.Log.Agent_Id (Id);

   Pace.Log.Put_Line ("=== Review Pipeline ===");
   Pace.Log.Put_Line
      ("Input: Write an essay about the PACE agent coordination framework.");

   Req.Prompt    := +"Write an essay about the PACE agent coordination framework.";
   Req.Iteration := 0;

   --  Kick off the pipeline via local dispatch:
   --    Main -> Review_Pipeline.Input(Request)
   --         -> Composer.Handle -> Composer.Agent (task rendezvous)
   --  Main is unblocked as soon as Composer.Agent accepts the message.
   Pace.Dispatching.Input (Req);

   --  Block here until Critic approves a draft (score >= 85) and
   --  calls Pipeline_Output.Publish.
   Pipeline_Output.Collect (Output);

   Pace.Log.Put_Line ("");
   Pace.Log.Put_Line ("=== FINAL OUTPUT ===");
   Pace.Log.Put_Line (-Output);
   Pace.Log.Put_Line ("====================");

   Pace.Log.Os_Exit (0);
end Main;
