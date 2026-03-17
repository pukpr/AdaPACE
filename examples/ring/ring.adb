with Pace.Log;
with Pace.Socket;

package body Ring is

    function Id is new Pace.Log.Unit_Id;

    task Agent is
	entry Input (Obj : in Token);
    end Agent;

    Value : Integer;
    Color : Integer;

    task body Agent is
	T : Duration;
    begin
	Pace.Log.Agent_Id (Id);
	T := Pace.Now;
	loop
	    accept Input (Obj : in Token) do
		Pace.Log.Trace (Obj);
		Value := Obj.Value + 1;
		Color := Obj.Color;
	    end Input;
	    if Value mod 1000 = 1 then
		Pace.Log.Put_Line ("Has token from" & Integer'Image (Color) &
				   " with value =" & Integer'Image (Value) &
				   " time =" & Duration'Image (Pace.Now - T));
		T := Pace.Now;
	    end if;
	    delay 0.000001;
	    declare
		Msg : Token;
	    begin
		Msg.Value := Value;
		Msg.Color := Color;
		Pace.Socket.Send (Msg, Ack => False);
	    end;
	end loop;
    end Agent;

    procedure Input (Obj : in Token) is
    begin
	Agent.Input (Obj);
    end Input;

end Ring;
