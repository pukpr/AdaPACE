with Ring;
with Pace.Socket;
with Pace.Log;
with Pace.Ses.Pp;

procedure Pace.Ring_Driver is
begin
--   Pace.Config.Assert ("max_node", 
--                        Pace.Command_Line.Argument("max"));   
    Pace.Log.Agent_Id;
    declare
	Msg : Ring.Token;
    begin
	Msg.Value := 1;
	Msg.Color := Pace.Get;
	Pace.Socket.Send (Msg);
    end;
    Pace.Ses.Pp.Parser;
exception
    when others =>
	Pace.Log.Os_Exit (0);  
end Pace.Ring_Driver;
