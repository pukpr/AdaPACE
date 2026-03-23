--with subscriber_1;
--with subscriber_2;
with Publisher_1;
with Pace.Ses.Pp;
with Pace.Log;
procedure Start_Publisher_1 is
begin
    Pace.Log.Agent_Id;
    Pace.Ses.Pp.Parser;
exception
    when E: others =>
	Pace.Log.Os_Exit (0);
end Start_Publisher_1;
