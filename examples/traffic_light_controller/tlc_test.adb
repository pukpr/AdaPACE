with Tlc;
with Ses.Pp;
procedure Tlc_Test is
begin
    Ses.Pp.Parser;
exception
    when others =>
	Ses.Os_Exit (0);
end Tlc_Test;
