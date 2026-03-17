with Ada.Containers.Vectors;
with Hal.Bounded_Assembly;

package Hal.Velocity_Plots is

   pragma Elaborate_Body;

   use Hal.Bounded_Assembly;

   package Velocity_Vector is new Ada.Containers.Vectors  (Positive,
                                                           Float,
                                                           "=");

   -- a vector of velocities that occured at time Index * Delta_Time
   type Velocity_Plot_Data is
      record
         -- Delta_Time is the amount of time between each index of the Velocities vector
         Delta_Time : Duration;
         Velocities : Velocity_Vector.Vector;
      end record;

   -- stores velocity plot data for later retrieval
   -- if data already exists for Assembly,
   -- then it will be overwritten with this new data
   procedure Add_Plot_Data (Assembly : Bounded_String;
                            Plot_Data : Velocity_Plot_Data);

   function Get_Velocity_Vector (Assembly : String) return Velocity_Plot_Data;

   package Assembly_Vector is new Ada.Containers.Vectors (Positive,
                                                          Bounded_String,
                                                          "=");

   function Get_Assembly_List return Assembly_Vector.Vector;

end Hal.Velocity_Plots;
