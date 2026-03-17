with Pace.Stream;
with Text_IO;
with Ada.Strings.Fixed;
with Pace.Strings;

package body Hla is

   use Pace.Strings;

--   type Coding is (Raw, XDR);
--   Code : constant Coding := XDR;

   DS  : Pace.Stream.Data_Access := new Pace.Stream.Data_Stream;
   DSM : aliased Pace.Semaphore.Mutex;


   package body Convert is

      function Value (Str : String) return Binary is
         L : Pace.Semaphore.Lock (DSM'Access);
      begin
         Pace.Stream.Reset_Data(DS);
         Pace.Stream.Set_Array (DS, Pace.Stream.To_Array (Str));
         return Binary'Input(DS);
      end Value;

      Quad : constant := 4; -- for XDR, Align on 4-byte boundaries

      function Image (Data : Binary) return String is
         L : Pace.Semaphore.Lock (DSM'Access);
      begin
         Pace.Stream.Reset_Data(DS);
         Binary'Output (DS, Data);
         -- XDR needs quad alignment
         declare
            Rep : constant String :=
                Pace.Stream.To_String (Pace.Stream.Get_Array(DS));
            Pad : constant Integer := Quad - (Rep'Length mod Quad);
            use Ada.Strings.Fixed;
         begin
            --return Pace.Stream.To_String (Pace.Stream.Get_Array(DS));
            if Pad = Quad then
               return Rep;
            else
               return Rep & Pad * Ascii.Nul;
            end if;
         end;
      end Image;

      function Param (Data : Binary) return Tuple is
      begin
         return (S2u (Parameter_Name), S2u (Image (Data)));
      end Param;

      function Check (Unknown_Name : String) return Boolean is
      begin
         return Unknown_Name = Parameter_Name;
      end Check;
   end Convert;

   procedure Exit_Gateway  (Handle : Gateway := Null_Gateway) is
      procedure ExitGateway (Handle : Gateway);
      pragma Import (C, ExitGateway, "Exit_Gateway");
      L : Pace.Semaphore.Lock(Connection'Access);
   begin
      ExitGateway (Handle);
   end;

   function "+" (Str : in String) return VString is
      VS : constant VString := (Length => Str'Length,
                                Value => Str);
   begin
      return VS;
   end;

   function "+" (Str : in VString) return String is
   begin
      return Str.Value;
   end;


   type Program_Exiter is access procedure;
   pragma Convention (C, Program_Exiter);

   procedure Cleanup;
   pragma Convention (C, Cleanup);
   
   -- A callback, as in the following
   procedure Cleanup is
   begin
      -- Pace.Log.Put_Line ("EXITING GATEWAY.......");
      -- Text_IO.Put_Line ("EXITING GATEWAY.......");
      -- Exit_Gateway;
      Text_IO.Put_Line ("HLA.CLEANUP @ EXIT .......");
      -- Pace.Log.Put_Line ("EXITING APP.......");
   end;

   procedure At_Exit (Proc : in Program_Exiter);
   pragma Import(C, At_Exit, "atexit");

begin
   At_Exit (Cleanup'Access);
   -- $id: hla.adb,v 1.3 11/21/2003 18:45:44 pukitepa Exp $
end Hla;
