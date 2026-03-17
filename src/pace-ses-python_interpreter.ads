with Python;

package Pace.Ses.Python_Interpreter is
   pragma Elaborate_Body;
   
   Interpreter_Error : exception;

   procedure Load (File : in String);

   -- Interpreter is a singleton per process

private

   type Interpreter is record
      Globals : Python.PyObject;  -- global symbols for the interpreter
   end record;

   procedure Initialize (Interp : in out Interpreter);

   function Run_Command -- Loads Command File
     (Interp  : in Interpreter;
      Command : in String;
      Name    : in String := "<stdin>")
      return    String;

   -- $Id: ses-python_interpreter.ads,v 1.2 2005/08/31 13:36:54 pukitepa Exp $
end Pace.Ses.Python_Interpreter;
