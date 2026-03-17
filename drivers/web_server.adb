with Pace.Log;
with UIO.Server;
-- with Gis.Ctdb.Server;

procedure Web_Server is
   NT : constant Integer := Pace.Getenv("MAX_CLIENTS", 10);
   SS : constant Integer := Pace.Getenv("MAX_STACK", 1_000_000);
begin
   UIO.Server.Create (NT, SS, True);
   Pace.Log.Agent_ID;
   Pace.Log.Put_Line ("WebServer Running:" & 
                      " Max Threads:" & NT'Img &
                      " Max Stack:" & SS'Img);
end;
