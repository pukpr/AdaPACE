with Tetris;
with Pace.Log;
with Pace.Ses.Pp;

--  Tetris falling-pieces demo.
--
--  All seven classic tetrominoes are animated by this Ada control agent.
--  Gravity is zero in the SDF; this program simulates free-fall by
--  decrementing each piece's Z position at every time step.  Each piece
--  also rotates (yaw) as it falls, demonstrating Set_Pose-driven motion.
--  When a piece reaches the ground (Z ≤ 0.5) it is recycled back to the
--  top, just like a Tetris game loop.
--
--  Eventually the Ada Tetris game from pukpr/degas will replace this demo
--  loop with full game logic (piece selection, collision detection, line
--  clearing) while re-using the same Gz.Set_Pose / Gz.Set_Rot interface.

procedure Tetris_Main is
   use Tetris;

   dT : constant Long_Float := 0.05;  --  simulation step (seconds)

   --  Fixed X positions matching the SDF link poses (one column per piece)
   Start_X : constant array (Pieces) of Long_Float :=
      (I_piece => -6.0,
       O_piece => -4.0,
       T_piece => -2.0,
       S_piece =>  0.0,
       Z_piece =>  2.0,
       J_piece =>  4.0,
       L_piece =>  6.0);

   --  Fall speeds (m/s).  Vary slightly so pieces are not in lock-step.
   Fall_Speed : constant array (Pieces) of Long_Float :=
      (I_piece => 2.0,
       O_piece => 2.2,
       T_piece => 1.8,
       S_piece => 2.4,
       Z_piece => 1.9,
       J_piece => 2.1,
       L_piece => 2.3);

   --  Yaw rotation speeds (rad/s).
   --  O-piece is symmetric so it gets 0 to avoid visual noise.
   Spin_Speed : constant array (Pieces) of Long_Float :=
      (I_piece => 1.5,
       O_piece => 0.0,
       T_piece => 1.2,
       S_piece => 1.8,
       Z_piece => 1.8,
       J_piece => 1.2,
       L_piece => 1.2);

   --  Mutable state: current Z height and yaw angle for each piece
   Z_Pos : array (Pieces) of Long_Float := (others => 12.0);
   Angle : array (Pieces) of Long_Float := (others =>  0.0);

   --  Control task runs the infinite falling loop
   task Falling_Pieces;
   task body Falling_Pieces is
   begin
      loop
         for P in Pieces loop

            --  Advance fall and spin
            Z_Pos (P) := Z_Pos (P) - Fall_Speed (P) * dT;
            Angle (P) := Angle (P) + Spin_Speed (P) * dT;

            --  Recycle piece back to the top once it hits the ground
            if Z_Pos (P) < 0.5 then
               Z_Pos (P) := 12.0;
               Angle (P) :=  0.0;
            end if;

            --  Push the new pose to Gazebo via shared memory
            Gz.Set_Pose (Name => P,
                         X    => Start_X (P),
                         Z    => Z_Pos (P),
                         Yaw  => Angle (P));

         end loop;

         Pace.Log.Wait (dT);
      end loop;
   end Falling_Pieces;

begin
   Pace.Log.Put_Line ("Tetris falling-pieces demo started.");
   --  Main task runs the P4 parser; shutdown is signalled from there
   Pace.Ses.Pp.Parser;
exception
   when others => Pace.Log.Os_Exit (0);
end Tetris_Main;
