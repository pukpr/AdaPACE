package Ses.Pipe_Server is

   --
   -- Pipe Server communicates through a Bi-Directional pipe to Exec
   --
   procedure Set_Pipe (Exec, Args : in String);
   procedure Close_Pipe;


   --
   -- Web Server communicates through the Web
   --
   procedure Set_Web;

end Ses.Pipe_Server;
