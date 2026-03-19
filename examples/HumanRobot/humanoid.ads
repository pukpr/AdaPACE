with Hal.Gazebo_Commands;

package Humanoid is

   type Links is (
      Torso,
      Neck,
      Head,
      LPelvis,
      LHip,
      LThigh,
      LTibia,
      LAnkle,
      LSole,
      LShoulder,
      LBicep,
      LElbow,
      LForeArm,
      LWrist,
      RPelvis,
      RHip,
      RThigh,
      RTibia,
      RAnkle,
      RSole,
      RShoulder,
      RBicep,
      RElbow,
      RForeArm,
      RWrist
   );

   package Gz is new Hal.Gazebo_Commands(Key => 123456, Entities => Links);

end Humanoid;
