with Pace.Log;
with Post.A;
with Pace.Surrogates;

procedure Post.Small is
   --pragma Time_Slice (0.0);
   Msg : Post.A.Start;
   package S is new Pace.Surrogates.Asynchronous(Post.A.Start);
begin
   Pace.Dispatching.Set_Trace_Call (Pace.Log.Trace'Access);
   Pace.Log.Agent_Id;
   --Pace.Dispatching.Input (Msg);
   S.Surrogate.Input(Msg);
end Post.Small;
