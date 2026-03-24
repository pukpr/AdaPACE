with Suite;
with AUnit.Test_Runner;
with Uio.Server;
with GNAT.OS_Lib;

procedure Test_Runner is
   procedure Run is new AUnit.Test_Runner (Suite.Suite);
begin
   Uio.Server.Create (Number_Of_Readers => 0, P4_On => False);
   Run;
   GNAT.OS_Lib.OS_Exit (0);
end Test_Runner;
