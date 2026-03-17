with Pace;
with Pace.Queue.Guarded;
with Pace.Server.Dispatch;
with Ada.Strings.Unbounded;
with Ada.Text_Io;

package Hal.Maintenance is

   -- A utility class for easy stepping of assemblies

   pragma Elaborate_Body;

   -- if this is given as the amount to a Step, then that Step will
   -- go home!
   Home : constant Float := -999999.9999999;

   -- Use this type when displaying info to the user
   type Float_Display is digits 4;

   package Float_Display_Io is new Ada.Text_Io.Float_Io (Float_Display);

   type Axes is (X, Y, Z);

   type Step_Parameters is
      record
         -- When translating represents meters
         -- When rotating represents radians (not degrees!).
         -- Sign of Amount determines direction of motion
         Amount : Float := 0.1;
         Speed : Hal.Rate := (1.0, 1);
      end record;

   type Step is abstract tagged
      record
         Assembly_Name : Ada.Strings.Unbounded.Unbounded_String;
         Lower_Limit : Float;
         Upper_Limit : Float;

         -- The following four attributes represent location information.
         -- Home_Location is represented as a Hal.Position... if a child
         -- class needs it as a Hal.Orientation object it must do the
         -- conversion.
         -- Current_Location and Destination_Location are a single float
         -- (instead of a tuple) since all assemblies can only move on 1
         -- axis.  Which axis these two variables represent is determined
         -- by Axis.
         Home_Location : Hal.Position;
         Current_Location : Float;
         Destination_Location : Float;
         Axis : Axes;
      end record;

   procedure Perform_Action
               (Obj : in out Step; Params : in out Step_Parameters) is abstract;

   procedure Url_Configure_Params
               (Obj : in out Step'Class; Params : out Step_Parameters);

   procedure Check_Limits (Obj : in out Step'Class);

   procedure Calculate_Destination (Obj : in out Step'Class; Amount : Float);

   function Calculate_Location_As_Percent (Obj : Step'Class) return Float;

   function Get_Location_As_Absolute
              (Obj : Step'Class) return Ada.Strings.Unbounded.Unbounded_String;





   type Step_Translate is new Step with null record;

   procedure Perform_Action (Obj : in out Step_Translate;
                             Params : in out Step_Parameters);


   function Get_Current_Pos (Obj : Step_Translate'Class) return Hal.Position;

   function Get_Destination_Pos
              (Obj : Step_Translate'Class) return Hal.Position;




   type Step_Rotate is new Step with null record;

   procedure Perform_Action (Obj : in out Step_Rotate;
                             Params : in out Step_Parameters);

   function Get_Current_Ori (Obj : Step_Rotate'Class) return Hal.Orientation;

   function Get_Destination_Ori
              (Obj : Step_Rotate'Class) return Hal.Orientation;


   -- adjusts amount for saving onto the undo stack
   -- this is necessary in case the step attempted to move beyond one of
   -- it's limits, or for any reason that the hal movement didn't go as
   -- far as planned
   -- Also, swaps the sign of the amount, thereby switching direction of
   -- motion.
   procedure Adjust_Amount (Amount : in out Float; Difference : Float);


   -- following is needed for Undo capabilities

   package Stack is new Pace.Queue (Pace.Channel_Msg, Fifo => False);
   package Guarded_Stack is new Stack.Guarded;

   type Save is new Pace.Msg with
      record
         Execute_Object : Pace.Channel_Msg;
      end record;
   procedure Input (Obj : in Save);

   type Step_Transaction is abstract new Pace.Msg with
      record
         Params : Step_Parameters;
         Last_Step_Amount : Float;
      end record;
   procedure Inout (Obj : in out Step_Transaction) is abstract;
   -- the undo function:
   --procedure Inout (Obj : in out Step_Transaction);


   -- package wide methods
   procedure Undo;
   -- This should be called for every step that takes place (usually
   -- by the action request).  This is necessary to store each step
   -- on a stack for Undo capabilities later.  It will also call
   -- Inout on the step.
   procedure Execute (Obj : in out Step_Transaction'Class);

end Hal.Maintenance;

