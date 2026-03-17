with Interfaces.C.Strings;
with Text_Io;

package body Gnu.Pdf is
   -- pragma Linker_Options ("-lpdf");
   pragma Linker_Options ("-lm");

   function "+" (Str : String) return P_String is
   begin
      return P_String (Str & Ascii.Nul);
   end "+";

   function "-" (Str : P_String) return String is
   begin
      for I in Str'Range loop
         if Str (I) = Ascii.Nul then
            return String (Str (Str'First .. I - 1));
         end if;
      end loop;
      return String (Str);
   end "-";

   function Pdf_Get_Parameter
              (P : access Pdf; Key : P_String; Modifier : P_Float)
              return String is
      use Interfaces.C.Strings;
      function Pdf_Get_Parameter
                 (P : access Pdf; Key : P_String; Modifier : P_Float)
                 return Chars_Ptr;  
      pragma Import (C, Pdf_Get_Parameter, "PDF_get_parameter");  
      Chars : Chars_Ptr;
   begin
      Chars := Pdf_Get_Parameter (P, Key, Modifier);
      if Chars = Null_Ptr then
         return "";
      else
         return Value (Chars);
      end if;
   end Pdf_Get_Parameter;


   function Pdf_Get_Buffer
              (P : access Pdf; Size : access Long_Integer) return String is  
      use Interfaces.C.Strings;
      function Pdf_Get_Buffer
                 (P : access Pdf; Size : access Long_Integer) return Chars_Ptr;  
      pragma Import (C, Pdf_Get_Buffer, "PDF_get_buffer");  
      Chars : Chars_Ptr;
   begin
      Chars := Pdf_Get_Buffer (P, Size);
      if Chars = Null_Ptr then
         return "";
      else
         return Value (Chars);
      end if;
   end Pdf_Get_Buffer;

   pragma Warnings (Off);
   procedure Default_Error (P : access Pdf; Error : Error_Type; Msg : P_String);
   pragma Convention (C, Default_Error);
   pragma Warnings (On);

   procedure Default_Error
               (P : access Pdf; Error : Error_Type; Msg : P_String) is
      Err : constant String := -Msg & " # " & Error_Type'Image (Error);
   begin
      Text_Io.Put_Line (Text_Io.Standard_Error, Err);
      if Error = Pdf_Nonfatal_Error then
         return;
      else
         raise Pdf_Error;
      end if;
   end Default_Error;

   procedure Initialize (Handle : in out Pdf_Handle) is
   begin
      Handle.Obj := Pdf_New2 (Default_Error'Access);
      Pdf_Set_Parameter (Handle.Obj, +"binding", +"Ada");
   end Initialize;

   procedure Finalize (Handle : in out Pdf_Handle) is
   begin
      Pdf_Delete (Handle.Obj);
   end Finalize;

   function "+" (Handle : Pdf_Handle) return Pdf_Access is
   begin
      return Handle.Obj;
   end "+";

begin
   Pdf_Boot;
end Gnu.Pdf;
