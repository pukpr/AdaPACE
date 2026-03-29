with Hal.Gazebo_Commands;

package Tetris is

   --  The seven classic Tetris tetrominoes.
   --  Names match the SDF link names (plugin maps them case-insensitively).
   type Pieces is (
      I_piece,   --  Cyan:   four blocks in a row
      O_piece,   --  Yellow: 2×2 square
      T_piece,   --  Purple: T-shape
      S_piece,   --  Green:  S-shape
      Z_piece,   --  Red:    Z-shape
      J_piece,   --  Blue:   J-shape
      L_piece    --  Orange: L-shape
   );

   --  Shared-memory key must match libTablePlugin SHM_KEY (see tetris.sdf)
   package Gz is new Hal.Gazebo_Commands (Key => 123456, Entities => Pieces);

end Tetris;
