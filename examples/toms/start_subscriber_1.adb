with Subscriber_1;
--with subscriber_2;
with Pace.Ses.Pp;
with Pace.Log;

procedure Start_Subscriber_1 is

begin
    Pace.Log.Agent_Id;
    Pace.Ses.Pp.Parser;
exception
    when E: others =>
	Pace.Log.Os_Exit (0);
end Start_Subscriber_1;
