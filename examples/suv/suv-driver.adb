with Suv.Controller;
with Pace.Log;
with UIO.Server;

procedure Suv.Driver is
   Msg : Suv.Controller.Start_Control;
begin
   Uio.Server.Create;
   Pace.Log.Agent_ID;
   Pace.Dispatching.Input (Msg);
end;
