with Review_Pipeline;

package Review_Pipeline.Critic is
   --pragma Elaborate_Body;

   --  Critic agent entry point.
   --  Called via Pace.Dispatching.Input (Verdict) ->
   --    Review_Pipeline.Input (Verdict) -> Critic.Handle (Verdict).
   procedure Handle (Obj : in Review_Pipeline.Verdict);

end Review_Pipeline.Critic;
