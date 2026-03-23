with Ada.Strings.Unbounded;

package Pace.Rule_Process is
   ------------------------------------------------------------
   -- RULE_PROCESS -- Prolog inference engine in Ada
   ------------------------------------------------------------
   pragma Elaborate_Body;

   type Variables is array (Natural range <>) of
                       Ada.Strings.Unbounded.Unbounded_String;

   type Results_Display is access procedure (Str : in String); -- Raw output
   type Values_Display is access procedure (Key : in String;   -- Filtered
                                            Val : in String);  --  (key,val)

   type Allocation is
      record
         Clause, Hash, In_Toks, Out_Toks, Frames,
         Goals, Subgoals, Trail, Control : Integer;
      end record;

   Default : constant Allocation := (Clause => 1500,
                                     Hash => 600,
                                     In_Toks => 500,
                                     Out_Toks => 1000,
                                     Frames => 4000,
                                     Goals => 6000,
                                     Subgoals => 320,
                                     Trail => 5000,
                                     Control => 700);

   task type Agent_Type (Task_Stack_Size : Integer) is
      entry Init (Ini_File : in String;
                  Console : in Boolean;
                  Screen : in Boolean;
                  Ini : in Allocation := Default);
      entry Load (File : in String);
      entry Assert (Fact : in String);
      entry Query (Rule : in String; List : in out Variables);
      entry Query (Rule : in String; List : in Results_Display);
      entry Query (Rule : in String; List : in Values_Display);
      entry Parse (Rule : in String);
      entry Set_Post (Cb : in Results_Display);
      pragma Storage_Size (Task_Stack_Size);
   end Agent_Type;

   package Asu renames Ada.Strings.Unbounded;

   function "+" (S : String) return Asu.Unbounded_String
     renames Asu.To_Unbounded_String;
   function "+" (S : Asu.Unbounded_String) return String renames Asu.To_String;

--    function "=" (S : String) return Asu.Unbounded_String
--      renames Asu.To_Unbounded_String;
--    function "=" (S : Asu.Unbounded_String) return String renames Asu.To_String;


   -- This package uses the Token_Ouput of the parent which
   --   provides a uniform and regular pattern for presenting query results.

   function F (Name, Args : in String) return String; -- Functor = Name(Args)

   function S (Source : in Integer) return String; -- String Image
   function S (Source : in Float) return String;
   -- if Check_For_Quotes is true, the if Source already has quotes around it
   -- then just return Source without adding more quotes
   function Q (Source : in String; Check_For_Quotes : Boolean := False) return String;  -- Quoted ("") Image
   --
   -- Convert into strings and quoted strings

   function "+" (L, R : in String) return String;
   function "=" (L, R : in String) return String;
   --
   -- Concatenate args together

   No_Match : exception;

private

--X1804: CSC
-- **********************************
-- *                                *
-- *   Rule_Processor               *  SPEC
-- *                                *
-- **********************************
   generic
   package Rule_Processor is

--| Purpose
--| Rule_Processor provides the interface to outside applications.
--|
--| Initialization Exceptions (none)
--| Notes
--| This was written as a generic encapsulating the other packages but
--| not all compilers have sufficient memory.
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions

      --pragma Remote_Call_Interface;  -- In case we want to send over network


--X1804: CSC
-- **********************************
-- *                                *
-- *   Table_Sizes                  *  SPEC
-- *                                *
-- **********************************
      package Table_Sizes is

--| Purpose
--| Table_Sizes holds constants for the data arrays.
--| The constants are absolute maximums.  The allocation
--| record is the actual ammount allocated for the arrays.
--|
--| Initialization Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| November  7, 1991  PP            Added Integers
--| April 26, 1993     PP            Heap extensions
--| May 15, 1993       PP            Default values added
--| June 23, 1993      PP            Word_Length_Max to 128 from 75

---------------- Adaptation Data ------------------------
         Max : constant := 1_000_000;

         Clause_Length_Max : constant :=
           Max;    -- Maximum ASCII characters per clause
         Symbol_Hash_Max : constant := Max;      -- Size of Hash Table
         Word_Length_Max : constant :=
           10_000;   -- Maximum characters in a word symbol
         Tokens_Per_Clause : constant := Max;    -- Maximum tokens per clause
         Frame_Range_Max : constant := Max;      -- Size of the Copy Frame array 2000
         Goal_Stack_Max : constant := Max;       -- Size of Goal Stack
         Subgoals_Max : constant := Max / 100;     -- Size of SubGoal Stack
         Unif_Stack_Max : constant := Max;       -- Size of Trail or Unification Stack
         Conversion_Stack_Max : constant := 1000;-- Size of Conversion Stack
         Control_Stack_Max : constant :=
           Max;    -- Size of Environment or Control Stack

         subtype Integer_16 is Integer;
         subtype Integer_Ptr is Integer;
         subtype Floating_Point is Float;

---------------------------------------------------------

      end Table_Sizes;

      -- Symbol provides a format for a word from the symbol table
      subtype Symbol is String (1 .. Table_Sizes.Word_Length_Max);

--X1804: CSU
-- **********************************
-- *                                *
-- *   Load_Clause                  *  SPEC
-- *                                *
-- **********************************
      procedure Load_Clause (Input_String : in String);

--| Purpose
--| Load_Clause stores a string into a rulebase buffer for later interpretation.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Load_Clause                  *  SPEC
-- *                                *
-- **********************************
      procedure Load_Clause (Position : in Integer; Input_Char : in Character);

--| Purpose
--| Load_Clause stores a character into a rulebase buffer for later interpretation.
--| Position indicates the index position for storage.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions



--X1804: CSU
-- **********************************
-- *                                *
-- *   Interpret                    *  SPEC
-- *                                *
-- **********************************
      function Interpret (Token_Input : in Boolean := False;
                          Lisp_Syntax : in Boolean := True;
                          Do_Tro : in Boolean := True;
                          Clauses : in Integer := 0;
                          Clause1 : in String := "";
                          Clause2 : in String := "") return Boolean;

--| Purpose
--| Interpret processes the incoming clause according to the following
--| identities (i.e. identity -> process) :
--|         Token_Input = FALSE -> String Input from Clauses = 0,1,2.
--|         Token_Input = TRUE  -> Token Input from Symbol Input procedures.
--|         Do_TRO      = TRUE  -> Does Tail Recursion and Cut optimization.
--|         Lisp_Syntax = TRUE  -> Prefix format (this is faster).
--|         Lisp_Syntax = FALSE -> Prolog format.
--|         Clauses = 0         -> String Input from Load_Clause.
--|         Clauses = 1 (and 2) -> String Input from Clause1 ( and Clause2 ).
--| If the input clause is a query, then it will be processed as such
--| and will return TRUE if the query's goal is satisfied and FALSE otherwise.
--| If the input clause is a fact, the return is not important.
--| Clauses = 1 or 2 are used for inputting primary and secondary queries
--| when progressive reasoning is needed.
--|
--| Exceptions
--| See details in code.
--|
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Initialize                   *  SPEC
-- *                                *
-- **********************************
      procedure Initialize (Sizes : Allocation); --PP := Table_Sizes.Default );

--| Purpose
--| Initialize clears and initializes all symbol tables, stacks, and arrays.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions
--| May 15, 1993       PP            Added Initial_Values


--X1804: CSU
-- **********************************
-- *                                *
-- *   Start_Fact_Input             *  SPEC
-- *                                *
-- **********************************
      procedure Start_Fact_Input (Query : in Boolean := False);

--| Purpose
--| Start_Fact_Input readies the rule processor for token by token input.
--| The Input procedures convert known symbol types directly to the symbol
--| table and tokens, thus bypassing the lexical analysis.
--| Example :  The fact  "data(1)."  is generated by
--|            Start_Fact_Input;
--|            Input_Functor ( "data" );
--|            Input_Integer ( 1 );
--|            End_Fact_Input;
--|
--| Example :  The query  " data(X)? "  is generated by
--|            Start_Fact_Input ( Query => TRUE );
--|            Input_Functor ( "data" );
--|            Input_Variable ( X );
--|            End_Fact_Input;
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| October  20, 1991  PP            Added default input Query := FALSE
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Input_Functor                *  SPEC
-- *                                *
-- **********************************
      procedure Input_Functor (Input_String : in String);

--| Purpose
--| Input_Functor loads a functor (symbol with argument '(' placeholders) into
--| the symbol table and input clause.  A list uses an "[" as input functor.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions



--X1804: CSU
-- **********************************
-- *                                *
-- *   End_Functor                  *  SPEC
-- *                                *
-- **********************************
      procedure End_Functor;

--| Purpose
--| End_Functor puts a ')' into the input clause.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Input_Integer                *  SPEC
-- *                                *
-- **********************************
      procedure Input_Integer (Value : in Integer);

--| Purpose
--| Input_Integer places an integer into the numeric data and input clause.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Input_Float                  *  SPEC
-- *                                *
-- **********************************
      procedure Input_Float (Value : in Float);

--| Purpose
--| Input_Float places a float into the numeric data and input clause.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions



--X1804: CSU
-- **********************************
-- *                                *
-- *   Input_Symbol                 *  SPEC
-- *                                *
-- **********************************
      procedure Input_Symbol (Input_String : in String);

--| Purpose
--| Input_Symbol loads a symbol into the symbol table (if not already there)
--| and adds it to the input clause.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Input_Variable               *  SPEC
-- *                                *
-- **********************************
      procedure Input_Variable (Input_String : in String);

--| Purpose
--| Input_Variable loads a variable symbol (capitalized symbol) into the
--| symbol table (if not already there) and adds it to the input clause.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| December 8, 1992  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions



--X1804: CSU
-- **********************************
-- *                                *
-- *   End_Fact_Input               *  SPEC
-- *                                *
-- **********************************
      procedure End_Fact_Input;

--| Purpose
--| End_Fact_Input places an end of clause token in the input clause.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Start_Token_Get              *  SPEC
-- *                                *
-- **********************************
      procedure Start_Token_Get;

--| Purpose
--| Start_Token_Get sets the output token array to its starting point.
--| Get procedures are used to retrieve data from the internal storage
--| after a successful query.  The tokens are accessed in sequential order
--| starting at the beginning of the output token table.
--| Example :  The results for query " goal(Number,Symbol)? " return as
--|            Start_Token_Get;
--|            Get_Integer ( Value );
--|            Get_Symbol_String ( Str, Last );
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Get_Integer                  *  SPEC
-- *                                *
-- **********************************
      procedure Get_Integer (Value : out Integer);

--| Purpose
--| Get_Integer returns the integer corresponding to the current index
--| in the output token array.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Get_Float                    *  SPEC
-- *                                *
-- **********************************
      procedure Get_Float (Value : out Float);

--| Purpose
--| Get_Float returns the float corresponding to the current index
--| in the output token array.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Get_Symbol_String            *  SPEC
-- *                                *
-- **********************************
      procedure Get_Symbol_String
                  (Output_String : out String; Last : out Integer);

--| Purpose
--| Get_Symbol_String returns the string corresponding to the current index
--| in the output token array.  Last returns the length of the string.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| September 8, 1991  Paul Pukite   Initial Version
--| April 26, 1993     PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Get_Integer_List             *  SPEC
-- *                                *
-- **********************************
      procedure Get_Integer_List (Value : out Integer);

--| Purpose
--| Get_Integer_List returns the integer corresponding to the current index
--| in the output token array without skipping the NIL terminator.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| October 18, 1991  Paul Pukite   Initial Version
--| April 26, 1993    PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Get_Float_List               *  SPEC
-- *                                *
-- **********************************
      procedure Get_Float_List (Value : out Float);

--| Purpose
--| Get_Integer_List returns the integer corresponding to the current index
--| in the output token array without skipping the NIL terminator.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| October 18, 1991  Paul Pukite   Initial Version
--| April 26, 1993    PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Get_Symbol_String_List       *  SPEC
-- *                                *
-- **********************************
      procedure Get_Symbol_String_List
                  (Output_String : out String; Last : out Integer);

--| Purpose
--| Get_Symbol_String returns the string corresponding to the current
--| index in the output token array without skipping the NIL terminator.
--| Last returns the length of the string.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| October 18, 1991  Paul Pukite   Initial Version
--| April 26, 1993    PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Is_End_List                  *  SPEC
-- *                                *
-- **********************************
      function Is_End_List return Boolean;

--| Purpose
--| Determines whether list of symbols is ended.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| October 18, 1991  Paul Pukite   Initial Version
--| April 26, 1993    PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *   Stop                         *  SPEC
-- *                                *
-- **********************************
      procedure Stop;

--| Purpose
--| Stops all tasks within rule processor.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| October 18, 1991  Paul Pukite   Initial Version
--| April 26, 1993    PP            Heap extensions


--X1804: CSU
-- **********************************
-- *                                *
-- *  Multiple                      *  SPEC
-- *                                *
-- **********************************
      procedure Multiple;

--| Purpose
--| Obtain multiple solutions.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| April 26, 1993    Paul Pukite    Initial Version


--X1804: CSU
-- **********************************
-- *                                *
-- *  Only_One                      *  SPEC
-- *                                *
-- **********************************
      procedure Only_One;

--| Purpose
--| Get only one solution.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| April 26, 1993    Paul Pukite    Initial Version

--X1804: CSC
-- **********************************
-- *                                *
-- *  Load                          *  SPEC
-- *                                *
-- **********************************
      function Load (File : in String;
                     Lisp : in Boolean := False;
                     Tro : in Boolean := True) return Boolean;

--| Purpose
--| Load a rulebase from a file and interpret. if Lisp is FALSE
--| use Prolog syntax.  Tail recursion is on if TRO is TRUE.
--| If File is "" then user console mode is invoked. Escape with ^Z.
--|
--| Exceptions (none)
--| Notes
--|
--| Modifications
--| April 26, 1993    Paul Pukite    Initial Version
--| May 29, 1993      PP             Exception for name added outside loop


-------------------------------------------------------------------------
-------------------------------------------------------------------------

      --
      -- Main procedure for starting up the rule processor
      --
      procedure Aes (Ini_File : in String := "";
                     Console : in Boolean := True;
                     Screen : in Boolean := True;
                     Ini : in Allocation := Default);

      --
      -- Attaching a display
      --
      type Write_Proc is access procedure (Str : in String);
      procedure Set_Write (Proc : Write_Proc);
      procedure Set_Post (Proc : Write_Proc);

      --
      -- Iterating on Token Output, only returns string representations
      --
      procedure Iterate (Output_String : out String; Last : out Integer);
      -- If Last = 0 then end of a sub-list
      procedure Reset_Iterator;

      --------------------------------------------------
      -- A pattern-matched set for flat functor/args
      --------------------------------------------------

      procedure Match
                  (Functor : in String;
                   Vars : in out Variables; -- Unbound are Null_Bounded_String
                   Terminal : in Character := '?');

      function Parse (Functor, Args : in String; Terminal : in Character := '?')
                     return Boolean;
      function Parse (Query : in String; Terminal : in Character := '?')
                     return Boolean;

   end Rule_Processor;

------------------------------------------------------------------------------
-- $id: gnu-rule_process.ads,v 1.3 10/27/03 16:29:13 peterswk Exp $
------------------------------------------------------------------------------
end Pace.Rule_Process;
