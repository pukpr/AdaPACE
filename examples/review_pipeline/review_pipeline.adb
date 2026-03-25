with Pace.Log;
with Review_Pipeline.Composer;
with Review_Pipeline.Checker;
with Review_Pipeline.Critic;

package body Review_Pipeline is

   --  -----------------------------------------------------------------------
   --  Routing hub: each Input primitive dispatches to the appropriate agent.
   --  This is the only place in the codebase that with-s all three agents,
   --  keeping agent specs free of cross-agent dependencies (pace.pdf:
   --  "Avoid placing with-dependencies in package spec").
   --
   --  Pace.Log.Trace is called on every message so the trace log records
   --  each edge of the directed message-flow graph:
   --    Request  ->  Composer   (trace here, before Handle)
   --    Draft    ->  Checker    (trace here, before Handle)
   --    Verdict  ->  Critic     (trace inside accept Input rendezvous)
   --  The Verdict trace is placed inside Critic.Agent's accept Input so
   --  it captures the synchronous handshake point in the trace output.
   --  Post-processing the trace output yields the full coordination graph.
   --  -----------------------------------------------------------------------

   procedure Input (Obj : in Request) is
   begin
      Pace.Log.Trace (Obj);
      Review_Pipeline.Composer.Handle (Obj);
   end Input;

   procedure Input (Obj : in Draft) is
   begin
      Pace.Log.Trace (Obj);
      Review_Pipeline.Checker.Handle (Obj);
   end Input;

   procedure Input (Obj : in Verdict) is
   begin
      Review_Pipeline.Critic.Input (Obj);
   end Input;

   --  -----------------------------------------------------------------------
   --  Pipeline_Output protected body
   --  -----------------------------------------------------------------------

   protected body Pipeline_Output is

      procedure Publish (Text : in String) is
      begin
         Result := +Text;
         Ready  := True;
      end Publish;

      entry Collect (Text : out Ustring) when Ready is
      begin
         Text := Result;
      end Collect;

   end Pipeline_Output;

end Review_Pipeline;
