with Gnu.Rule_Process;

procedure ES is
   use Gnu.Rule_Process;
   KB : Agent_Type (2_000_000);
begin
   KB.Init (Ini_File => "",
            Console => True,
            Screen => True,
            Ini => (Clause    => 1000,
                    Hash      => 507,
                    In_Toks   => 500,
                    Out_Toks  => 500,
                    Frames    => 4000,
                    Goals     => 6000,
                    Subgoals  => 300,
                    Trail     => 5000,
                    Control   => 700));

end;
