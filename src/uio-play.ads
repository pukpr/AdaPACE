with Gkb.Database;
generic
   Path_Key : in String;
   with package Db is new Gkb.Database (<>);
   File : in String := Db.Get (Path_Key); 
procedure UIO.Play;
