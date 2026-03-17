with Python.Ada;

with Ual.Utilities;
with Pace.Log;
with Pace.Server.Dispatch;

package body Pace.Ses.Python_Interpreter is
   use type Python.PyObject, Python.PyCodeObject;

   --  Initialize the interpreter. Only one such object can be created in the
   --  application, since there is only one shared python interpreter.  Raises
   --  Interpreter_Error if the interpreter couldn't be initialized
   procedure Initialize (Interp : in out Interpreter) is
      Setup_Cmd   : constant String  := "import sys" & ASCII.LF;
      Main_Module : Python.PyObject;
   begin
      Python.Py_Initialize_Interruptible;

      --  We need to set the program name, or some import commands will raise
      --  errors.   The Python pkg comments say to do this first!
      Python.Py_SetProgramName ("Python_Interpreter");

      if not Python.PyRun_SimpleString (Setup_Cmd) then
         raise Interpreter_Error;
      end if;

      Main_Module := Python.PyImport_AddModule ("__main__");
      if Main_Module = null then
         raise Interpreter_Error;
      end if;
      Interp.Globals := Python.PyModule_GetDict (Main_Module);

   end Initialize;

   -----------------
   -- Run_Command --
   -----------------
   --  Execute a command in the interpreter, and send its output to the
   --  console. Return its return value (which doesn't need to be Py_DECREF,
   --  since it is a borrowed reference).
   --  Errors is set to True if there was an error executing the command or
   --  if the input was incomplete.

   function Run_Command
     (Interp  : in Interpreter;
      Command : in String;
      Name    : in String := "<stdin>")
      return    String
   is
      Result, Builtin : Python.PyObject := null;
      Obj             : Python.PyObject;
      Code            : Python.PyCodeObject;
      Str             : Python.PyObject;
      Cmd             : constant String := Command & ASCII.LF;

   begin
      --  Reset previous output
      Builtin := Python.PyImport_ImportModule ("__builtin__");
      Python.PyObject_SetAttrString (Builtin, "_", Python.Py_None);

      Code := Python.Py_CompileString (Cmd, Name, Python.Py_File_Input);

      --  If code compiled just fine
      if Code /= null then

         Obj := Python.PyEval_EvalCode (Code, Interp.Globals, Interp.Globals);
         Python.Py_DECREF (Python.PyObject (Code));

         if Obj = null then
            Python.PyErr_Print;
            raise Interpreter_Error;
         else
            --  No other python command between this one and the previous
            --  call to PyEval_EvalCode
            if Python.PyObject_HasAttrString (Builtin, "_") then
               Result := Python.PyObject_GetAttrString (Builtin, "_");
            else
               Result := null;
            end if;
            Python.Py_DECREF (Obj);
         end if;

      --  Do we have compilation error because input was incomplete ?
      else
         raise Interpreter_Error;
      end if;

      if Result /= null then
         Str := Python.PyObject_Str (Result);
         Python.Py_DECREF (Result);
         declare
            S : constant String := Python.PyString_AsString (Str);
         begin
            Python.Py_DECREF (Str);
            return S;
         end;
      else
         Python.Py_XDECREF (Result);
         return "";
      end if;

   end Run_Command;

   Py : Interpreter;  -- Can only allow one instance

   Module    : Python.PyObject;
   Command   : constant String := "cbpace";
   User_Data : Python.PyObject := null;

   function CB_Function
     (Self   : Python.PyObject;
      Args   : Python.PyObject;
      Kwargs : Python.PyObject)
      return   Python.PyObject;
   pragma Convention (C, CB_Function);

   function CB_Function
     (Self   : Python.PyObject;
      Args   : Python.PyObject;
      Kwargs : Python.PyObject)
      return   Python.PyObject
   is
      -- Size : Integer := Python.PyTuple_Size (Args);
      Query : constant String := Python.PyString_AsString (Python.PyTuple_GetItem (Args, 0));
   begin
      --       Pace.Log.Put_Line ("Inside Ada calling 'CB_Function' Nargs=" & Size'Img);

      --       Pace.Log.Put_Line
      --         ("Inside Ada calling 'CB_Function'" &
      --          Python.PyString_AsString (Python.PyTuple_GetItem (Args, 0)));
      --       return Python.PyString_FromString ("<xml>100</xml>"); --Python.Py_None;
      return Python.PyString_FromString (Pace.Server.Dispatch.Dispatch_To_Action (Query));
   end CB_Function;

   procedure Init is
   begin
      Initialize (Py);
      Python.PySys_SetArgv;

      Module :=
         Python.Ada.Py_InitModule
           ("PACE",
            Doc => "Interface with the PACE environment");
      Python.Ada.Add_Function
        (Module => Module,
         Func   =>
            Python.Ada.Create_Method_Def
              (Command,
               CB_Function'Access),
         Self   => User_Data);

   exception
      when E : Interpreter_Error =>
         Pace.Log.Ex (E, "Python Interpreter_Error during Initializing");
      when E : others =>
         Pace.Log.Ex (E, "?");
   end Init;

   procedure Load (File : in String) is
      T : constant String := Ual.Utilities.File_To_String (File);
   begin
      Pace.Log.Put_Line ("[" & Run_Command (Py, T, File) & "]");
   exception
      when E : Interpreter_Error =>
         Pace.Log.Ex (E, "Python Interpreter_Error during Loading");
      when E : others =>
         Pace.Log.Ex (E);
   end Load;

begin
   Init;
   -- $Id: ses-python_interpreter.adb,v 1.5 2005/08/31 21:04:24 ludwiglj Exp $
end Pace.Ses.Python_Interpreter;
