with Review_Pipeline;

package Review_Pipeline.Composer is
   pragma Elaborate_Body;

   --  Composer agent entry point.
   --  Called via Pace.Dispatching.Input (Request) ->
   --    Review_Pipeline.Input (Request) -> Composer.Handle (Request).
   procedure Handle (Obj : in Review_Pipeline.Request);

end Review_Pipeline.Composer;
