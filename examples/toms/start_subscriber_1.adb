with Subscriber_1;
--with subscriber_2;
with Ses.Pp;
with Pace.Log;

procedure Start_Subscriber_1 is

begin
    Pace.Log.Agent_Id;
    Ses.Pp.Parser;
exception
    when E: others =>
	Ses.Os_Exit (0);
end Start_Subscriber_1;
