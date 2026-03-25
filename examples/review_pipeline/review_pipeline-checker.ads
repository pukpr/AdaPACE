with Review_Pipeline;

package Review_Pipeline.Checker is
   pragma Elaborate_Body;

   --  Checker agent entry point.
   --  Called via Pace.Dispatching.Input (Draft) ->
   --    Review_Pipeline.Input (Draft) -> Checker.Handle (Draft).
   procedure Handle (Obj : in Review_Pipeline.Draft);

end Review_Pipeline.Checker;
