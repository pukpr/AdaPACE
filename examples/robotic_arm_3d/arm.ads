with Hal.Gazebo_Commands;

package Arm is
   type Elements is (
      Base,
      Lower_Arm,
      Upper_Arm,
      Gripper
   );

   package Gz is new Hal.Gazebo_Commands(Key => 123456, Entities => Elements);

end Arm;
