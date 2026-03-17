with Pace.Jobs;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Pace.Log;
with Str;
with Ada.Strings.Unbounded;

package body Uio.Pace_Jobs is

   use Str;

   package Asu renames Ada.Strings.Unbounded;

   type Jobs_To_Xml is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Jobs_To_Xml);

   procedure Get_Jobs_Data (Obj : in out Jobs_To_Xml) is
      use Pace.Jobs;
      use Job_Set_Pkg;
      use Pace.Server.Xml;
      Jobs_Set : Set;
      Iter : Cursor;
      J : Job;
   begin
      Pace.Jobs.Get_Jobs (Jobs_Set);
      Iter := First (Jobs_Set);
      while Iter /= No_Element loop
         J := Element (Iter);
         Append (Obj, Item ("job",
                            Item ("name", B2s (J.Unique_Id)) &
                            Item ("start_time", Integer (J.Start_Time)'Img) &
                            Item ("actual_start_time", Integer (J.Actual_Start_Time)'Img) &
                            Item ("expected_duration", Integer (J.Expected_Duration)'Img) &
                            Item ("status", J.Status'Img)));
         Next (Iter);
      end loop;
      Obj.Set := Asu.To_Unbounded_String (Item ("schedule",
                                                Item ("currenttime", Float (Pace.Now)) &
                                                Item ("jobs", Asu.To_String (Obj.Set))));
   end Get_Jobs_Data;

   procedure Inout (Obj : in out Jobs_To_Xml) is
      Default_Stylesheet : constant String := "/eng/schedule/jobs.xsl";
      use Pace.Server.Dispatch;
   begin
      Pace.Server.Xml.Put_Content (Default_Stylesheet);
      Get_Jobs_Data (Obj);
      Pace.Server.Put_Data (U2s (Obj.Set));
      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;
   type Is_Job_Executing is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Is_Job_Executing);
   procedure Inout (Obj : in out Is_Job_Executing) is
   begin
      Pace.Server.Xml.Put_Content;
      Obj.Set := S2u (Pace.Server.Xml.Item ("is_job_executing", Pace.Jobs.Is_Job_Executing'Img));
      Pace.Server.Put_Data (U2s (Obj.Set));
   end Inout;

begin
   Save_Action (Jobs_To_Xml'(Pace.Msg with Set => Xml_Set));
   Save_Action (Is_Job_Executing'(Pace.Msg with Set => Xml_Set));
end Uio.Pace_Jobs;
