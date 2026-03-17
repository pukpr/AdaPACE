with Interfaces;

package HLA.Articulation is

   type Articulated_Part_Type is private;
   type Articulated_Parameter is private;

private

   type Articulated_Kind is (Invalid, Main_Gun, Small_Gun, Turret, Cupola, Mast);
   type Station_Type is new Natural;
   type Parameter_Type is (Articulated_Part, Attached_Part);
   
   type Quaternion is
     record
        W,X,Y,Z : Long_Float;
     end record;

   type Relative_Position is
     record
        X,Y,Z : Long_Float;
     end record;
   
   type Articulated_Part_Type is 
     record
        Part_Class : Long_Integer;
        Orientation_To_Attachment : Quaternion;
        Location_To_Attachment : Relative_Position;
        Kind : Articulated_Kind;
     end record;

   type Store_Type is
     record
        Entity_Kind, Domain, Country_Code, Category, Subcategory, Specific, Extra
          : Long_Integer;
     end record;

   type Attached_Part_Type is 
     record
        Station : Station_Type;
        Store : Store_Type;
     end record;

   type Parameter_Value_Struct is 
     record
        Articulated_Parameter : Parameter_Type; -- picks articulated vs. attached?
        Articulated_Parts : Articulated_Part_Type;
        Attached_Parts : Attached_Part_Type;
     end record;

   type Articulated_Parameter is -- needed multi-layer structure
     record
        Articulated_Parameter_Change : Long_Integer;
        Part_Attached_To : Interfaces.Unsigned_8;
        Parameter_Value : Parameter_Value_Struct;
     end record;

end;
