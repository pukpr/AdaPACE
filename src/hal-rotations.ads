package Hal.Rotations is

   pragma Elaborate_Body;

   ------------------------------------------------
   -- ROTATIONS - Basic Roll, Pitch, Yaw rotations
   ------------------------------------------------
   -- A,B,C are rotations about X,Y,Z respectively
   -- follows SSOM internal terrain coordinate system with
   -- X north (roll), Y east (pitch), Z down (yaw)

   type Euler_Index is (A, B, C);
   type Euler_Projection is (X, Y, Z);
   type Rotation_Matrix is array (Euler_Projection, Euler_Index) of Float;
   type Rotation_Order is array (Integer range 1..3) of Euler_Index;
   Default_Order : constant Rotation_Order := (A,B,C); -- standard YPR order

   function Multiply (M : Rotation_Matrix;
                      N : Rotation_Matrix) return Rotation_Matrix;

   function Multiply (R : in Orientation; M : in Rotation_Matrix)
                      return Orientation;

   function Multiply (P : in Position; M : in Rotation_Matrix)
                      return Position;

   function Rx (Theta : in Float) return Rotation_Matrix;
   function Ry (Theta : in Float) return Rotation_Matrix;
   function Rz (Theta : in Float) return Rotation_Matrix;


   function Rx (P : in Position; A : in Float; Invert : in Boolean := False) return Position;
   function Ry (P : in Position; B : in Float; Invert : in Boolean := False) return Position;
   function Rz (P : in Position; C : in Float; Invert : in Boolean := False) return Position;
   function Rn (P : in Position;     -- n=1,2,3 corresponding to xyx
                R : in Orientation; 
                E : in Euler_Index;  -- Arbitrary Rotation
                Invert : in Boolean := False) return Position;

   -- Transformation in order according to Terrain Coordinate System
   -- Rz (Ry (Rx)) (rotate first around X, then new Y, then new Z)
   -- order is opposite when doing inverse
   function R3_Terrain (P : in Position; 
                        R : in Orientation; 
                        Invert : in Boolean := False;
                        Order : in Rotation_Order := Default_Order) return Position;

   function Convert_Vector (In_Vec : Position;
                            First : Rotation_Matrix;
                            Second : Rotation_Matrix;
                            Third : Rotation_Matrix) return Position;

   -- Transformation in order according to Division Coordinate System ->  Ry (Rx (Rz))
   -- order is opposite when doing inverse
   function R3_Div (P : in Position; R : Orientation; Invert : Boolean := False) return Position;

   -- Roll/Pitch/Yaw seq is not being used but may be needed in the future
   type Sequence is (Default, RPY, RYP, PYR, PRY, YRP, YPR);

   -- In the direction that the object is oriented
   procedure To_Quaternion (Yaw, Pitch, Roll : in Float;
                            W, X, Y, Z : out Float;
                            Latitude, Longitude : in Float := 0.0;
                            Seq : in Sequence := Default);

   procedure To_Euler (W, X, Y, Z : in Float;
                       Yaw, Pitch, Roll : out Float;
                       Latitude, Longitude : in Float := 0.0);

   -- this uses the SLERP method (Spherical Linear Interpolation)
   -- returns an array of Orientations of size Num with Start at index 1
   -- and Final at index num
   function Interpolate_Quat (Num : in Integer; -- number of interpolations
                              Start : in Orientation;
                              Final : in Orientation) return Ori_Arr;

   -- This can be used to go from an absolute reference frame to a relative reference
   -- frame (set Invert to true) or vice-versa (set Invert to false).
   procedure Adjust_For_Pitch_And_Roll (In_El : in Float; -- the input elevation (radians)
                                        In_Az : in Float; -- the input azimuth (radians)
                                        Pitch : in Float; -- radians
                                        Roll : in Float; -- radians
                                        Yaw : in Float;  -- radians
                                        Invert : in Boolean;  -- should be true for abs to rel
                                        Out_El : out Float; -- the output elevation (radians)
                                        Out_Az : out Float; -- the output azimuth (radians)
                                        Order : in Rotation_Order :=Default_Order);

   procedure To_Axis (W, X, Y, Z : in Float;
                      To, Up : out Position);
   procedure To_Axis (Yaw, Pitch, Roll : in Float;
                      To, Up : out Position);


   -- Given a rotation matrix will extract the orientation it represents
   -- from the YXZ Euler point of view
   function Extract_YXZ (Tm : Rotation_Matrix) return Orientation;

   function Convert_Euler_To_Yxz (First : Rotation_Matrix;
                                  Second : Rotation_Matrix;
                                  Third : Rotation_Matrix;
                                  Inverse : Boolean) return Orientation;
   pragma Warnings (off, Convert_Euler_To_Yxz);  -- Doesn't like Boolean, should be char
   pragma Export (C, Convert_Euler_To_Yxz, "Convert_Euler_To_Yxz");

   type Euler_Conversion is (None,
                             Xyz_To_Yxz, Xzy_To_Yxz,
                             Yxz_To_Yxz, Yzx_To_Yxz,
                             Zxy_To_Yxz, Zyx_To_Yxz);

   function Convert_Euler (Conv_Type : Euler_Conversion;
                           Ori : Orientation;
                           Inverse : Boolean := False) return Orientation;

   -- can't export to C with a signature that has a default
   procedure Convert_Euler_C (Conv_Type : Euler_Conversion;
                              In_A, In_B, In_C : in Float;
                              Out_A, Out_B, Out_C : out Float;
                              Inverse : Boolean);
   pragma Warnings (off, Convert_Euler_C);  -- Doesn't like Boolean, should be char
   pragma Export (C, Convert_Euler_C, "convert_euler");

   -- can't export to C with a signature that has a default
   procedure Convert_Vector_Xyz_To_Yxz_C (In_X, In_Y, In_Z : in Float;
                                          In_A, In_B, In_C : in Float;
                                          Out_X, Out_Y, Out_Z : out Float);
   pragma Export (C, Convert_Vector_Xyz_To_Yxz_C, "convert_vector_xyz_to_yxz");

end Hal.Rotations;

