package Hal.Sms_Lib.Banana_Track is

   procedure Increment_Slot (Rotate : in Rotation_Direction);

   procedure Step (Rotate : in Rotation_Direction; Number : in Integer := 1);

   function Get_Current_Slot return Integer;

   procedure Initialize_Slots;

end Hal.Sms_Lib.Banana_Track;
