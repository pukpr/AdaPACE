with Pace.Log;
with Pace.Socket;
with Orchestra;
with Processor_Pkg;

package body Orchestra is

   -- 1. Input received by Processor agent
   procedure Input (Obj : in Raw_Data) is
   begin
      Pace.Log.Trace (Obj); -- Essential for simulation timeline
      Processor_Pkg.Notify_Processor;
   end Input;

   -- 2. Input received by Consumer agent
   procedure Input (Obj : in Refined_Data) is
   begin
      Pace.Log.Trace (Obj); -- Essential for simulation timeline
      Pace.Log.Put_Line ("Consumer: Received Refined Data #" & 
                         Integer'Image(Obj.Serial) & 
                         " (Factor =" & Float'Image(Obj.Factor) & ")");
   end Input;

end Orchestra;
