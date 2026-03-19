with Hal.Gazebo_Commands;

package Panda is

   type Joints is (
      Panda_Joint1,
      Panda_Joint2,
      Panda_Joint3,
      Panda_Joint4,
      Panda_Joint5,
      Panda_Joint6,
      Panda_Joint7,
      Panda_Finger_Joint1,
      Panda_Finger_Joint2
   );

   package Gz is new Hal.Gazebo_Commands(Key => 123456, Entities => Joints);

end Panda;
