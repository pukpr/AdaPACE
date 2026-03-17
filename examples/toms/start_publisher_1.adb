--with subscriber_1;
--with subscriber_2;
with Publisher_1;
with Ses.Pp;
with Pace.Log;
procedure Start_Publisher_1 is
begin
    Pace.Log.Agent_Id;
    Ses.Pp.Parser;
exception
    when E: others =>
	Ses.Os_Exit (0);
end Start_Publisher_1;
