with Ada.Strings.Unbounded;

package Pace.Fault is
   ------------------------------------------------------
   -- Fault -- Logging faults for later retrieval
   ------------------------------------------------------
   pragma Elaborate_Body;

   type ID is new Pace.Msg with record
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Instance : Integer := 1;
   end record;

   procedure Input (Obj : in ID);  -- command deposit of fault
   procedure Output (Obj : out ID);  -- retrieval of fault

   function To_Name
     (Str  : in String)
      return Ada.Strings.Unbounded.Unbounded_String renames
     Ada.Strings.Unbounded.To_Unbounded_String;
   function To_Str
     (Str  : in Ada.Strings.Unbounded.Unbounded_String)
      return String renames Ada.Strings.Unbounded.To_String;

   procedure Send (Name : in String; Instance : in Integer := 1);
   generic
   procedure Report (Instance : in Integer := 1);

      -------------------------------------------------------------------------
      -------
      -- $id: pace-fault.ads,v 1.1 09/16/2002 18:18:25 pukitepa Exp $
      -------------------------------------------------------------------------
      -------
   end Pace.Fault;
