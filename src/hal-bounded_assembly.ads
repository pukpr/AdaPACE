with Ada.Strings.Bounded;

package Hal.Bounded_Assembly is
  new Ada.Strings.Bounded.Generic_Bounded_Length (Hal.Max_Assembly_Name_Length);

