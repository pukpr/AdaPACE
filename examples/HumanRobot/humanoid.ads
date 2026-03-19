with Hal.Gazebo_Commands;

package Humanoid is

   -- JOINTS (Using names from SDF after lower-casing)
   type Joints is (
      HeadYaw,
      HeadPitch,
      LHipYawPitch,
      LHipRoll,
      LHipPitch,
      LKneePitch,
      LAnklePitch,
      LAnkleRoll,
      LShoulderPitch,
      LShoulderRoll,
      LElbowYaw,
      LElbowRoll,
      LWristYaw,
      RHipYawPitch,
      RHipRoll,
      RHipPitch,
      RKneePitch,
      RAnklePitch,
      RAnkleRoll,
      RShoulderPitch,
      RShoulderRoll,
      RElbowYaw,
      RElbowRoll,
      RWristYaw
   );

   -- LINKS (For torso/head if controlled kinematically)
   type Links is (
      Torso,
      Head
   );

   package Gz_Joints is new Hal.Gazebo_Commands(Key => 123456, Entities => Joints);
   package Gz_Links  is new Hal.Gazebo_Commands(Key => 123456, Entities => Links);

end Humanoid;
