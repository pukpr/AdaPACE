with Pace;

package Max_Finder is
   pragma Elaborate_Body;

   -- Message sent from Worker to Server
   type Found_Value is new Pace.Msg with record
      Value : Float;
      Origin : Integer; -- Node ID of the worker
   end record;

   -- Server primitive to handle incoming values
   procedure Input (Obj : in Found_Value);

   -- Protected type to store the maximum value safely
   protected Max_Store is
      procedure Update (New_Value : Float; From_Node : Integer; Success : out Boolean);
      function Get_Max return Float;
   private
      Current_Max : Float := Float'First;
   end Max_Store;

end Max_Finder;
