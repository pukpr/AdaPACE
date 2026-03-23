with Tlc;
with Pace.Ses.Pp;
with Pace.Log;
procedure Tlc_Test is
begin
    Pace.Ses.Pp.Parser;
exception
    when others =>
	Pace.Log.Os_Exit (0);
end Tlc_Test;
