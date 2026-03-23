with Text_IO;
with Ada.Integer_Text_IO;
with Ada.Float_Text_IO;
with Unchecked_Deallocation;
with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Environment_Variables;
with Ada.Exceptions;

package body Pace.Rule_Process is

   function Getenv (Name : in String; Default : in String) return String is
   begin
      if Ada.Environment_Variables.Exists (Name) then
         return Ada.Environment_Variables.Value (Name);
      else
         return Default;
      end if;
   end Getenv;

   function F (Name, Args : in String) return String is
   begin
      return Name & "(" & Args & ")";
   end F;

   function S (Source : in Integer) return String is
      Str : constant String := Integer'Image (Source);
   begin
      return Ada.Strings.Fixed.Trim (Str, Ada.Strings.Left);
   end S;

   function S (Source : in Float) return String is
      Str : String (1 .. 100);
      S   : constant String := Float'Image (Source);
   begin
      Ada.Float_Text_IO.Put (Str, Source, 6, 0);
      return Ada.Strings.Fixed.Trim (Str, Ada.Strings.Left);
   exception
      when Text_IO.Layout_Error =>
         return Ada.Strings.Fixed.Trim (S, Ada.Strings.Left);
   end S;

   function Q
     (Source           : in String;
      Check_For_Quotes : Boolean := False)
      return             String
   is
   begin
      if Check_For_Quotes then
         if Source (Source'First) = '"' and Source (Source'Last) = '"' then
            return Source;
         end if;
      end if;
      return '"' & Source & '"';
   end Q;

   function "+" (L, R : in String) return String is
   begin
      return L & ", " & R;
   end "+";

   function "+"
     (L, R : in Asu.Unbounded_String)
      return Asu.Unbounded_String
   is
      use Ada.Strings.Unbounded;
   begin
      if L = Null_Unbounded_String then
         return R;
      else
         return L & ", " & R;
      end if;
   end "+";

   function "=" (L, R : in String) return String is
   begin
      return L & "=" & R;
   end "=";

   function "="
     (L, R : in Asu.Unbounded_String)
      return Asu.Unbounded_String
   is
      use Ada.Strings.Unbounded;
   begin
      if L = Null_Unbounded_String then
         return R;
      else
         return L & "=" & R;
      end if;
   end "=";

   --X1804: CSC
   -- **********************************
   -- *                                *
   -- *   Rule_Processor               *  BODY
   -- *                                *
   -- **********************************
   package body Rule_Processor is

      --| Purpose
      --| Package body for Rule_Processor
      --|
      --| Exceptions
      --|
      --| Notes
      --| Rule_Processor provides the interface to outside applications.
      --|
      --| Modifications
      --| October 25, 1991  Paul Pukite  Initial Version
      --| April 26, 1993    PP           Heap extensions

      package Iio renames Ada.Integer_Text_IO;
      package Fio renames Ada.Float_Text_IO;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Rule_Errors                  *  SPEC
      -- *                                *
      -- **********************************
      package Rule_Errors is

         --| Purpose
         --| Rule_Errors provides exceptions and stopping conditions for the
         --| rule processor.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         -- ----------------------------------------------------------------
         --  The following exceptions are raised within the Expert System
         --  The Interpret procedure handles all of the exceptions.
         -- ----------------------------------------------------------------

         Symbol_Table_Error,           --  Too many symbols in symbol table
           Variable_Table_Error,         --  Too many variables
           Numeric_Table_Error,          --  Too many integers
           Lex_Error,                    --  Error during lexical analysis
           Prefix_Error,                 --  Error in conversion to prefix
           Clist_Error,                  --  Error in updating clause list
           Parse_Error,                  --  Conversion stack overflow
           Lost_Track_Variable_Error,    --  In Unification
           Builtin_Error,                --  Unknown builtin function
           Unbound_Variable_Error,       --  X := Y error where Y is not bound
           Nonnumeric_Error,             --  X := 2 + q type error
           Evaluate_Error,               --  Unexpected arithmetic operator
           Compute_Error,                --  Uncomputable Right Hand Side
           Unbound_Relation_Error,       --  X < Y error where Y is not bound
           Relation_Error,               --  Unexpected relational operator
           Variable_Overwrite_Error,     --  In Verify
           Garbage_Collection_Error,      --  Error in Linked_List Garbage
                                          --Collection
           Inferences_Error,             --  Too many inferences
           Unifications_Error,           --  Too many unifications
           Control_Stack_Error,          --  Exceeded the control stack
           Frame_Error,                   --  Access beyond Frame_Range in
                                          --Verify
           Unify_Stack_Error,             --  Unification stack overflow (
                                          --large list )
           Goal_Stack_Error,             --  Goal stack overflow
           Output_Error,                 --  Too many output tokens
           Links_Error,                  --  Too many clause links
           Timeout_Error,                --  Externally timed out
           Stop_Error : exception;       --  Externally stopped

         subtype Count is Long_Integer;   -- This is changed to INTEGER for VAX

         type External_Control_Flag is (None, Stop, Timeout);

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Set_Condition                *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Condition (Flag : in External_Control_Flag);

         --| Purpose
         --| Set_Condition enables external override control of the Expert
         --System.
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
         -- *   Check_Condition              *  SPEC
         -- *                                *
         -- **********************************
         procedure Check_Condition
           (Inferences   : in Count := 0;
            Unifications : in Count := 0);

         --| Purpose
         --| Check_Condition raises exceptions due to external control
         --| directives of Stop and Timeout, and also runaway conditions from
         --| too many inferences and unifications.
         --|
         --| Exceptions
         --| STOP_ERROR if externally stopped.
         --| TIMEOUT_ERROR if externally timed out.
         --| INFERENCES_ERROR if too many inferences.
         --| UNIFICATIONS_ERROR if too many unifications.
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| October  24, 1991  PP            Changed LONG_INTEGER to Count
         --| April 26, 1993     PP            Heap extensions

      end Rule_Errors;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Lexical_Analysis             *  SPEC
      -- *                                *
      -- **********************************
      package Lexical_Analysis is

         --| Purpose
         --| Lexical_Analysis sets up tables and parses incoming clauses to
         --| their underlying token (i.e. Goal) values.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions
         --| June 23, 1993      PP            Adde Word_Length_Max to
         --Max_String (was 100)

         type Contents is (
            Int, -- integer token
            Var, -- variable
            Sym, -- atomic symbol
            Lis, -- list
            Any, -- wild card
            Bip, -- built-in
            Flt  -- float
           );

         type Goal_Value;
         type Goal_Value_Record (Content : Contents := Any) is private;
         type Goal_Value is access Goal_Value_Record;

         subtype Builtin_Range is Table_Sizes.Integer_Ptr range 1 .. 75;

         subtype Max_String is Integer range 0 .. Table_Sizes.Word_Length_Max;
         type Symbol_Record (Length : Max_String) is private;
         type Symbol_String is access Symbol_Record;

         type Instance_Record is private;
         type Instance is access Instance_Record;

         type Token_Range is new Table_Sizes.Integer_Ptr range
            0 .. Table_Sizes.Tokens_Per_Clause - 1;

         type Token_Array is array (Token_Range range <>) of Goal_Value;
         type Token_Access is access Token_Array;
         Lex_Table    : Token_Access;  -- temporary place to hold tokens
         Lex_Position : Token_Range;   -- position within Lex_Table
         First_Token  : constant Token_Range := Token_Range'First;

         subtype Clause_String_Range is Integer range
            1 .. Table_Sizes.Clause_Length_Max;
         --  maximum number of characters per clause

         type Str is access String;
         Clause_String : Str; -- String(Clause_String_Range); -- holds current
                              --clause

         --  Area for hashing symbols
         subtype Symbol_Hash_Table_Range is Table_Sizes.Integer_Ptr range
            0 .. Table_Sizes.Symbol_Hash_Max - 1;

         subtype Calc_Int is Table_Sizes.Integer_16;
         -- Integer for storage and calculations on expressions.

         subtype Calc_Flt is Table_Sizes.Floating_Point;
         -- Floating point for storage and calculations on expressions.

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Goals               *  SPEC
         -- *                                *
         -- **********************************
         function Number_Of_Goals return Rule_Errors.Count;

         --| Purpose
         --| Return the number of goals or stored tokens.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Symbols             *  SPEC
         -- *                                *
         -- **********************************
         function Number_Of_Symbols return Rule_Errors.Count;

         --| Purpose
         --| Return the number of stored string symbols.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Numeric                   *  SPEC
         -- *                                *
         -- **********************************
         function Is_Numeric (Token : in Goal_Value) return Boolean;
         --   pragma INLINE ( Is_Numeric );

         --| Purpose
         --| Is_Numeric determines whether a token is an integer (e.g. 10).
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Variable                  *  SPEC
         -- *                                *
         -- **********************************
         function Is_Variable (Token : in Goal_Value) return Boolean;
         --   pragma INLINE ( Is_Variable );

         --| Purpose
         --| Is_Variable determines whether a token is a variable (e.g. X).
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Atomic                    *  SPEC
         -- *                                *
         -- **********************************
         function Is_Atomic (Token : in Goal_Value) return Boolean;
         --   pragma INLINE ( Is_Atomic );

         --| Purpose
         --| Is_Atomic determines whether a token is a static symbol (e.g.
         --'blue').
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Nil                       *  SPEC
         -- *                                *
         -- **********************************
         function Is_Nil (Token : in Goal_Value) return Boolean;
         --   pragma INLINE ( Is_Nil );

         --| Purpose
         --| Is_Nil determines if a token is unassigned.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Goal                      *  SPEC
         -- *                                *
         -- **********************************
         function Is_Goal (Token : in Goal_Value) return Boolean;
         --   pragma INLINE ( Is_Goal );

         --| Purpose
         --| Is_Goal determines whether a token has been assigned a goal.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_List                      *  SPEC
         -- *                                *
         -- **********************************
         function Is_List (Token : in Goal_Value) return Boolean;
         --   pragma INLINE ( Is_List );

         --| Purpose
         --| Is_List determines whether a token is assigned to a list.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Token                     *  SPEC
         -- *                                *
         -- **********************************
         function Is_Token (Token : in Goal_Value) return Boolean;
         --   pragma INLINE ( Is_Token );

         --| Purpose
         --| Is_Token determines if a token has been assigned a goal that
         --| is not a list (i.e. a tokenized variable, symbol, or integer).
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Clear_Table                  *  SPEC
         -- *                                *
         -- **********************************
         procedure Clear_Table;

         --| Purpose
         --| Clear_Table clears the Lex_Table
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
         -- *   Tokenize                     *  SPEC
         -- *                                *
         -- **********************************
         procedure Tokenize (Token_Input : in Boolean);

         --| Purpose
         --| Tokenize parses a clause (Clause_String) into an array of
         --| tokens residing in Lex_Table.
         --|
         --| Exceptions
         --| LEX_ERROR if Lex_Table becomes full.
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| October  20, 1991  PP            Added Token_Input conditional
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Add_Integer                  *  SPEC
         -- *                                *
         -- **********************************
         function Add_Integer (Number : in Calc_Int) return Goal_Value;

         --| Purpose
         --| Add_Integer adds an integer value (type Calc_Int) to the list.
         --|
         --| Exceptions
         --| NUMERIC_TABLE_ERROR if the table overflows.
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Add_Float                     *  SPEC
         -- *                                *
         -- **********************************
         function Add_Float (Number : in Calc_Flt) return Goal_Value;

         --| Purpose
         --| Add_Float adds a floating point value to the list.
         --|
         --| Exceptions
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Add_Word                     *  SPEC
         -- *                                *
         -- **********************************
         function Add_Word
           (Str    : in String;
            Symbol : in Boolean := True)
            return   Symbol_String;

         --| Purpose
         --| Initiate a search to insert a word into the symbol table.
         --| Return an object describing the string.  If Symbol=TRUE, then
         --ignore
         --| search and just store.
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| November10, 1991  PP           Changed to string input
         --| April 26, 1993    PP           Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Insert_Variable              *  SPEC
         -- *                                *
         -- **********************************
         function Insert_Variable
           (Variable : in Symbol_String)
            return     Goal_Value;

         --| Purpose.
         --| Insert a variable into the variable table.
         --|
         --| Exceptions
         --| Notes
         --|
         --| Modifications
         --| October 20, 1991  Paul Pukite   Initial Version
         --| April 26, 1993    PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Variable                 *  SPEC
         -- *                                *
         -- **********************************
         function Make_Variable (Variable : in Instance) return Goal_Value;

         --| Purpose
         --| Make a variable instance token.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Builtin                  *  SPEC
         -- *                                *
         -- **********************************
         function Make_Builtin
           (Predicate : in Builtin_Range)
            return      Goal_Value;

         --| Purpose
         --| Make a builtin token.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Atom                     *  SPEC
         -- *                                *
         -- **********************************
         function Make_Atom (Symbol : in Symbol_String) return Goal_Value;

         --| Purpose
         --| Make an atomic symbol token.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Symbol                   *  SPEC
         -- *                                *
         -- **********************************
         function Make_Symbol (Str : in String) return Symbol_String;

         --| Purpose
         --| Create a symbol string.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Purge_Query                  *  SPEC
         -- *                                *
         -- **********************************
         procedure Purge_Query (Query : in Goal_Value);

         --| Purpose
         --| Purge_Query removes a query from the linked list. NOT IMPLEMENTED.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Push_Lex                     *  SPEC
         -- *                                *
         -- **********************************
         procedure Push_Lex (Token : in Goal_Value);

         --| Purpose
         --| Push_Lex adds a token to the lex table.
         --|
         --| Exceptions
         --| LEX_ERROR if storage exceeded
         --|
         --| Notes
         --|
         --| Modifications
         --| November 9, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Initialize_Lex               *  SPEC
         -- *                                *
         -- **********************************
         procedure Initialize_Lex
           (In_Toks : in Token_Range;
            Hash    : in Symbol_Hash_Table_Range);

         --| Purpose
         --| Initialize_Lex clears all symbol tables and resets pointers and
         --indices.
         --| It also hashes predefined keywords.  Input parameters are ranges
         --allowed.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions
         --| May 15, 1993       PP            In_Toks (per clause), Hash
         --(table size)

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Mark_Cell                     *  SPEC
         -- *                                *
         -- **********************************
         procedure Mark_Cell (Gv : in Goal_Value);

         --| Purpose
         --| Mark a token GV for garbage collection.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Marked                     *  SPEC
         -- *                                *
         -- **********************************
         function Is_Marked (Gv : Goal_Value) return Boolean;

         --| Purpose
         --| Is token GV marked for garbage collection?
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Builtin_Token              *  SPEC
         -- *                                *
         -- **********************************
         function Is_Builtin_Token
           (Gv    : in Goal_Value;
            Token : in Builtin_Range)
            return  Boolean;

         --| Purpose
         --| Is GV a builtin of type Token?
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Builtin                    *  SPEC
         -- *                                *
         -- **********************************
         function Is_Builtin (Gv : in Goal_Value) return Boolean;

         --| Purpose
         --| Is GV a builtin?
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  NIL                           *  SPEC
         -- *                                *
         -- **********************************
         function Nil return Goal_Value;

         --| Purpose
         --| Return a NIL token.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Wild_Card                     *  SPEC
         -- *                                *
         -- **********************************
         function Wild_Card return Goal_Value;

         --| Purpose
         --| Return a wild-card token.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Next_Var                  *  SPEC
         -- *                                *
         -- **********************************
         function Get_Next_Var (Gv : in Goal_Value) return Goal_Value;

         --| Purpose
         --| Get next variable in a clause.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Prev_Var                  *  SPEC
         -- *                                *
         -- **********************************
         function Get_Prev_Var (Gv : in Goal_Value) return Goal_Value;

         --| Purpose
         --| Get previous variable in a clause.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_BIP                       *  SPEC
         -- *                                *
         -- **********************************
         function Get_Bip (Gv : in Goal_Value) return Builtin_Range;

         --| Purpose
         --| Get builtin index corresponding to token GV.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Int                       *  SPEC
         -- *                                *
         -- **********************************
         function Get_Int (Gv : in Goal_Value) return Calc_Int;

         --| Purpose
         --| Get the integer representation of token GV.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Flt                       *  SPEC
         -- *                                *
         -- **********************************
         function Get_Flt (Gv : in Goal_Value) return Calc_Flt;

         --| Purpose
         --| Get the float representation of token GV.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Sym                       *  SPEC
         -- *                                *
         -- **********************************
         function Get_Sym (Gv : in Goal_Value) return String;

         --| Purpose
         --| Get the string representation of atomic token GV.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Next_Link                     *  SPEC
         -- *                                *
         -- **********************************
         function Next_Link (Gv : Goal_Value) return Goal_Value;

         --| Purpose
         --| Get the next token linked to GV.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Delete_Link                   *  SPEC
         -- *                                *
         -- **********************************
         procedure Delete_Link (Gv : in out Goal_Value);

         --| Purpose
         --| Delete the token GV.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Link                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Link (Gv : in out Goal_Value; Next : in Goal_Value);

         --| Purpose
         --| Set GV's link to Next.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Float                      *  SPEC
         -- *                                *
         -- **********************************
         function Is_Float (Token : in Goal_Value) return Boolean;

         --| Purpose
         --| Is the Token a float?
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Integer                    *  SPEC
         -- *                                *
         -- **********************************
         function Is_Integer (Token : in Goal_Value) return Boolean;

         --| Purpose
         --| Is the token an integer?
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Same                          *  SPEC
         -- *                                *
         -- **********************************
         function Same (L1, L2 : in Goal_Value) return Boolean;

         --| Purpose
         --| Are the goals L1 and L2 identical?
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   CAR                          *  SPEC
         -- *                                *
         -- **********************************
         function Car (Pointer : in Goal_Value) return Goal_Value;
         --   pragma INLINE ( CAR );

         --| Purpose
         --| CAR returns the 1st field of a Lisp pair.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   CDR                          *  SPEC
         -- *                                *
         -- **********************************
         function Cdr (Pointer : in Goal_Value) return Goal_Value;
         --   pragma INLINE ( CDR );

         --| Purpose
         --| CDR returns the second (i.e. Rest) field of a Lisp pair.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Set_CAR_CDR                  *  SPEC
         -- *                                *
         -- **********************************
         function Set_Car_Cdr
           (Car_Value, Cdr_Value : in Goal_Value)
            return                 Goal_Value;

         --| Purpose
         --| SET_CAR_CDR sets the CAR and CDR for a LISP-like cell and updates
         --the linked list pointer.
         --|
         --| Exceptions
         --| LINKS_ERROR if linked list out of memory.
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Set_CAR                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Car
           (Pointer   : in out Goal_Value;
            Car_Value : in Goal_Value);
         --   pragma INLINE ( Set_CAR );

         --| Purpose
         --| Set_CAR sets the CAR of a cell.
         --|
         --| Exceptions
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Set_CDR                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Cdr
           (Pointer   : in out Goal_Value;
            Cdr_Value : in Goal_Value);
         --   pragma INLINE ( Set_CDR );

         --| Purpose
         --| Set_CDR sets the CDR of a cell.
         --|
         --| Exceptions
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   CAAR_CADR_CDDR_CAADR_CADDR   *  SPEC
         -- *                                *
         -- **********************************
         function Caar (Ptr : in Goal_Value) return Goal_Value;
         function Cadr (Ptr : in Goal_Value) return Goal_Value;
         function Cddr (Ptr : in Goal_Value) return Goal_Value;
         function Caadr (Ptr : in Goal_Value) return Goal_Value;
         function Caddr (Ptr : in Goal_Value) return Goal_Value;

         --| Purpose
         --| CAAR,CADR,CDDR,CAADR,CADDR are combinations of CAR and CDR
         --functions.
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
         -- *   Get_Variable                 *  SPEC
         -- *                                *
         -- **********************************
         function Get_Variable (Gv : in Goal_Value) return Instance;

         --| Purpose
         --| Get_Variable gets the variable instance of a goal.
         --|
         --| Exceptions
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| August 6, 1993     PP            Initial Version

      private

         type Goal_Value_Record (Content : Contents := Any) is record
            Mark : Boolean;
            Link : Goal_Value;
            case Content is
               when Int =>
                  Number : Calc_Int;
               when Flt =>
                  Fvalue : Calc_Flt;
               when Var =>
                  Variable : Instance;
               when Bip =>
                  Builtin : Builtin_Range;
               when Sym =>
                  Symbol : Symbol_String;
               when Lis =>
                  First : Goal_Value;
                  Next  : Goal_Value;
               when others =>
                  null;
            end case;
         end record;

         type Instance_Record is record
            Symbol   : Symbol_String;
            Previous : Goal_Value;
            Forward  : Goal_Value;
            Refs     : Table_Sizes.Integer_16;
         end record;

         type Symbol_Record (Length : Max_String) is record
            Refs : Table_Sizes.Integer_16;
            Str  : String (1 .. Length);
         end record;

      end Lexical_Analysis;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Linked_List                  *  SPEC
      -- *                                *
      -- **********************************
      package Linked_List is

         --| Purpose
         --| Linked_List creates goal links and does garbage collection.
         --| List type functions are defined.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions
         --| August 6, 1993     PP            Removed unneeded external objects

         package Lex renames Lexical_Analysis;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Clause_List                   *  SPEC
         -- *                                *
         -- **********************************
         function Clause_List return Lex.Goal_Value;
         --   pragma INLINE ( Clause_List );

         --| Purpose
         --| Global starting point to all clauses, these are indexed by
         --functor.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Collect                   *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Collect;

         --| Purpose
         --| Set a variable signaling whether GC has to be done.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Links               *  SPEC
         -- *                                *
         -- **********************************
         function Number_Of_Links return Rule_Errors.Count;

         --| Purpose
         --| The count of storage links used at any time.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Update_Clause_List           *  SPEC
         -- *                                *
         -- **********************************
         procedure Update_Clause_List (Clause : in Lex.Goal_Value);

         --| Purpose
         --| Update_Clause_List adds a new clause to the list of clauses to be
         --proved.
         --|
         --| Exceptions
         --| CLIST_ERROR if links overflow.
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Clean_Clause_List            *  SPEC
         -- *                                *
         -- **********************************
         procedure Clean_Clause_List (Clause : in Lex.Goal_Value);

         --| Purpose
         --| Removes the clause's associated clauses.
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
         -- *   Purge_Clause                 *  SPEC
         -- *                                *
         -- **********************************
         procedure Purge_Clause (Clause : in Lex.Goal_Value);

         --| Purpose
         --| Purge_Clause sets the clause pointers to NIL.
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
         -- *   Convert                      *  SPEC
         -- *                                *
         -- **********************************
         function Convert return Lex.Goal_Value;

         --| Purpose
         --| Convert creates a linked list based on Prefix array Lextab.
         --| Returns current clause.
         --|
         --| Exceptions
         --| PARSE_ERROR if conversion stack is blown.
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Associated_List              *  SPEC
         -- *                                *
         -- **********************************
         function Associated_List
           (List, Index_Item : in Lex.Goal_Value)
            return             Lex.Goal_Value;

         --| Purpose
         --| Associated_List finds the list associated with an index item.
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
         -- *   Set_CAR_CDR                  *  SPEC
         -- *                                *
         -- **********************************
         function Set_Car_Cdr
           (Car_Value, Cdr_Value : in Lex.Goal_Value)
            return                 Lex.Goal_Value;

         --| Purpose
         --| SET_CAR_CDR sets the CAR and CDR for a LISP-like cell and updates
         --the linked list pointer.
         --|
         --| Exceptions
         --| LINKS_ERROR if linked list out of memory.
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Construct                    *  SPEC
         -- *                                *
         -- **********************************
         procedure Construct (List, Item : in Lex.Goal_Value);

         --| Purpose
         --| Construct attaches an object to the end of a list.
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
         -- *   Set_CAR                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Car
           (Pointer   : in Lex.Goal_Value;
            Car_Value : in Lex.Goal_Value);
         --   pragma INLINE ( Set_CAR );

         --| Purpose
         --| Set_CAR sets the CAR of a cell.
         --|
         --| Exceptions
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Set_CDR                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Cdr
           (Pointer   : in Lex.Goal_Value;
            Cdr_Value : in Lex.Goal_Value);
         --   pragma INLINE ( Set_CDR );

         --| Purpose
         --| Set_CDR sets the CDR of a cell.
         --|
         --| Exceptions
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Garbage_Collect              *  SPEC
         -- *                                *
         -- **********************************
         procedure Garbage_Collect;

         --| Purpose
         --| Removes inactive links (such as queries, etc.) from linked list.
         --|
         --| Exceptions
         --| Notes
         --| Contains recursive calls.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Find_Principal_ID            *  SPEC
         -- *                                *
         -- **********************************
         function Find_Principal_Id
           (Token : in Lex.Goal_Value)
            return  Lex.Goal_Value;

         --| Purpose
         --| Find_Principle_ID finds the principal identifier in a clause.
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
         -- *   Is_Evaluated                 *  SPEC
         -- *                                *
         -- **********************************
         function Is_Evaluated (Token : in Lex.Goal_Value) return Boolean;

         --| Purpose
         --| Is_Evaluated determines whether a clause is a query.
         --|
         --| Exceptions
         --| Notes (none)
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Initialize_Links             *  SPEC
         -- *                                *
         -- **********************************
         procedure Initialize_Links;

         --| Purpose
         --| Initialize_Links clears the linked list and sets pointers to NIL.
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
         -- *  Heap_Walk                     *  SPEC
         -- *                                *
         -- **********************************
         function Heap_Walk return Boolean;

         --| Purpose
         --| Debugging function for walking the heap.
         --| Returns FALSE when done.  NOT IMPLEMENTED.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

      end Linked_List;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Prefix                       *  SPEC
      -- *                                *
      -- **********************************
      package Prefix is

         --| Purpose
         --| Prefix is used to convert from Prolog-style notation to prefix
         --| notation.  Prefix notation is also known as Lisp or reverse
         --polish.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         package Lex renames Lexical_Analysis;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Tok                       *  SPEC
         -- *                                *
         -- **********************************
         function Get_Tok
           (Position : in Lex.Token_Range)
            return     Lex.Goal_Value;

         --| Purpose
         --| Get_Tok gets a token from internal prefix array
         --|
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Last_Tok_Pos                  *  SPEC
         -- *                                *
         -- **********************************
         function Last_Tok_Pos return Lex.Token_Range;

         --| Purpose
         --| Last_Tok_Pos gets the pointer to the last token.
         --|
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Store_Tok                    *  SPEC
         -- *                                *
         -- **********************************
         procedure Store_Tok (Tok : in Lex.Goal_Value);

         --| Purpose
         --| Store_Tok saves a token to internal array and increments ptr.
         --|
         --| Exceptions
         --| PREFIX_ERROR if Lextab overflows
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Prefix                       *  SPEC
         -- *                                *
         -- **********************************
         procedure Prefix (Lisp_Syntax : in Boolean);

         --| Purpose
         --| Prefix converts the tokens in LEX.Lex_Table to a prefix notation,
         --| and stores these in Lextab.  If Lisp_Syntax is TRUE, then it is
         --| assumed that the tokens are already in prefix notation.
         --| If Lextab_Ptr not advanced, nothing was converted.
         --|
         --| Exceptions
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Purge                        *  SPEC
         -- *                                *
         -- **********************************
         procedure Purge;

         --| Purpose
         --| Purge resets Lextab_Ptr.
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
         -- *  Initialize_Prefix             *  SPEC
         -- *                                *
         -- **********************************
         procedure Initialize_Prefix
           (In_Toks : in Lexical_Analysis.Token_Range);

         --| Purpose
         --| Initialize heap area.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| May 15, 1993      PP             Added In_Toks

      end Prefix;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Verify                       *  SPEC
      -- *                                *
      -- **********************************
      package Verify is

         --| Purpose
         --| Verify controls the logical deduction functions for the
         --Rule_Processor.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions
         --| August 6, 1993     PP            Put external object Frame into
         --body

         package Lex renames Lexical_Analysis;

         type Frame_Range is new Table_Sizes.Integer_Ptr range
            0 .. Table_Sizes.Frame_Range_Max - 1;
         -- Maximum size for the frame array

         Next_Frame : Frame_Range;  -- This is global for speed only

         type Control_Stack_Range is new Table_Sizes.Integer_Ptr range
            1 .. Table_Sizes.Control_Stack_Max;

         type Goal_Stack_Range is new Table_Sizes.Integer_Ptr range
            0 .. Table_Sizes.Goal_Stack_Max - 1;

         Only_One : Boolean := True;   -- Only a single solution is required.

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_TRO                       *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Tro (On : in Boolean);

         --| Purpose
         --| Set the tail recursion optimization on or off.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Findall_Variable          *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Findall_Variable (Var : in Lex.Goal_Value);

         --| Purpose
         --| Set the findall variable to Var.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Control_Depth             *  SPEC
         -- *                                *
         -- **********************************
         function Get_Control_Depth return Table_Sizes.Integer_Ptr;

         --| Purpose
         --| Returns the deepest level of recursion.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Inferences          *  SPEC
         -- *                                *
         -- **********************************
         function Number_Of_Inferences return Rule_Errors.Count;

         --| Purpose
         --| Returns the number of inferences of last query.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Get_Next_Frame               *  SPEC
         -- *                                *
         -- **********************************
         function Get_Next_Frame return Frame_Range;

         --| Purpose
         --| Get_Next_Frame finds the next available Frame cell.
         --|
         --| Exceptions
         --| FRAME_ERROR if Frame array overflows.
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Resolve                      *  SPEC
         -- *                                *
         -- **********************************
         function Resolve
           (A_Query        : in Lex.Goal_Value;
            Frame_Ptr      : in Frame_Range;
            Multiple_Goals : in Boolean)
            return           Lex.Goal_Value;

         --| Purpose
         --| Resolve does the backchaining deduction, starting from A_Query.
         --| If Multiple_Goals is TRUE then all solutions are returned.
         --|
         --| Exceptions (none)
         --| Notes
         --| Limited amount of recursion.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| September 23,1991  PP            Changed return value
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Query                        *  SPEC
         -- *                                *
         -- **********************************
         procedure Query
           (Current_Clause : in Lex.Goal_Value;
            This_Query     : out Lex.Goal_Value;
            Solution       : out Lex.Goal_Value;
            At_Frame       : out Frame_Range);

         --| Purpose
         --| Query starts the deduction process on Current_Clause.
         --| The output parameters are :
         --| This_Query = Query corresponding to Current_Clause.
         --| Solution   = Solution List for Query (should be non NIL if
         --successful).
         --| At_Frame   = Frame for Solution.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| September 23,1991  PP            Removed Success parameter
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Frame_Variable               *  SPEC
         -- *                                *
         -- **********************************
         function Frame_Variable
           (Pointer : in Frame_Range)
            return    Lex.Goal_Value;
         --   pragma INLINE ( Frame_Variable );

         --| Purpose
         --| Frame_Variable returns the variable corresponding to the frame
         --pointer.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Frame_Value                  *  SPEC
         -- *                                *
         -- **********************************
         function Frame_Value
           (Pointer : in Frame_Range)
            return    Lex.Goal_Value;
         --   pragma INLINE ( Frame_Value );

         --| Purpose
         --| Frame_Value returns the value corresponding to the frame pointer.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Frame_Reference              *  SPEC
         -- *                                *
         -- **********************************
         function Frame_Reference
           (Pointer : in Frame_Range)
            return    Frame_Range;
         --   pragma INLINE ( Frame_Reference );

         --| Purpose
         --| Frame_Reference returns the frame corresponding to the frame
         --pointer.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Set_Frame_Value              *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Frame_Value
           (Pointer : in Frame_Range;
            Value   : in Lex.Goal_Value);
         --   pragma INLINE ( Set_Frame_Value );

         --| Purpose
         --| Set_Frame_Value sets the value corresponding to the frame pointer.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Set_Frame_Reference          *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Frame_Reference
           (Pointer, Ref_Value : in Frame_Range);
         --   pragma INLINE ( Set_Frame_Reference );

         --| Purpose
         --| Set_Frame_Reference sets the frame corresponding to the frame
         --pointer.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Copy_Clause                  *  SPEC
         -- *                                *
         -- **********************************
         function Copy_Clause
           (New_Frame_Ptr : in Frame_Range;
            Clause        : in Lex.Goal_Value)
            return          Boolean;

         --| Purpose
         --| Copy_Clause copies all variables in a clause at once into a frame
         --area.
         --|
         --| Exceptions
         --| Notes
         --| Recursion invoked here.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Initialize_Ver                *  SPEC
         -- *                                *
         -- **********************************
         procedure Initialize_Ver
           (Frames   : in Frame_Range;
            Goals    : in Goal_Stack_Range;
            Subgoals : in Goal_Stack_Range;
            Control  : in Control_Stack_Range);

         --| Purpose
         --| Initialize heap arrays.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| May 15, 1993      PP             Added Subgoals, Control

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  All_Query                     *  SPEC
         -- *                                *
         -- **********************************
         procedure All_Query
           (Current_Clause : in Lex.Goal_Value;
            This_Query     : out Lex.Goal_Value;
            Solution       : out Lex.Goal_Value;
            At_Frame       : out Frame_Range);

         --| Purpose
         --| Query to find all solutions.  Call this repetitively to obtain
         --solutions
         --| if the Multiple builtin predicate has been set.
         --| Solution is NIL when no solutions are left.
         --|
         --| Exceptions (none)
         --| Notes
         --| Uses tasking, so use Stop to halt task.
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Stop                          *  SPEC
         -- *                                *
         -- **********************************
         procedure Stop;

         --| Purpose
         --| Stop tasks used by All_Query.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

      end Verify;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Builtin_Predicates           *  SPEC
      -- *                                *
      -- **********************************
      package Builtin_Predicates is

         --| Purpose
         --| Builtin_Predicates provides access to Prolog-style builtins and
         --| to mathematical and logical operations.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         package Lex renames Lexical_Analysis;
         package Ver renames Verify;

         subtype Predicates is Lex.Builtin_Range range
            Lex.Builtin_Range'First .. Lex.Builtin_Range'First + 65;
         -- Ranges to maximum number of builtin functions, the maximum limit
         --is -^
         -- Builtin range limits is set in LEX.

         -- Pointers to builtin predicates
         -- Builtins start with 'P_***' and correspond to those in
         --Symbol_String
         -- Goal_Value

         P_Is     : constant Predicates := Predicates'First + 0;  --  assignmen
                                                                  --t 'is'
         P_Not    : constant Predicates := Predicates'First + 1;  --  negation
                                                                  --'not'
         P_Ifthen : constant Predicates := Predicates'First + 2;  --  If Then
                                                                  --->
         P_Uminus : constant Predicates := Predicates'First + 3;  --  token
                                                                  --for unary
                                                                  --minus '-'
         P_Bminus : constant Predicates := Predicates'First + 4;  --  token
                                                                  --for binary
                                                                  --minus '-'
         P_Exp    : constant Predicates := Predicates'First + 5;  --  integer
                                                                  --power '^'
         P_Mult   : constant Predicates := Predicates'First + 6;  --  multiplic
                                                                  --ation '*'
         P_Plus   : constant Predicates := Predicates'First + 7;  --  addition
                                                                  --'+'
         P_Lt     : constant Predicates := Predicates'First + 8;  --  less
                                                                  --than '<'
         P_Gt     : constant Predicates := Predicates'First + 9;  --  greater
                                                                  --than '>'
         P_Div    : constant Predicates := Predicates'First + 10; --  division
                                                                  --symbol '/'
         P_Ne     : constant Predicates := Predicates'First + 11; --  not
                                                                  --equal '/='
         P_Le     : constant Predicates := Predicates'First + 12; --  less
                                                                  --than or
                                                                  --equal '<='
         P_Ge     : constant Predicates := Predicates'First + 13; --  greater
                                                                  --than or
                                                                  --equal '>='
         P_Sequal : constant Predicates := Predicates'First + 14; --  strong
                                                                  --equality
                                                                  --'='
         P_Period : constant Predicates := Predicates'First + 15; --  period
                                                                  --'.'
         P_Comma  : constant Predicates := Predicates'First + 16;--  comma ','
         P_If     : constant Predicates := Predicates'First + 17;--  if ':-'
         P_Query  : constant Predicates := Predicates'First + 18; --  right
                                                                  --query '?'
         P_Ldot   : constant Predicates := Predicates'First + 19; --  Pipe or
                                                                  --Lisp dot
                                                                  --'|'
         P_Lrb    : constant Predicates := Predicates'First + 20; --  left
                                                                  --round
                                                                  --bracket '('
         P_Rrb    : constant Predicates := Predicates'First + 21; --  right
                                                                  --round
                                                                  --bracket ')'
         P_Lsqb   : constant Predicates := Predicates'First + 22; --  left
                                                                  --square
                                                                  --bracket '['
         P_Rsqb   : constant Predicates := Predicates'First + 23; --  right
                                                                  --square
                                                                  --bracket ']'
         P_Cut    : constant Predicates := Predicates'First + 24; --  cut
                                                                  --symbol '!'

         --  Added Builtins, these can be added as library functions

         P_Findall  : constant Predicates := Predicates'First + 25;
         P_Assert   : constant Predicates := Predicates'First + 26;
         P_Retract  : constant Predicates := Predicates'First + 27;
         P_Fail     : constant Predicates := Predicates'First + 28;
         P_Asserta  : constant Predicates := Predicates'First + 29;
         P_Trace    : constant Predicates := Predicates'First + 30;
         P_Var      : constant Predicates := Predicates'First + 31;
         P_Length   : constant Predicates := Predicates'First + 32;
         P_Write    : constant Predicates := Predicates'First + 33;
         P_Listing  : constant Predicates := Predicates'First + 34;
         P_Atom     : constant Predicates := Predicates'First + 35;
         P_Integer  : constant Predicates := Predicates'First + 36;
         P_Float    : constant Predicates := Predicates'First + 37;
         P_Mod      : constant Predicates := Predicates'First + 38;
         P_Arg      : constant Predicates := Predicates'First + 39;
         P_Concat   : constant Predicates := Predicates'First + 40;
         P_Gc       : constant Predicates := Predicates'First + 41;
         P_Idiv     : constant Predicates := Predicates'First + 42;
         P_Read     : constant Predicates := Predicates'First + 43;
         P_Display  : constant Predicates := Predicates'First + 44;
         P_Onlyone  : constant Predicates := Predicates'First + 45;
         P_Load     : constant Predicates := Predicates'First + 46;
         P_Equal    : constant Predicates := Predicates'First + 47;
         P_Nequal   : constant Predicates := Predicates'First + 48;
         P_Or       : constant Predicates := Predicates'First + 49;
         P_Save     : constant Predicates := Predicates'First + 50;
         P_Nl       : constant Predicates := Predicates'First + 51;
         P_Multiple : constant Predicates := Predicates'First + 52;
         P_System   : constant Predicates := Predicates'First + 53;
         P_Tell     : constant Predicates := Predicates'First + 54;
         P_Told     : constant Predicates := Predicates'First + 55;
         P_Tab      : constant Predicates := Predicates'First + 56;
         P_Print    : constant Predicates := Predicates'First + 57;
         P_Dde      : constant Predicates := Predicates'First + 58;
         P_Post     : constant Predicates := Predicates'First + 59;
         P_True     : constant Predicates := Predicates'First + 60;
         P_Call     : constant Predicates := Predicates'First + 61;
         P_Unif     : constant Predicates := Predicates'First + 62;
         P_See      : constant Predicates := Predicates'First + 63;
         P_Seen     : constant Predicates := Predicates'First + 64;

         -- If more builtins are needed, add an ASCII label to end of
         --Symbol_String
         -- and increment Predicates range by 1.

         P_Eot : constant Predicates := Predicates'First + 65;

         Predicate_Table : array (Predicates) of Lex.Symbol_String;

         type Builtin_Result is (Succeeded, Failed, Interpret);

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Trace_On                   *  SPEC
         -- *                                *
         -- **********************************
         function Is_Trace_On return Boolean;

         --| Purpose
         --| Checks if trace is on.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Builtin                   *  SPEC
         -- *                                *
         -- **********************************
         --   function Is_Builtin ( Token : in LEX.Goal_Value ) return BOOLEAN;
         --   pragma INLINE ( Is_Builtin );

         --| Purpose
         --| Is_Builtin determines whether a token (i.e. Goal) is a builtin
         --| predicate.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Parenthetic                  *  SPEC
         -- *                                *
         -- **********************************
         function Parenthetic (Token : in Lex.Goal_Value) return Boolean;
         --   pragma INLINE ( Parenthetic );

         --| Purpose
         --| Parenthetic determines if a token is one of '()' or '[]'.
         --|
         --| Exceptions (none)
         --| Notes
         --| Inline for speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Operation                    *  SPEC
         -- *                                *
         -- **********************************
         function Operation (Token : in Lex.Goal_Value) return Boolean;
         --   pragma INLINE ( Operation );

         --| Purpose
         --| Operation determines if a token (i.e. Goal) is an arithmetic
         --| operation.
         --|
         --| Initialization Exceptions
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Initialize_Bips              *  SPEC
         -- *                                *
         -- **********************************
         procedure Initialize_Bips
           (In_Toks : in Lex.Token_Range;
            Hash    : in Lex.Symbol_Hash_Table_Range);

         --| Purpose
         --| Initialize_Bips clears the builtin predicate table and sets
         --pointer to
         --| start.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions
         --| May 15, 1993       PP            Added In_Toks (per clause),
         --Out_Toks (output), Hash (size)

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Evaluate_Builtin             *  SPEC
         -- *                                *
         -- **********************************
         function Evaluate_Builtin
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Builtin_Result;

         --| Purpose
         --| Evaluate_Builtin evaluates the predicate corresponding to the
         --goal.
         --| This includes arithmetic, logical, and other builtins.
         --|
         --| Exceptions
         --| BUILTIN_ERROR if not a builtin predicate
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

      end Builtin_Predicates;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Token_IO                     *  SPEC
      -- *                                *
      -- **********************************
      package Token_Io is

         --| Purpose
         --| Token_IO generates symbolic and numeric values for output to
         --| the display.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         package Ver renames Verify;
         package Lex renames Lexical_Analysis;

         type Io_Flag is (Stream_Out, Error_Display, Aux_Display, Nul_Bucket);

         subtype Description is String (1 .. 4);

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print_Token                  *  SPEC
         -- *                                *
         -- **********************************
         procedure Print_Token
           (Fp        : in Io_Flag;
            Token     : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range);

         --| Purpose
         --| Print_Token displays the symbolic representation of
         --| a token (i.e. goal).
         --|
         --| Exceptions (none)
         --| Notes
         --| Recursion if Token is a list.
         --|
         --| Modifications
         --| September 9, 1991  Paul Pukite   Initial Version
         --| November  3, 1991  Paul Pukite   IO_Flag modified
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print_Variables              *  SPEC
         -- *                                *
         -- **********************************
         procedure Print_Variables
           (Fp        : in Io_Flag;
            Arg       : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range);

         --| Purpose
         --| Print_Variables displays or stores symbolic or numeric
         --representations
         --| of the variable arguments represented in the Arg goal.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 9, 1991  Paul Pukite   Initial Version
         --| November  3, 1991  Paul Pukite   IO_Flag modified
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print_Statistics             *  SPEC
         -- *                                *
         -- **********************************
         procedure Print_Statistics;

         --| Purpose
         --| Print_Statistics displays additional statistics information.
         --|
         --| Exceptions (none)
         --| Notes
         --| Used mainly for interactive display.
         --|
         --| Modifications
         --| September 9, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print_Driver                 *  SPEC
         -- *                                *
         -- **********************************
         procedure Print_Driver
           (Fp        : in Io_Flag;
            Item      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range);

         --| Purpose
         --| Print_Driver starts the symbolic display of tokens associated
         --| with the Item goal.
         --|
         --| Exceptions
         --| Notes
         --|
         --| Modifications
         --| September 9, 1991  Paul Pukite   Initial Version
         --| November  3, 1991  Paul Pukite   IO_Flag modified
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Trace                        *  SPEC
         -- *                                *
         -- **********************************
         procedure Trace
           (Str   : in Description;
            Level : in Table_Sizes.Integer_Ptr;
            Goal  : in Lex.Goal_Value;
            Frame : in Ver.Frame_Range);

         --| Purpose
         --| Trace provides debugging of the resolution process in the package
         --Verify
         --| Query procedure.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| September 9, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Close_File                   *  SPEC
         -- *                                *
         -- **********************************
         procedure Close_File (Fp : in Io_Flag);

         --| Purpose
         --| Close_File is equivalent to Text_IO.Close.
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
         -- *   Open_File                    *  SPEC
         -- *                                *
         -- **********************************
         procedure Open_File (File_Name : in String; Fp : in Io_Flag);

         --| Purpose
         --| Open_File is equivalent to Text_IO.Close.
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
         -- *   New_Line                     *  SPEC
         -- *                                *
         -- **********************************
         procedure New_Line (Fp : in Io_Flag);

         --| Purpose
         --| New_Line provides a CR/LF.
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
         -- *   Print                        *  SPEC
         -- *                                *
         -- **********************************
         procedure Print (Fp : in Io_Flag; Str : in String);

         --| Purpose
         --| Print puts a string.
         --| Provides TEXT_IO-like display to a monitor, file, or nul.
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
         -- *   Print                        *  SPEC
         -- *                                *
         -- **********************************
         procedure Print (Fp : in Io_Flag; Ch : in Character);

         --| Purpose
         --| Print puts a character.
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
         -- *  FltStr                        *  SPEC
         -- *                                *
         -- **********************************
         function Fltstr
           (Val   : in Lex.Calc_Flt;
            Short : in Boolean := True)
            return  String;

         --| Purpose
         --| Convert a float to a string.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  IntStr                        *  SPEC
         -- *                                *
         -- **********************************
         function Intstr (Val : in Lex.Calc_Int) return String;

         --| Purpose
         --| Convert an integer to a string.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

      end Token_Io;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Unification                  *  SPEC
      -- *                                *
      -- **********************************
      package Unification is

         --| Purpose
         --| Unification does the major work in unifying variables.
         --|
         --| Initialization Exceptions (none)
         --| Notes
         --| All function calls should be inlined for maximum speed.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions
         --| August 6, 1993     PP            Optimization

         package Ver renames Verify;
         package Lex renames Lexical_Analysis;

         --  The trail stack must save information about the frame pointer
         --  of the variable so that it can be reset properly.

         type Unification_Stack_Range is new Table_Sizes.Integer_Ptr range
            0 .. Table_Sizes.Unif_Stack_Max - 1;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Unification_Attempts          *  SPEC
         -- *                                *
         -- **********************************
         function Unification_Attempts
           (Reset : Boolean := False)
            return  Rule_Errors.Count;

         --| Purpose
         --| Return the number of unifications attempted.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Unify                        *  SPEC
         -- *                                *
         -- **********************************
         function Unify
           (Source, Target               : in Lex.Goal_Value;
            Old_Frame_Ptr, New_Frame_Ptr : in Ver.Frame_Range)
            return                         Boolean;

         --| Purpose
         --| Unify unifies Source to Target goal arguments.
         --|
         --| Exceptions (none)
         --| Notes
         --| Recursion is used in the Unify function for lists.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Find                         *  SPEC
         -- *                                *
         -- **********************************
         function Find
           (Argument  : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Ver.Frame_Range;

         --| Purpose
         --| Find finds the Argument in Frame, using a linear search method.
         --|
         --| Exceptions
         --| LOST_TRACK_VARIABLE_ERROR if not found.
         --|
         --| Notes
         --| Critical to speed this up.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Attach                       *  SPEC
         -- *                                *
         -- **********************************
         procedure Attach
           (Argument  : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range;
            Value     : in Lex.Goal_Value;
            Value_Ptr : in Ver.Frame_Range);

         --| Purpose
         --| Attach performs the binding of a variable.
         --|
         --| Exceptions
         --| UNIFY_STACK_ERROR if stack overflows.
         --|
         --| Notes
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions
         --| August 6, 1993     PP            Pulled in Push_Unify_Stack

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Lookup                       *  SPEC
         -- *                                *
         -- **********************************
         procedure Lookup
           (Argument     : in Lex.Goal_Value;
            Frame_Ptr    : in out Ver.Frame_Range;
            Return_Value : out Lex.Goal_Value);

         --| Purpose
         --| Lookup the value of a variable in the frame area.  If lookup
         --yields
         --| another variable, then continue to lookup until we get to an
         --unbound
         --| variable or to a final value.
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
         -- *  Initialize_Unif               *  SPEC
         -- *                                *
         -- **********************************
         procedure Initialize_Unif
           (Length : in Unification_Stack_Range;
            Frames : in Ver.Frame_Range);

         --| Purpose
         --| Initialize heap area.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| August 6, 1993    PP             Added Frames

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Variable                  *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Variable
           (Frame_Ptr : in Ver.Frame_Range;
            Variable  : in Lex.Goal_Value);

         --| Purpose
         --| Set the frame variable for searching
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Unify_Ptr                 *  SPEC
         -- *                                *
         -- **********************************
         function Get_Unify_Ptr return Unification_Stack_Range;

         --| Purpose
         --| Get the unification pointer
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Unify_From                *  SPEC
         -- *                                *
         -- **********************************
         function Get_Unify_From
           (Ptr  : in Unification_Stack_Range)
            return Ver.Frame_Range;

         --| Purpose
         --| Get the first unified frame pointer
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Unify_To                  *  SPEC
         -- *                                *
         -- **********************************
         function Get_Unify_To
           (Ptr  : in Unification_Stack_Range)
            return Ver.Frame_Range;

         --| Purpose
         --| Get the second unified frame pointer
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Unify_Ptr                 *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Unify_Ptr (Ptr : in Unification_Stack_Range);

         --| Purpose
         --| Set the unification stack.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

      end Unification;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Rule_Errors                  *  BODY
      -- *                                *
      -- **********************************
      package body Rule_Errors is

         --| Purpose
         --| Package body for Rule_Errors
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         External_Control : External_Control_Flag := None;

         -- Default : Table_Sizes.Allocation := Table_Sizes.Default;

         -- **********************************
         -- *                                *
         -- *   Check_Condition              *  BODY
         -- *                                *
         -- **********************************
         procedure Check_Condition
           (Inferences   : in Count := 0;
            Unifications : in Count := 0)
         is
         begin

            if External_Control = Stop then
               raise Stop_Error;
            elsif External_Control = Timeout then
               raise Timeout_Error;
            elsif Inferences > Count'Last then --  (Default.Infers) then --PP
               raise Inferences_Error;
            elsif Unifications > Count'Last then -- (Default.Unifs) then --PP
               raise Unifications_Error;
            else
               null;
            end if;

         end Check_Condition;

         -- **********************************
         -- *                                *
         -- *   Set_Condition                *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Condition (Flag : in External_Control_Flag) is
         begin
            External_Control := Flag;
         end Set_Condition;

      end Rule_Errors;

      package body Lexical_Analysis is

         --| Purpose
         --| Package body for Lexical_Analysis
         --|
         --| Exceptions
         --|
         --| Notes
         --| This package contains details of the lexical tokenizer.
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| July 15, 1993     PP           Speeded up Clear_Table, and Same
         --functions

         package Bips renames Builtin_Predicates;
         procedure Free is new Unchecked_Deallocation (
            Object => Goal_Value_Record,
            Name => Goal_Value);

         procedure Free is new Unchecked_Deallocation (
            Object => Instance_Record,
            Name => Instance);

         procedure Free is new Unchecked_Deallocation (
            Object => Symbol_Record,
            Name => Symbol_String);

         type Symbol_Hash_Array is
           array (Symbol_Hash_Table_Range range <>) of Symbol_String;
         type Symbol_Hash_Access is access Symbol_Hash_Array;
         Symbol_Hash_Table : Symbol_Hash_Access;

         -- String to be analyzed is contained in Clause_String.
         -- Clause Position refers to position within the string.
         Clause_Position : Clause_String_Range;

         Variable_Ptr : Goal_Value;
         -- Number of current clause which contains at least one variable.
         -- Used for standardizing apart.

         type Word_Flag is (Variable, Atom, Anonymous);

         -- List holding the possible components of symbolic strings in Prolog,
         -- i.e. ':-' contains ':' and '-'.
         Symbol_List : String (1 .. 13) := "+-*/^<>=:.?;\";

         Builtin_Goals : array (Builtin_Range) of Goal_Value;

         Eot : Goal_Value;

         Nil_Value : Goal_Value :=
            new Goal_Value_Record'
           (Content => Lis,
            Mark    => True,
            First   => null,
            Link    => null,
            Next    => null);

         Wild_Card_Value : Goal_Value :=
            new Goal_Value_Record'
           (Content => Any,
            Mark    => True,
            Link    => null);

         subtype Word_Range is Integer range 1 .. Table_Sizes.Word_Length_Max;
         subtype Word_String is String (Word_Range);
         -- Maximum size of atom and variable names.

         One : constant Word_Range := Word_Range'First;

         Prev_Gv : Goal_Value := Nil_Value;

         Num_Goals : Rule_Errors.Count := 0;
         Num_Symbs : Rule_Errors.Count := 0;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Goals               *  BODY
         -- *                                *
         -- **********************************
         function Number_Of_Goals return Rule_Errors.Count is
         begin
            return Num_Goals;
         end Number_Of_Goals;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Symbols             *  BODY
         -- *                                *
         -- **********************************
         function Number_Of_Symbols return Rule_Errors.Count is
         begin
            return Num_Symbs;
         end Number_Of_Symbols;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Save                          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Save (Gv : Goal_Value) return Goal_Value is

         --| Purpose
         --| Connect GV to the linked list.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Prev_Gv.Link := Gv;
            Prev_Gv      := Gv;
            return Gv;
         end Save;

         -- **********************************
         -- *                                *
         -- *   Is_Numeric                   *  BODY
         -- *                                *
         -- **********************************
         function Is_Numeric (Token : in Goal_Value) return Boolean is
         begin
            return Token /= null
                  and then (Token.Content = Int or Token.Content = Flt);
         end Is_Numeric;

         -- **********************************
         -- *                                *
         -- *   Is_Variable                  *  BODY
         -- *                                *
         -- **********************************
         function Is_Variable (Token : in Goal_Value) return Boolean is
         begin
            return Token /= null and then Token.Content = Var;
         end Is_Variable;

         -- **********************************
         -- *                                *
         -- *   Is_Atomic                    *  BODY
         -- *                                *
         -- **********************************
         function Is_Atomic (Token : in Goal_Value) return Boolean is
         begin
            return Token /= null and then Token.Content = Sym;
         end Is_Atomic;

         -- **********************************
         -- *                                *
         -- *   Is_Nil                       *  BODY
         -- *                                *
         -- **********************************
         function Is_Nil (Token : in Goal_Value) return Boolean is
         begin
            return Token = null
                  or else (Token.Content = Lis and then Token.First = null);
         end Is_Nil;

         -- **********************************
         -- *                                *
         -- *   Is_Goal                      *  BODY
         -- *                                *
         -- **********************************
         function Is_Goal (Token : in Goal_Value) return Boolean is
         begin
            return not Is_Nil (Token);
         end Is_Goal;

         -- **********************************
         -- *                                *
         -- *   Is_List                      *  BODY
         -- *                                *
         -- **********************************
         function Is_List (Token : in Goal_Value) return Boolean is
         begin
            return Token /= null
                  and then Token.Content = Lis
                  and then Token.First /= null;
         end Is_List;

         -- **********************************
         -- *                                *
         -- *   Is_Token                     *  BODY
         -- *                                *
         -- **********************************
         function Is_Token (Token : in Goal_Value) return Boolean is
         begin
            return Token /= null
                  and then Token.Content /= Lis
                  and then Token.Content /= Any;
         end Is_Token;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Word_Hash                    *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Word_Hash
           (Str  : in String)
            return Symbol_Hash_Table_Range
         is

            --| Purpose
            --| Hash the given word to obtain a number of size less than the
            --table range.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Hash_Value : Table_Sizes.Integer_Ptr := 0;
         begin

            for I in  Str'Range loop
               Hash_Value := Hash_Value + Character'Pos (Str (I));
            end loop;

            return (Hash_Value rem Symbol_Hash_Table'Last);

         end Word_Hash;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Hash_Keywords                *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Hash_Keywords is

            --| Purpose
            --| Initialize the symbol table so that it contains all the
            --built-in
            --| function names used by the rule processor.
            --| Hash only the builtin keywords.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            --PP Keyword_Ptr : BIPS.Predicates; -- Keyword_Ptr points into
            --Symbol_Table.
            Code : Symbol_Hash_Table_Range;  -- Code holds the hash value for
                                             --a word.

         begin

            for Keyword_Ptr in  Bips.Predicates'First .. Bips.Predicates'Last
            loop

               Num_Goals                   := Num_Goals + 1;
               Builtin_Goals (Keyword_Ptr) :=
                 new Goal_Value_Record'
                 (Content => Bip,
                  Mark    => True,
                  Link    => null,
                  Builtin => Keyword_Ptr);

               exit when Bips.Predicate_Table (Keyword_Ptr) = null;

               Code := Word_Hash (Bips.Predicate_Table (Keyword_Ptr).Str);
               -- Obtain the hash code for this word.

               while Symbol_Hash_Table (Code) /= null loop
                  -- Use open addressing to find a match in table.
                  if Code = Symbol_Hash_Table'Last then
                     Code := Symbol_Hash_Table'First;
                  else
                     Code := Code + 1;
                  end if;
               end loop;

               Num_Symbs                               := Num_Symbs + 1;
               Bips.Predicate_Table (Keyword_Ptr).Refs := 0;
               Symbol_Hash_Table (Code)                :=
                 Bips.Predicate_Table (Keyword_Ptr);
               -- Retain info on where atom is stored.

            end loop;

         end Hash_Keywords;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Numeric                      *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Numeric (Char : in Character) return Boolean is

         --| Purpose
         --| Numeric returns boolean TRUE if character is a digit.
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         begin
            return (Char in '0' .. '9');
         end Numeric;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Alpha                        *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Alpha (Char : in Character) return Boolean is

         --| Purpose
         --| Alpha returns boolean TRUE if character is an alpha.
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         begin
            return ((Char in 'a' .. 'z') or else (Char in 'A' .. 'Z'));
         end Alpha;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Alphanumeric                 *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Alphanumeric (Char : in Character) return Boolean is

         --| Purpose
         --| Alphanumeric returns boolean TRUE if character is an alpha or
         --digit.
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version

         begin
            return (Char = '_' or else Alpha (Char) or else Numeric (Char));
         end Alphanumeric;

         -- **********************************
         -- *                                *
         -- *   Add_Integer                  *  BODY
         -- *                                *
         -- **********************************
         function Add_Integer (Number : in Calc_Int) return Goal_Value is

         --| Notes
         --| Add an integer to the list.
         --| Return the relevant symbolic token.

         begin
            Num_Goals := Num_Goals + 1;
            return Save
                     (new Goal_Value_Record'
              (Content => Int,
               Mark    => True,
               Link    => null,
               Number  => Number));
         end Add_Integer;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Add_Float                     *  BODY
         -- *                                *
         -- **********************************
         function Add_Float (Number : in Calc_Flt) return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Num_Goals := Num_Goals + 1;
            return Save
                     (new Goal_Value_Record'
              (Content => Flt,
               Mark    => True,
               Link    => null,
               Fvalue  => Number));
         end Add_Float;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Word_to_Integer              *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Word_To_Integer (Str : in String) return Calc_Int is

            --| Purpose
            --| Convert from ASCII representation to integer.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| November10, 1991  PP           Added count
            --| April 26, 1993    PP           Heap extensions

            Cvalue : Calc_Int := 0;
            Last   : Natural;
         begin

            Iio.Get (Str, Cvalue, Last);
            return (Cvalue);

         end Word_To_Integer;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Word_To_Float                 *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Word_To_Float (Str : in String) return Calc_Flt is

            --| Purpose
            --| Convert a string to a float.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Cvalue : Calc_Flt := 0.0;
            Last   : Natural;
         begin

            Fio.Get (Str, Cvalue, Last);
            return (Cvalue);

         end Word_To_Float;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Lex_Number                   *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Lex_Number return Goal_Value is

            --| Purpose
            --| Lex_Number parses and inserts a number into the list.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Symb    : Character;
            Word    : Word_String;
            Pos     : Word_Range := Word_Range'First;
            Is_Int  : Boolean    := True;
            Is_Exp  : Boolean    := False;
            Is_Sign : Boolean    := False;
            Lastch  : Character  := ASCII.NUL;
            Gv      : Goal_Value;
         begin

            loop
               Symb := Clause_String (Clause_Position);
               if Symb = '.' then
                  if Clause_String (Clause_Position + 1) in '0' .. '9' then
                     Is_Int := False;
                  else
                     exit;
                  end if;
               elsif Symb = 'e' or Symb = 'E' then
                  exit when Is_Int or Is_Exp;
                  Is_Exp := True;
               elsif Symb = '+' or Symb = '-' then
                  exit when Is_Int or
                            Is_Sign or
                            not (Lastch = 'e' or Lastch = 'E');
                  Is_Sign := True;
               else
                  exit when not (Symb in '0' .. '9');
               end if;
               Lastch          := Symb;
               Word (Pos)      := Symb;
               Clause_Position := Clause_Position + 1;
               Pos             := Pos + 1;
            end loop;

            if Is_Int then
               Gv := Add_Integer (Word_To_Integer (Word (One .. Pos - 1)));
            else
               Gv := Add_Float (Word_To_Float (Word (One .. Pos - 1)));
            end if;

            if Lex_Position > Token_Range'First
              and then Is_Builtin_Token
                          (Lex_Table (Lex_Position - 1),
                           Bips.P_Uminus)
            then
               Lex_Position := Lex_Position - 1;
               if Is_Int then
                  Gv.Number := -Gv.Number;
               else
                  Gv.Fvalue := -Gv.Fvalue;
               end if;
            end if;

            return Gv;

         end Lex_Number;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Search                       *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Search
           (Word   : Word_String;
            Len    : Word_Range;
            Symbol : Boolean)
            return   Symbol_String
         is

            --| Purpose
            --| Search uses a hash-based search to match a symbol in the
            --symbol table.
            --| If not found, the word is inserted into the table.
            --|
            --| Exceptions
            --| SYMBOL_TABLE_ERROR if the symbol table overflows.
            --|
            --| Notes
            --|
            --| Modifications
            --| September 8, 1991  Paul Pukite   Initial Version
            --| November 10, 1991  PP            Added Len of Word
            --| April 26, 1993     PP            Heap extensions

            Table_Pos : Symbol_String;
            Code      : Symbol_Hash_Table_Range;
            Loops     : Symbol_Hash_Table_Range;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Compare                      *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Compare (Start : in String) return Boolean is

            --| Purpose
            --| Check if word is equal to the atom at position Start of symbol
            --table.
            --| Internal to Search.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            begin

               if Start'Length /= Len then
                  return False;
               else
                  return Start (Start'First - 1 + One .. Start'First - 1 + Len) = 
                  Word (Start'First - 1 + One .. Start'First - 1 + Len);
               end if;
            end Compare;

         begin -- Search

            if Symbol then
               Code := Word_Hash (Word (One .. Len));

               Table_Pos := Symbol_Hash_Table (Code);
               Loops     := Symbol_Hash_Table_Range'First;

               while Table_Pos /= null loop
                  Loops := Loops + 1;

                  if Compare (Table_Pos.Str) then
                     if Table_Pos.Refs /= 0 then
                        Table_Pos.Refs := Table_Pos.Refs + 1;
                     end if;
                     return (Table_Pos);
                  else
                     if Code = Symbol_Hash_Table'Last then
                        Code := Symbol_Hash_Table'First;
                     else
                        Code := Code + 1;
                     end if;
                     Table_Pos := Symbol_Hash_Table (Code);
                  end if;
                  if Loops >= Symbol_Hash_Table'Last then
                     raise Rule_Errors.Symbol_Table_Error;
                  end if;

               end loop;
            end if;

            Table_Pos := Make_Symbol (Word (One .. Len));

            if Symbol then
               Symbol_Hash_Table (Code) := Table_Pos;
               -- Did not find word, insert its code in hash table.
            end if;

            return (Table_Pos);

         end Search;

         -- **********************************
         -- *                                *
         -- *   Add_Word                     *  BODY
         -- *                                *
         -- **********************************
         function Add_Word
           (Str    : in String;
            Symbol : in Boolean := True)
            return   Symbol_String
         is

            --| Purpose
            --| Initiate a search to insert a word into the symbol table.
            --Word must be
            --| obtained from String.  Return the record at which word is
            --stored.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| November10, 1991  PP           Changed to string input
            --| April 26, 1993    PP           Heap extensions

            Word   : Word_String;
            Pos    : Word_Range := Word_Range'First;
            Char   : Character;
            Symtab : Symbol_String;
         begin

            for I in  Str'Range loop

               Char := Str (I);
               if Char in ' ' .. '~' then
                  -- exit when Char = ' ';
                  Word (Pos) := Char;

                  if Pos = Word_Range'Last then
                     raise Rule_Errors.Lex_Error;
                  end if;

                  Pos := Pos + 1;
               end if;

            end loop;

            Word (Pos) := ASCII.NUL;

            Symtab := Search (Word, Pos - 1, Symbol);
            return (Symtab);

         end Add_Word;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Find_Predicate               *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Find_Predicate
           (Location : in Symbol_String)
            return     Bips.Predicates
         is

         --| Purpose
         --| Find the builtin predicate corresponding to the symbol.
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         begin

            for I in  Bips.Predicates'First .. Bips.Predicates'Last loop
               if Location = Bips.Predicate_Table (I) then
                  return (I);
               end if;
            end loop;

            raise Rule_Errors.Lex_Error;

         end Find_Predicate;

         -- **********************************
         -- *                                *
         -- *   Insert_Variable              *  BODY
         -- *                                *
         -- **********************************
         function Insert_Variable
           (Variable : in Symbol_String)
            return     Goal_Value
         is

            --| Purpose
            --| Insert a variable and its instance number into the variable
            --table.

            Copy : Goal_Value := Variable_Ptr;
            Gv   : Goal_Value;
            Inst : Instance;

         begin
            Inst :=
              new Instance_Record'
              (Symbol   => Variable,
               Previous => null,
               Forward  => null,
               Refs     => 1);
            Gv   := Make_Variable (Inst);

            if Variable_Ptr /= null then
               Variable_Ptr.Variable.Forward := Gv;
            end if;
            Variable_Ptr         := Gv;
            Gv.Variable.Previous := Copy;
            return Gv;

         end Insert_Variable;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Variable                 *  BODY
         -- *                                *
         -- **********************************
         function Make_Variable (Variable : in Instance) return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Num_Goals := Num_Goals + 1;
            return Save
                     (new Goal_Value_Record'
              (Content  => Var,
               Mark     => True,
               Link     => null,
               Variable => Variable));
         end Make_Variable;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Builtin                  *  BODY
         -- *                                *
         -- **********************************
         function Make_Builtin
           (Predicate : in Builtin_Range)
            return      Goal_Value
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            if Builtin_Goals (Predicate) = null then
               raise Rule_Errors.Builtin_Error;
            else
               return Builtin_Goals (Predicate);
            end if;
         end Make_Builtin;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Atom                     *  BODY
         -- *                                *
         -- **********************************
         function Make_Atom (Symbol : in Symbol_String) return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            if Symbol.Refs = 0 then
               return Make_Builtin (Find_Predicate (Symbol));
            else
               Num_Goals := Num_Goals + 1;
               return Save
                        (new Goal_Value_Record'
                 (Content => Sym,
                  Mark    => True,
                  Link    => null,
                  Symbol  => Symbol));
            end if;
         end Make_Atom;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Make_Symbol                   *  BODY
         -- *                                *
         -- **********************************
         function Make_Symbol (Str : in String) return Symbol_String is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Num_Symbs := Num_Symbs + 1;
            return new Symbol_Record'
              (Length => Str'Length,
               Refs   => 1,
               Str    => Str);
         end Make_Symbol;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Lex_Words                    *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Lex_Words return Goal_Value is

            --| Purpose
            --| Lex_Words places words into the symbol table.  The table is
            --first
            --| searched using a hashing scheme.  Numbers are placed into
            --| a list (floats and integers).
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions
            --| May 2, 1993       PP           quoted builtin overidden

            Start, Stop : Clause_String_Range;
            -- Spans word in Clause_String

            V_Flag : Word_Flag;
            -- Ordinary variable or anonymous (wild card) ?

            V_Index : Goal_Value;
            -- Index into table of variables.

            --Symbol_Table_Pos : Hash_Format;
            Symbol_Table_Pos : Symbol_String;
            -- Starting position of word in the symbol table.

            Symb : Character;
            -- Next symbol in Clause_String.

            Variable_Found : Boolean := False;
            Token          : Goal_Value;
            Is_String      : Boolean := False;
            Is_Quote       : Boolean := False;

         begin

            Start := Clause_Position;
            -- Starting position of word.
            Clause_Position := Clause_Position + 1;

            -- First, test to see if word indicates the anonymous variable.

            Symb := Clause_String (Start);
            if Symb = '_' then
               if Alphanumeric (Clause_String (Clause_Position)) then
                  V_Flag := Variable;  -- Ordinary variables can start with '_'
               else
                  V_Flag := Anonymous; -- Anonymous variable is '_'.
               end if;
            elsif Symb in 'A' .. 'Z' then
               V_Flag := Variable;
            else
               V_Flag := Atom;         -- Other words are atoms.
               if Symb = '"' then
                  Is_String := True;
               elsif Symb = ''' then
                  Is_Quote := True;
               end if;
            end if;

            if Is_String or Is_Quote then
               Start := Start + 1;
               if Is_String then
                  while Clause_String (Clause_Position) /= '"' loop
                     Clause_Position := Clause_Position + 1;
                  end loop;      -- Skip until quote ends
               else
                  while Clause_String (Clause_Position) /= ''' loop
                     Clause_Position := Clause_Position + 1;
                  end loop;      -- Skip until quote ends
               end if;
               Stop := Clause_Position - 1;     -- Record stopping point for
                                                --end of word.
               if Start = Stop + 1 then
                  Start := Clause_Position - 1;
                  Stop  := Clause_Position;
               end if;
               Clause_Position := Clause_Position + 1;
            else
               while Alphanumeric (Clause_String (Clause_Position)) loop
                  Clause_Position := Clause_Position + 1;
               end loop;      -- Skip until a word is started.
               Stop := Clause_Position - 1;     -- Record stopping point for
                                                --end of word.
            end if;

            Symbol_Table_Pos :=
               Add_Word
                 (Clause_String (Start .. Stop),
                  (V_Flag /= Anonymous));

            -- Find starting point for this in symbol table,
            -- inserting it if necessary.

            if V_Flag = Anonymous then
               -- Each anonymous variable is a variable, it doesn't "share".

               Token := Insert_Variable (Symbol_Table_Pos);

            elsif V_Flag = Variable then
               -- For variables see if this name already occurred in this
               --clause.

               -- starting search var
               if Variable_Ptr /= null then
                  V_Index := Variable_Ptr;

                  while V_Index /= null loop
                     if V_Index.Variable.Symbol = Symbol_Table_Pos then
                        Variable_Found := True;
                        exit;
                     end if;
                     V_Index := Get_Prev_Var (V_Index);
                  end loop;
               end if;

               if Variable_Found then
                  V_Index.Variable.Refs := V_Index.Variable.Refs + 1;
                  Token                 := Make_Variable (V_Index.Variable);
               else
                  Token := Insert_Variable (Symbol_Table_Pos);
               end if;

            --if Symbol_Table_Pos is Builtin then
            elsif (Symbol_Table_Pos.Refs = 0) and
                  (not Is_String) and
                  (not Is_Quote)
            then
               -- Probably can fold this into Make_Atom

               Token := Make_Builtin (Find_Predicate (Symbol_Table_Pos));

            else

               -- Word must be a program defined atom,
               -- return the pointer into the symbol table.

               if Symbol_Table_Pos.Refs = 0 then
                  Symbol_Table_Pos.Refs := 1;  -- quoted builtin overidden
                  Token                 := Make_Atom (Symbol_Table_Pos);
                  Symbol_Table_Pos.Refs := 0;
               else
                  Token := Make_Atom (Symbol_Table_Pos);
               end if;

            end if;

            return (Token);

         end Lex_Words;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Scan_Special_Symbol          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Scan_Special_Symbol return Goal_Value is

            --| Purpose
            --| Scan_Special_Symbol scans special symbol sequences and to
            --determine
            --| if token is a builtin.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Start, Stop : Clause_String_Range;
            -- Same as for ordinary words.

            Symb             : Character;
            Symbol_Table_Pos : Symbol_String;
            Token            : Goal_Value;
            Pred             : Builtin_Range;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Classify_Minus               *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Classify_Minus return Builtin_Range is

               --| Purpose
               --| Classify a minus symbol as being unary or binary.  This is
               --distinguished
               --| by different token values (note 2 minus symbols).
               --| The rule for distinguishing a unary minus is that a minus
               --symbol is
               --| unary if the last non-paranthetic symbol before the minus
               --| is an operation symbol or does not exist.
               --|
               --| Exceptions
               --|
               --| Notes
               --|
               --| Modifications
               --| October 25, 1991  Paul Pukite  Initial Version
               --| April 26, 1993    PP           Heap extensions

               I : Token_Range;

            begin

               if Lex_Position = Token_Range'First then
                  return Bips.P_Uminus;
               end if;

               -- Start from current position.
               I := Lex_Position - 1;
               ---
               -- This is probably only correct for Prolog-style
               ---
               if Is_Builtin_Token (Lex_Table (I), Bips.P_Lrb) or
                  Is_Builtin_Token (Lex_Table (I), Bips.P_Lsqb)
               then
                  return Bips.P_Uminus;
               end if;

               while I >= Token_Range'First and
                     Bips.Parenthetic (Lex_Table (I))
               loop
                  I := I - 1;
               end loop;

               if Bips.Operation (Lex_Table (I)) then
                  return Bips.P_Uminus;
               else
                  return Bips.P_Bminus;
               end if;

            end Classify_Minus;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Not_Symbol                   *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Not_Symbol (Char : in Character) return Boolean is

            --| Purpose
            --| Not_Symbol returns TRUE if the Char character is not found in
            --| the valid symbol list.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            begin
               for I in  Symbol_List'Range loop
                  if Char = Symbol_List (I) then
                     return (False);
                  end if;
               end loop;
               return (True);

            end Not_Symbol;

         begin

            Start := Clause_Position;
            -- Clause_Position has been backed up to start this symbol
            --sequence.

            if Not_Symbol (Clause_String (Start)) then
               Stop := Start;
               -- Other special symbols cannot be part of symbol sequence.

               Clause_Position := Clause_Position + 1;

            else
               loop
                  Clause_Position := Clause_Position + 1;
                  Symb            := Clause_String (Clause_Position);
                  exit when Symb = ASCII.NUL or else Not_Symbol (Symb);
                  -- Skip to end of symbol.
               end loop;

               Stop := Clause_Position - 1;
               -- End point of symbol sequence.

            end if;

            Symbol_Table_Pos := Add_Word (Clause_String (Start .. Stop));
            -- Add this word to the symbol table.

            --if Symbol_Table_Pos is Builtin then
            if Symbol_Table_Pos.Refs = 0 then
               -- Probably can fold this into Make_Atom
               Pred := Find_Predicate (Symbol_Table_Pos);
               if Pred = Bips.P_Uminus then
                  Token := Make_Builtin (Classify_Minus);
               else
                  Token := Make_Builtin (Pred);
               end if;
            else
               Token := Make_Atom (Symbol_Table_Pos);
            end if;

            return (Token);

         end Scan_Special_Symbol;

         -- **********************************
         -- *                                *
         -- *   Clear_Table                  *  BODY
         -- *                                *
         -- **********************************
         procedure Clear_Table is
         begin
            for I in  Lex_Table'Range loop
               exit when Lex_Table (I) = null;
               Lex_Table (I) := null;
            end loop;
            Lex_Position := Token_Range'First;  -- First open position in
                                                --Lex_Table.
         end Clear_Table;

         -- **********************************
         -- *                                *
         -- *   Tokenize                     *  BODY
         -- *                                *
         -- **********************************
         procedure Tokenize (Token_Input : in Boolean) is

            --| Notes
            --| Main lexical analysis.

            Symb  : Character;
            Token : Goal_Value;

            procedure Increment_Clause is
            begin
               Variable_Ptr := null;
            end Increment_Clause;

         begin

            if Token_Input then  -- Do not have to analyze fact input
               Increment_Clause;
               return;
            end if;

            Clear_Table;

            Clause_Position := Clause_String_Range'First;
            -- Start position in Clause_String.
            -- Clause_Position will always point to the first unused symbol.
            -- Clause_String contains a NUL character at the
            -- end of the string of valid characters.

            loop

               Symb := Clause_String (Clause_Position);
               exit when Symb = ASCII.NUL;

               -- Branch according to classification of symbol.

               if Symb = ' ' then    -- Imbedded blank is spaced over.

                  while Symb = ' ' loop
                     Clause_Position := Clause_Position + 1;
                     Symb            := Clause_String (Clause_Position);
                  end loop;

                  Token := null;
               -- Each Clause_String ends with something nonblank (ASCII.NUL).

               elsif Numeric (Symb) then  -- Integer number.

                  Token := Lex_Number;

               elsif Alpha (Symb) or
                     Symb = '_' or
                     Symb = '"' or
                     Symb = '''
               then
                  -- Variables and alpha symbols.
                  Token := Lex_Words;

               else

                  -- Symbols: symbol sequences can also be special characters
                  -- such as + - * / ^ < > = : . ?
                  -- The symbols ! , { } [ ] | ( ) occur only as single symbol
                  --tokens.

                  Token := Scan_Special_Symbol;

               end if;

               if Token /= null then      -- any illegal symbol sequence
                                          --ignored.

                  Push_Lex (Token);

               end if;

            end loop;    -- End of while ( symb /= NUL ) loop.

            if Lex_Position > Token_Range'First then
               Lex_Position := Lex_Position - 1;
            end if;

            Token := Lex_Table (Lex_Position);

            if Token.Content = Bip
              and then Token.Builtin = Bips.P_Period
            then
               Lex_Table (Lex_Position) := Eot;
            end if;

            Increment_Clause;

         end Tokenize;

         -- **********************************
         -- *                                *
         -- *   Purge_Query                  *  BODY
         -- *                                *
         -- **********************************
         procedure Purge_Query (Query : in Goal_Value) is

         --| Notes
         --| Remove the query from the linked list.
         --| Not used in heap mode.

         begin

            null; -- NOT USED

         exception
            when others =>
               raise Rule_Errors.Variable_Table_Error;

         end Purge_Query;

         -- **********************************
         -- *                                *
         -- *   Push_Lex                     *  BODY
         -- *                                *
         -- **********************************
         procedure Push_Lex (Token : in Goal_Value) is

         --| Purpose
         --| Push_Lex adds a token to the Lex Table.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| November 9, 1991  Paul Pukite   Initial Version
         --| April 26, 1993    PP           Heap extensions

         begin
            Lex_Table (Lex_Position) := Token;
            -- Store the new token and advance.
            Lex_Position := Lex_Position + 1;
            if Lex_Position = Lex_Table'Last then
               raise Rule_Errors.Lex_Error;
            end if;
         end Push_Lex;

         -- **********************************
         -- *                                *
         -- *   Initialize_Lex               *  BODY
         -- *                                *
         -- **********************************
         procedure Initialize_Lex
           (In_Toks : in Token_Range;
            Hash    : in Symbol_Hash_Table_Range)
         is
         begin

            Lex_Table     := new Token_Array (Token_Range'First .. In_Toks);
            Lex_Table.all := (others => null);

            Symbol_Hash_Table     :=
              new Symbol_Hash_Array (Symbol_Hash_Table_Range'First .. Hash);
            Symbol_Hash_Table.all := (others => null);
            -- Make and Clear the hash area.

            Variable_Ptr := null;
            -- Points to free position in the variable table.

            Hash_Keywords;
            -- Place initialization values for the symbol table.
            -- Update predefined predicate pointers to the symbol table
            --entries.

            Eot := Make_Builtin (Bips.P_Eot);

         end Initialize_Lex;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Mark_Cell                     *  BODY
         -- *                                *
         -- **********************************
         procedure Mark_Cell (Gv : in Goal_Value) is

            --| Purpose
            --| See spec.
            --|
            --| Exceptions (none)
            --| Notes
            --| Should be procedure with an in out value.
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Temp : Goal_Value := Gv;
         begin
            Temp.Mark := not Temp.Mark;
            Prev_Gv   := Gv;
         end Mark_Cell;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Marked                     *  BODY
         -- *                                *
         -- **********************************
         function Is_Marked (Gv : Goal_Value) return Boolean is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return not Gv.Mark;
         end Is_Marked;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Builtin_Token              *  BODY
         -- *                                *
         -- **********************************
         function Is_Builtin_Token
           (Gv    : in Goal_Value;
            Token : in Builtin_Range)
            return  Boolean
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv /= null
                  and then Gv.Content = Bip
                  and then Gv.Builtin = Token;
         end Is_Builtin_Token;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Builtin                    *  BODY
         -- *                                *
         -- **********************************
         function Is_Builtin (Gv : in Goal_Value) return Boolean is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv /= null and then Gv.Content = Bip;
         end Is_Builtin;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_BIP                       *  BODY
         -- *                                *
         -- **********************************
         function Get_Bip (Gv : in Goal_Value) return Builtin_Range is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv.Builtin;
         end Get_Bip;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Int                       *  BODY
         -- *                                *
         -- **********************************
         function Get_Int (Gv : in Goal_Value) return Calc_Int is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv.Number;
         end Get_Int;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Flt                       *  BODY
         -- *                                *
         -- **********************************
         function Get_Flt (Gv : in Goal_Value) return Calc_Flt is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv.Fvalue;
         end Get_Flt;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Sym                       *  BODY
         -- *                                *
         -- **********************************
         function Get_Sym (Gv : in Goal_Value) return String is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| December 5, 1999  added warning stopper

         begin

            if Gv.Content = Sym then
               return Gv.Symbol.Str;
            elsif Gv.Content = Var then
               return Gv.Variable.Symbol.Str;
            elsif Gv.Content = Bip then
               return Bips.Predicate_Table (Get_Bip (Gv)).Str;
            else -- Stops warning
               raise Program_Error;
               return "";
            end if;

         end Get_Sym;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Float                      *  BODY
         -- *                                *
         -- **********************************
         function Is_Float (Token : in Goal_Value) return Boolean is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Token /= null and then Token.Content = Flt;
         end Is_Float;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Integer                    *  BODY
         -- *                                *
         -- **********************************
         function Is_Integer (Token : in Goal_Value) return Boolean is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Token /= null and then Token.Content = Int;
         end Is_Integer;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  NIL                           *  BODY
         -- *                                *
         -- **********************************
         function Nil return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Nil_Value;
         end Nil;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Wild_Card                     *  BODY
         -- *                                *
         -- **********************************
         function Wild_Card return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Wild_Card_Value;
         end Wild_Card;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Same                          *  BODY
         -- *                                *
         -- **********************************
         function Same (L1, L2 : in Goal_Value) return Boolean is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| July 6, 1993      PP             Var comparison added Refs to
         --distinguish symbols from different clauses.
         --| July 15, 1993     PP             Speeded up logical ops

         begin
            if L1 = null then
               return L2 = null;
            elsif L2 = null then
               return False;
            elsif L1.Content /= L2.Content then
               return False;
            end if;
            case L1.Content is
               when Int =>
                  return L1.Number = L2.Number;
               when Var =>
                  return L1.Variable = L2.Variable;
               when Sym =>
                  return L1.Symbol = L2.Symbol;
               when Bip =>
                  return L1.Builtin = L2.Builtin;
               when Lis =>
                  return L1.First = L2.First;
               when Flt =>
                  return L1.Fvalue = L2.Fvalue;
               when others =>
                  return False;
            end case;
         end Same;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Next_Var                  *  BODY
         -- *                                *
         -- **********************************
         function Get_Next_Var (Gv : in Goal_Value) return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv.Variable.Forward;
         end Get_Next_Var;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Prev_Var                  *  BODY
         -- *                                *
         -- **********************************
         function Get_Prev_Var (Gv : in Goal_Value) return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv.Variable.Previous;
         end Get_Prev_Var;

         -- **********************************
         -- *                                *
         -- *   Set_CAR                      *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Car
           (Pointer   : in out Goal_Value;
            Car_Value : in Goal_Value)
         is
         begin
            if Pointer /= null then
               Pointer.First := Car_Value;
            end if;
         end Set_Car;

         -- **********************************
         -- *                                *
         -- *   Set_CDR                      *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Cdr
           (Pointer   : in out Goal_Value;
            Cdr_Value : in Goal_Value)
         is
         begin
            if Pointer /= null then
               Pointer.Next := Cdr_Value;
            end if;
         end Set_Cdr;

         -- **********************************
         -- *                                *
         -- *   CAR                          *  BODY
         -- *                                *
         -- **********************************
         function Car (Pointer : in Goal_Value) return Goal_Value is
         begin
            if Pointer /= null then
               if Pointer.Content = Lis then
                  return Pointer.First;
               end if;
            end if;
            return Pointer;
         end Car;

         -- **********************************
         -- *                                *
         -- *   CDR                          *  BODY
         -- *                                *
         -- **********************************
         function Cdr (Pointer : in Goal_Value) return Goal_Value is
         begin
            if Pointer /= null then
               return Pointer.Next;
            else
               return null;
            end if;
         end Cdr;

         -- **********************************
         -- *                                *
         -- *   CAAR                         *  BODY
         -- *                                *
         -- **********************************
         function Caar (Ptr : in Goal_Value) return Goal_Value is
         begin
            return (Car (Car (Ptr)));
         end Caar;

         -- **********************************
         -- *                                *
         -- *   CADR                         *  BODY
         -- *                                *
         -- **********************************
         function Cadr (Ptr : in Goal_Value) return Goal_Value is
         begin
            return (Car (Cdr (Ptr)));
         end Cadr;

         -- **********************************
         -- *                                *
         -- *   CDDR                         *  BODY
         -- *                                *
         -- **********************************
         function Cddr (Ptr : in Goal_Value) return Goal_Value is
         begin
            return (Cdr (Cdr (Ptr)));
         end Cddr;

         -- **********************************
         -- *                                *
         -- *   CAADR                        *  BODY
         -- *                                *
         -- **********************************
         function Caadr (Ptr : in Goal_Value) return Goal_Value is
         begin
            return (Car (Car (Cdr (Ptr))));
         end Caadr;

         -- **********************************
         -- *                                *
         -- *   CADDR                        *  BODY
         -- *                                *
         -- **********************************
         function Caddr (Ptr : in Goal_Value) return Goal_Value is
         begin
            return (Car (Cdr (Cdr (Ptr))));
         end Caddr;

         -- **********************************
         -- *                                *
         -- *   Set_CAR_CDR                  *  BODY
         -- *                                *
         -- **********************************
         function Set_Car_Cdr
           (Car_Value, Cdr_Value : in Goal_Value)
            return                 Goal_Value
         is

         --| Notes
         --| Set both the CAR and CDR for a cell.

         begin
            Num_Goals := Num_Goals + 1;
            return Save
                     (new Goal_Value_Record'
              (Content => Lis,
               Next    => Cdr_Value,
               Mark    => True,
               Link    => null,
               First   => Car_Value));

         exception
            when others =>
               raise Rule_Errors.Links_Error;

         end Set_Car_Cdr;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Next_Link                     *  BODY
         -- *                                *
         -- **********************************
         function Next_Link (Gv : Goal_Value) return Goal_Value is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            return Gv.Link;
         end Next_Link;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Delete_Link                   *  BODY
         -- *                                *
         -- **********************************
         procedure Delete_Link (Gv : in out Goal_Value) is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --| Delete symbol is not implemented yet (keep symbol table
         --persistent).
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            if Is_Variable (Gv) then
               if Gv.Variable /= null then
                  if Gv.Variable.Refs > 1 then
                     Gv.Variable.Refs        := Gv.Variable.Refs - 1;
                     Gv.Variable.Symbol.Refs := 1;
                  else
                     Gv.Variable.Symbol.Refs := 1;
                     Free (Gv.Variable);
                  end if;
               end if;
            elsif Is_Atomic (Gv) then
               Gv.Symbol.Refs := 1;
            end if;
            Free (Gv);
         end Delete_Link;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Link                      *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Link (Gv : in out Goal_Value; Next : in Goal_Value) is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Gv.Link := Next;
         end Set_Link;

         -- **********************************
         -- *                                *
         -- *  Get_Variable                  *  BODY
         -- *                                *
         -- **********************************
         function Get_Variable (Gv : in Goal_Value) return Instance is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 6, 1993    Paul Pukite    Initial Version

         begin
            if Gv /= null and then Gv.Content = Var then
               return Gv.Variable;
            else
               return null;
            end if;
         end Get_Variable;

      end Lexical_Analysis;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Linked_List                  *  BODY
      -- *                                *
      -- **********************************
      package body Linked_List is

         --| Purpose
         --| Package body for Linked_List
         --|
         --| Exceptions
         --|
         --| Notes
         --| This module contains the routines for setting up the major
         --| linked lists used by the interpreter.
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         package Bips renames Builtin_Predicates;

         type Conversion_Stack_Range is new Table_Sizes.Integer_Ptr range
            0 .. Table_Sizes.Conversion_Stack_Max;
         -- Stack for convertion to links.

         Conversion_Stack     :
           array (Conversion_Stack_Range) of Lex.Goal_Value;
         Conversion_Stack_Ptr : Conversion_Stack_Range :=
            Conversion_Stack_Range'First;

         function Nil return Lex.Goal_Value renames Lex.Nil;

         The_Clause_List : Lex.Goal_Value;   -- Global starting point to all
                                             --clauses,
         -- these are indexed by functor

         Cells_Used : Rule_Errors.Count; -- count of cells used at any time

         Collect : Boolean; -- variable signaling whether GC has to be done

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Clause_List                   *  BODY
         -- *                                *
         -- **********************************
         function Clause_List return Lex.Goal_Value is
         begin
            return The_Clause_List;
         end Clause_List;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Collect                   *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Collect is
         begin
            Collect := True;
         end Set_Collect;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Links               *  BODY
         -- *                                *
         -- **********************************
         function Number_Of_Links return Rule_Errors.Count is
         begin
            return Cells_Used;
         end Number_Of_Links;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Push                         *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Push (Token : in Lex.Goal_Value) is

         --| Purpose
         --| Push onto conversion stack.
         --|
         --| Exceptions
         --| PARSE_ERROR if stack overflow
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         begin
            Conversion_Stack (Conversion_Stack_Ptr) := Token;
            if Conversion_Stack_Ptr >= Conversion_Stack_Range'Last then
               raise Rule_Errors.Parse_Error;
            end if;
            Conversion_Stack_Ptr := Conversion_Stack_Ptr + 1;
         end Push;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Pop                          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Pop return Lex.Goal_Value is

         --| Purpose
         --| Pop from conversion stack.
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         begin
            Conversion_Stack (Conversion_Stack_Ptr) := Nil;
            Conversion_Stack_Ptr                    := Conversion_Stack_Ptr -
                                                       1;
            return (Conversion_Stack (Conversion_Stack_Ptr));
         end Pop;

         -- **********************************
         -- *                                *
         -- *   Set_CAR                      *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Car
           (Pointer   : in Lex.Goal_Value;
            Car_Value : in Lex.Goal_Value)
         is
            Temp : Lex.Goal_Value := Pointer;
         begin
            Lex.Set_Car (Temp, Car_Value);
         end Set_Car;

         -- **********************************
         -- *                                *
         -- *   Set_CDR                      *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Cdr
           (Pointer   : in Lex.Goal_Value;
            Cdr_Value : in Lex.Goal_Value)
         is
            Temp : Lex.Goal_Value := Pointer;
         begin
            Lex.Set_Cdr (Temp, Cdr_Value);
         end Set_Cdr;

         -- **********************************
         -- *                                *
         -- *   Find_Principal_ID            *  BODY
         -- *                                *
         -- **********************************
         function Find_Principal_Id
           (Token : in Lex.Goal_Value)
            return  Lex.Goal_Value
         is

         --| Notes
         --| This dissects the clause structure, to find the principal
         --identifier
         --| in a clause. Check first whether the
         --| clause is a rule (CAR == P_IF).  If so, take the CADR = head of
         --rule
         --| and obtain its CAR.  Otherwise, the CAR of the clause is the PID.

         begin
            if Lex.Is_Builtin_Token (Lex.Car (Token), Bips.P_If) then
               return (Lex.Caadr (Token));
            else
               return (Lex.Car (Token));
            end if;
         end Find_Principal_Id;

         -- **********************************
         -- *                                *
         -- *   Is_Evaluated                 *  BODY
         -- *                                *
         -- **********************************
         function Is_Evaluated (Token : in Lex.Goal_Value) return Boolean is

         --| Notes
         --| To check whether a clause has to be evaluated,
         --| the first element in the list is P_QUERY (i.e. ?).

         begin
            return Lex.Is_Builtin_Token (Lex.Car (Token), Bips.P_Query);
         end Is_Evaluated;

         -- **********************************
         -- *                                *
         -- *   Convert                      *  BODY
         -- *                                *
         -- **********************************
         function Convert return Lex.Goal_Value is

            --| Notes
            --| The following function converts the tokens in the array
            --Prefix.Lextab into
            --| a linked list stored in the heap.

            Top, Top1 : Lex.Goal_Value;   -- Top and top1 are pulled off stack.
            Token     : Lex.Goal_Value;

            function "-" (L, R : Lex.Token_Range) return Lex.Token_Range
               renames Lex. "-";
         begin

            Conversion_Stack_Ptr := Conversion_Stack_Range'First;

            -- Start scanning stream of tokens.

            for Position in  Lex.First_Token .. Prefix.Last_Tok_Pos - 1 loop
               -- Scan until end of token stream.

               --Token := Prefix.Lextab ( Position );
               Token := Prefix.Get_Tok (Position);

               if not Lex.Is_Builtin_Token (Token, Bips.P_Rrb) then
                  Push (Token);
               else
                  Top  := Nil;             -- Indicator for null list.
                  Top1 := Pop;             -- Prepare to construct a new cell.

                  while not Lex.Is_Builtin_Token (Top1, Bips.P_Lrb) loop
                     -- Build all new cells at current level.

                     Top  := Set_Car_Cdr (Top1, Top);
                     Top1 := Pop;

                  end loop;
                  Push (Top);
               end if;
            end loop;

            return (Pop);

         end Convert;

         -- **********************************
         -- *                                *
         -- *   Update_Clause_List           *  BODY
         -- *                                *
         -- **********************************
         procedure Update_Clause_List (Clause : in Lex.Goal_Value) is

            --| Notes
            --| Update the linked list holding the clauses which are active.

            Pid, Temp_Clause_List : Lex.Goal_Value;

         begin

            -- Main functor of clause and
            -- list associated with this functor
            Pid              := Find_Principal_Id (Clause);
            Temp_Clause_List :=
               Associated_List (Lex.Cdr (The_Clause_List), Pid);

            -- Find the list of associated clauses.
            -- This list will be NIL if no reference to PID is found.
            -- Note that CAR of The_Clause_List is always NIL.

            if Lex.Is_Nil (Temp_Clause_List) then

               -- Make the associated list for this PID.
               Temp_Clause_List := Set_Car_Cdr (Pid, Nil);
               Construct (The_Clause_List, Temp_Clause_List);

            end if;

            Construct (Temp_Clause_List, Clause);
            -- Add the new clause to this list.

         exception

            when others =>
               raise Rule_Errors.Clist_Error;

         end Update_Clause_List;

         -- **********************************
         -- *                                *
         -- *   Associated_List              *  BODY
         -- *                                *
         -- **********************************
         function Associated_List
           (List, Index_Item : in Lex.Goal_Value)
            return             Lex.Goal_Value
         is

            --| Notes
            --| Find the list associated with an index item.

            Index      : Lex.Goal_Value;
            Local_List : Lex.Goal_Value := List;
         -- Temporary index and list.

         begin

            Index := Lex.Caar (Local_List);
            -- Find index of first element of list.

            if Lex.Is_Goal (Index) then
               -- CAR of NIL is NIL.

               loop
                  if Lex.Same (Index, Index_Item) then
                     return (Lex.Car (Local_List));
                  -- Return the PID of list.

                  else
                     Local_List := Lex.Cdr (Local_List);
                     -- Search until item is found.

                     Index := Lex.Caar (Local_List);
                  end if;
                  exit when Lex.Is_Nil (Local_List);
               end loop;
            end if;

            return (Nil);
            -- Indicates index item was not found.

         end Associated_List;

         -- **********************************
         -- *                                *
         -- *   Construct                    *  BODY
         -- *                                *
         -- **********************************
         procedure Construct (List, Item : in Lex.Goal_Value) is

            --| Notes
            --| Attach an object to the end of a list.
            --| Same as LISP function called CONS.

            Local_List : Lex.Goal_Value := List;
            Temp       : Lex.Goal_Value;
         begin

            if Lex.Is_Nil (Local_List) then
               -- Create a modifiable NIL cell if needed.
               Local_List := Set_Car_Cdr (Nil, Nil);
            end if;

            while Lex.Is_Goal (Lex.Cdr (Local_List)) loop
               Local_List := Lex.Cdr (Local_List);
            end loop;

            -- When only one element in list, attach item to the end of the
            --list.
            Temp := Set_Car_Cdr (Item, Nil);
            Set_Cdr (Local_List, Temp);

         end Construct;

         -- **********************************
         -- *                                *
         -- *   Set_CAR_CDR                  *  BODY
         -- *                                *
         -- **********************************
         function Set_Car_Cdr
           (Car_Value, Cdr_Value : in Lex.Goal_Value)
            return                 Lex.Goal_Value
         is

         --| Notes
         --| Set both the CAR and CDR for a cell.

         begin
            return Lex.Set_Car_Cdr (Car_Value, Cdr_Value);
         end Set_Car_Cdr;

         -- **********************************
         -- *                                *
         -- *   Garbage_Collect              *  BODY
         -- *                                *
         -- **********************************
         procedure Garbage_Collect is

            --| Notes
            --| Garbage collection can be initiated at any time.  Currently
            --the setup
            --| is to initiate it if, at the time of starting a deduction, the
            --boolean
            --| variable Collect is true.

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Mark_List                    *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Mark_List (Cell : in Lex.Goal_Value) is

            --| Purpose
            --| Mark all the cells which are accessible from the current set
            --of clauses
            --| for garbage collection.  First part of a mark and sweep
            --algorithm.
            --| This marks the CDR cell by setting a mark bit within this cell
            --and then
            --| makes recursive calls to the CAR and CDR cells.  This is
            --internal to
            --| Garbage_Collect.
            --|
            --| Exceptions
            --|
            --| Notes
            --| This is recursive.
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            begin

               if Lex.Is_Nil (Cell) then
                  return;
               end if;

               if Lex.Is_Marked (Cell) then
                  return;
               else
                  Lex.Mark_Cell (Cell);  -- Mark the current cell.
               end if;

               if not Lex.Is_List (Cell) then
                  return;
               end if;

               Mark_List (Lex.Car (Cell));
               Mark_List (Lex.Cdr (Cell));
               -- Make recursive calls to further cells to be marked.

            end Mark_List;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Sweep                        *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Sweep is

               --| Purpose
               --| Sweep collects all the cells that have been marked during
               --garbage collection.
               --| Internal to Garbage_Collect.
               --|
               --| Exceptions
               --|
               --| Notes
               --|
               --| Modifications
               --| October 25, 1991  Paul Pukite  Initial Version

               Previous, Head, Temp : Lex.Goal_Value;
               First_Free_Point     : Boolean := True;
            begin

               Cells_Used := 1;  -- Set the number of cells used to get first
                                 --unmarked cell.

               Head     := The_Clause_List;
               Previous := Head;

               loop
                  exit when Lex.Is_Nil (Head);
                  if Lex.Is_Marked (Head) then    -- If this cell is marked,
                     Cells_Used := Cells_Used + 1;    -- increase count of
                                                      --used cells.
                     Lex.Mark_Cell (Head);
                     Previous := Head;
                     Head     := Lex.Next_Link (Head);
                  else
                     Temp := Head;
                     Head := Lex.Next_Link (Head);
                     Lex.Set_Link (Previous, Head);
                     Lex.Delete_Link (Temp);
                  end if;

               end loop;

            end Sweep;

         begin -- Garbage_Collect

            if not Collect then
               return;
            end if;

            Collect := False;
            -- Reset the flag which triggered the garbage collection.

            Mark_List (The_Clause_List);
            -- Mark all the accessible clauses.

            Sweep;
            -- Collect all inaccessible cells and return these to the free
            --list.

         exception
            when Constraint_Error =>
               raise Rule_Errors.Garbage_Collection_Error;
            when others =>
               raise;

         end Garbage_Collect;

         -- **********************************
         -- *                                *
         -- *   Purge_Clause                 *  BODY
         -- *                                *
         -- **********************************
         procedure Purge_Clause (Clause : in Lex.Goal_Value) is

         --| Notes
         --| If something goes wrong in the process of converting input into
         --linked
         --| lists (or when converting anything into the linked list form)
         --then call
         --| Purge_Clause to clean the list off.  If garbage collection is
         --used then
         --| this cleaning can be done simply by destroying the pointers for
         --| eventual recovery by the garbage collector.

         begin

            Set_Car (Clause, Nil);
            Set_Cdr (Clause, Nil);

         end Purge_Clause;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Heap_Walk                     *  BODY
         -- *                                *
         -- **********************************
         function Heap_Walk return Boolean is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            --   LEX.Get_Prev ( Box_List );
            --   return TRUE;
            --exception
            --   when others =>
            return False;
         end Heap_Walk;

         -- **********************************
         -- *                                *
         -- *   Clean_Clause_List            *  BODY
         -- *                                *
         -- **********************************
         procedure Clean_Clause_List (Clause : in Lex.Goal_Value) is

            --| Notes
            --| Clean off a clause from The_Clause_List - the association list
            --of
            --| principal ID's and clauses which belong to these principal
            --identifiers.

            Pid, Local_Clause_List : Lex.Goal_Value;
         begin
            Pid               := Find_Principal_Id (Clause);
            Local_Clause_List :=
               Lex.Cdr (Associated_List (The_Clause_List, Pid));
            while Lex.Is_Goal (Local_Clause_List) loop
               if Lex.Is_Goal (Lex.Car (Local_Clause_List)) then
                  Set_Car (Local_Clause_List, Nil);
                  return;
               end if;
               Local_Clause_List := Lex.Cdr (Local_Clause_List);
            end loop;
         end Clean_Clause_List;

         -- **********************************
         -- *                                *
         -- *   Initialize_Links             *  BODY
         -- *                                *
         -- **********************************
         procedure Initialize_Links is
         begin

            -- Initialize the linked list area.

            Cells_Used := 1;  -- First cell is always used.
            Collect    := False;
            -- Initialize the main variables used by the garbage collector

            The_Clause_List := Set_Car_Cdr (Nil, Nil);
            -- No clauses yet.

            Conversion_Stack_Ptr := Conversion_Stack_Range'First;

         end Initialize_Links;

      end Linked_List;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *  Text_Server                   *  SPEC
      -- *                                *
      -- **********************************
      package Text_Server is

         --| Purpose
         --| Windows console Text_IO replacement
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version
         --| June 23, 1993     PP             Increased Max_String from 100 to
         --128

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Write                         *  SPEC
         -- *                                *
         -- **********************************
         procedure Write (Str : in String);

         --| Purpose
         --| Write string to console.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         procedure Set_Write (Proc : Write_Proc);

      end Text_Server;

      package body Text_Server is

         P : Write_Proc := null;

         procedure Write (Str : in String) is
         begin
            if P = null then
               null;
            else
               P (Str);
            end if;
         end Write;

         procedure Set_Write (Proc : Write_Proc) is
         begin
            P := Proc;
         end Set_Write;

      end Text_Server;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *  Con_IO                        *  BODY
      -- *                                *
      -- **********************************
      package Con_Io is

         --| Purpose
         --| Provides portable console-like interface to Standard or Auxiliary
         --display.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  New_Line                      *  SPEC
         -- *                                *
         -- **********************************
         procedure New_Line (Aux : in Boolean := False);

         --| Purpose
         --| Puts a CR.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Put                           *  SPEC
         -- *                                *
         -- **********************************
         procedure Put (Ch : in Character; Aux : in Boolean := False);

         --| Purpose
         --| Puts a character.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Put                           *  SPEC
         -- *                                *
         -- **********************************
         procedure Put (Str : in String; Aux : in Boolean := False);

         --| Purpose
         --| Puts a string.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Put_Line                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Put_Line (Str : in String; Aux : in Boolean := False);

         --| Purpose
         --| Puts a string and CR
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Line                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Get_Line
           (Str : out String;
            Len : out Integer;
            Aux : in Boolean := False);

         --| Purpose
         --| Get a string terminated with CR.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Execute                       *  SPEC
         -- *                                *
         -- **********************************
         function Execute
           (Str  : in String;
            Post : in Boolean := False)
            return Boolean;

         --| Purpose
         --| Execute another program or Post a message to main application.
         --|
         --| Exceptions (none)
         --| Notes
         --| This is mainly for Windows applications
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Exchange                      *  SPEC
         -- *                                *
         -- **********************************
         procedure Exchange
           (Request : in Integer;
            Input   : in String;
            Output  : out String;
            Len     : out Integer;
            Status  : out Integer);

         --| Purpose
         --| DDE interface to Windows. Sends a Request identifier with Input
         --data,
         --| then waits until receives an Output string of length Len.
         --Non-zero
         --| Status indicates a valid return.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 23, 1993    Paul Pukite    Initial Version

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  TextIO                        *  SPEC
         -- *                                *
         -- **********************************
         function Textio return Boolean;

         --| Purpose
         --| Return TRUE if console only accepts Text_IO.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| October 11, 1993    Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_On                         *  SPEC
         -- *                                *
         -- **********************************
         function Is_On return Boolean;

         --| Purpose
         --| Return TRUE if console has been initialized.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| October 11, 1993    Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_TextIO                    *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Textio (On : in Boolean);

         --| Purpose
         --| Set TRUE if console only accepts Text_IO.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| October 11, 1993    Paul Pukite    Converted from global data

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Console                   *  SPEC
         -- *                                *
         -- **********************************
         procedure Set_Console (On : in Boolean);

         --| Purpose
         --| Set TRUE if console to initialize.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| October 11, 1993    Paul Pukite    Converted from global data

         Post_Proc : Write_Proc := null;

      end Con_Io;

      package body Con_Io is

         Textio_On : Boolean := False;   -- Accept only Text_IO input/output

         Console_On : Boolean := False;    -- Turn off/on console

         Carriage_Return : constant String (1 .. 2) :=
           (1 => ASCII.CR,
            2 => ASCII.LF);
         Single_Char     : String (1 .. 1);

         procedure New_Line (Aux : in Boolean := False) is
         begin
            if Console_On or not Aux then
               if Textio_On then
                  if Aux then
                     Text_IO.New_Line (Text_IO.Current_Error);
                  else
                     Text_IO.New_Line;
                  end if;
               else
                  Text_Server.Write (Carriage_Return);
               end if;
            end if;
         end New_Line;

         procedure Put (Ch : in Character; Aux : in Boolean := False) is
         begin
            if Console_On or not Aux then
               Single_Char (1) := Ch;
               if Textio_On then
                  if Aux then
                     Text_IO.Put (Text_IO.Current_Error, Ch);
                  else
                     Text_IO.Put (Ch);
                  end if;
               else
                  Text_Server.Write (Single_Char);
               end if;
            end if;
         end Put;

         procedure Put (Str : in String; Aux : in Boolean := False) is
         begin
            if Console_On or not Aux then
               if Textio_On then
                  if Aux then
                     Text_IO.Put (Text_IO.Current_Error, Str);
                  else
                     Text_IO.Put (Str);
                  end if;
               else
                  Text_Server.Write (Str);
               end if;
            end if;
         end Put;

         procedure Put_Line (Str : in String; Aux : in Boolean := False) is
         begin
            if Console_On or not Aux then
               if Textio_On then
                  if Aux then
                     Text_IO.Put_Line (Text_IO.Current_Error, Str);
                  else
                     Text_IO.Put_Line (Str);
                  end if;
               else
                  Text_Server.Write (Str & Carriage_Return);
               end if;
            end if;
         end Put_Line;

         procedure Get_Line
           (Str : out String;
            Len : out Integer;
            Aux : in Boolean := False)
         is
         begin
            if Console_On or not Aux then
               if Textio_On then
                  Text_IO.Get_Line (Str, Len);
                  --else
                  --   Text_Server.Read(Str,Len);
               end if;
            else
               Str (Str'First .. Str'First + 1) := "no";
               Len          := 2;
            end if;
         end Get_Line;

         Nargs : constant Natural := Ada.Command_Line.Argument_Count;
         Post_Error : exception;  -- something that will raise to top level

         function Execute
           (Str  : in String;
            Post : in Boolean := False)
            return Boolean
         is
         begin
            if Post then
               if Con_Io.Post_Proc = null then
                  return False;
               else
                  Con_Io.Post_Proc (Str);
                  return True;
               end if;
            else
               for I in  1 .. Nargs loop
                  if Str = Ada.Command_Line.Argument (I) then
                     return True;
                  end if;
               end loop;
               return False;
            end if;
         exception
            when others =>
               if Post then
                  raise Post_Error;
               else
                  raise;
               end if;
         end Execute;

         function Argument
           (Key  : in String;
            Pos  : in Integer)
            return String
         is
         begin
            if Pos < 0 then
               return Getenv (Key, "");
            else
               for I in  1 .. Nargs loop
                  if Key = Ada.Command_Line.Argument (I)
                    and then I + Pos <= Nargs
                  then
                     return Ada.Command_Line.Argument (I + Pos);
                  end if;
               end loop;
            end if;
            return "";
         end Argument;

         procedure Exchange
           (Request : in Integer;
            Input   : in String;
            Output  : out String;
            Len     : out Integer;
            Status  : out Integer)
         is
            Arg : constant String := Argument (Input, Request);
         begin
            Len := Arg'Length;
            if Len = 0 then
               Status := 0;
            else
               Output (Output'First .. Output'First + Len - 1) 
                                 := Arg (Arg'First .. Arg'Last);
               Status            := 1;
            end if;
         end Exchange;

         function Textio return Boolean is
         begin
            return Textio_On;
         end Textio;

         function Is_On return Boolean is
         begin
            return Console_On;
         end Is_On;

         procedure Set_Textio (On : in Boolean) is
         begin
            Textio_On := On;
         end Set_Textio;

         procedure Set_Console (On : in Boolean) is
         begin
            Console_On := On;
         end Set_Console;

      end Con_Io;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Prefix                       *  BODY
      -- *                                *
      -- **********************************
      package body Prefix is

         --| Purpose
         --| Package body for Prefix
         --|
         --| Exceptions
         --|
         --| Notes
         --| This package version supports the Prolog to Prefix conversion.
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| July 15, 1993     PP           Speeded up Lex_Table to Lextab
         --conversion
         --| Sept 23, 1993     PP           Added ":-a(L)." type of query.

         package Bips renames Builtin_Predicates;

         function Nil return Lex.Goal_Value renames Lex.Nil;

         T_Query  : Lex.Goal_Value;
         T_Lrb    : Lex.Goal_Value;
         T_Rrb    : Lex.Goal_Value;
         T_Period : Lex.Goal_Value;
         T_If     : Lex.Goal_Value;

         Lextab     : Lex.Token_Access;  --  table of tokens in prefix format
         Lextab_Ptr : Lex.Token_Range;   --  pointer into this table

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Tok                       *  BODY
         -- *                                *
         -- **********************************
         function Get_Tok
           (Position : in Lex.Token_Range)
            return     Lex.Goal_Value
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         begin
            return Lextab (Position);
         end Get_Tok;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Last_Tok_Pos                  *  BODY
         -- *                                *
         -- **********************************
         function Last_Tok_Pos return Lex.Token_Range is

         --| Purpose
         --| Last_Tok_Pos gets the pointer to the last token.
         --|
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 20, 1993      Paul Pukite    Converted from global data

         begin
            return Lextab_Ptr;
         end Last_Tok_Pos;

         --X1804: CSC
         -- **********************************
         -- *                                *
         -- *   Prefix_Parse_Driver          *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Prefix_Parse_Driver (Begp, Endp : in Lex.Token_Range) is

            --| Purpose
            --| Prefix_Parse_Driver converts a Prolog-style input to a Prefix
            --format.
            --| It also distinguishes what kind of clause the current clause is
            --| (a rule, fact, or query), and parses it accordingly.
            --| Begp and Endp are beginning and end pointers of the current
            --clause.
            --|
            --| Exceptions
            --| PREFIX_ERROR if unmatched bracket occurs.
            --|
            --| Notes
            --| This is not included in the embedded version so that the
            --rulebase
            --| should be converted to prefix format during rulebase
            --development.
            --|
            --| Modifications
            --| September 8, 1991  Paul Pukite   Initial Version
            --| April 26, 1993     PP            Heap extensions

            No_Separator : Lex.Token_Range := Lextab'Last;

            -- Associativity types for operations, according to Clocksin &
            --Mellish
            -- Prolog standard.

            type Associativity is (
               None,
               Xfx,
               Xfy,
               Yfx,
               Yfy,
               Fx,
               Fy,
               Xf,
               Yf);

            type Precedence is new Table_Sizes.Integer_Ptr;

            Not_Found    : constant Precedence := -1;
            Not_Operator : constant Precedence := -2;

            -- Table for parsing - this is used by Prefix to determine
            --precedences.

            type Op_Record is                      -- Entries of the Op_Table
                                                   --below:
            record
               Tok_Value        : Bips.Predicates;    -- name of each token
               Prec_Type        : Associativity;      -- associativity type
               Precedence_Value : Precedence;  -- precedence value
            end record;

            Op_Table : array (0 .. 25) of Op_Record :=
              (
            -- ISO standard -- BYTE
              (Bips.P_Exp, Yfx, 200),   -- 10
               (Bips.P_Mult, Yfx, 400),   -- 21
               (Bips.P_Bminus, Yfx, 500),   -- 31
               (Bips.P_Plus, Yfx, 500),   -- 31
               (Bips.P_Lt, Xfx, 700),   -- 40
               (Bips.P_Gt, Xfx, 700),   -- 40
               (Bips.P_Div, Yfx, 400),   -- 21
               (Bips.P_Uminus, Fx, 200),   -- 9    FY?
               (Bips.P_Le, Xfx, 700),   -- 40
               (Bips.P_Ge, Xfx, 700),   -- 40
               (Bips.P_Ne, Xfx, 700),   -- 40
               (Bips.P_Sequal, Xfx, 700),   -- 40
               (Bips.P_Period, Xfy, 800),   -- 51
               (Bips.P_Comma, Xfy, 1000),  -- 253
               (Bips.P_Is, Xfx, 700),   -- 40
               (Bips.P_If, Xfx, 1200),  -- 255
               (Bips.P_Query, Fx, 1200),  -- 255
               (Bips.P_Not, Fx, 900),   -- 60   FY ?
               (Bips.P_Ifthen, Xfy, 1050),
               (Bips.P_Ldot, Xfx, 800),   -- 51
               (Bips.P_Mod, Yfx, 400),   -- 21
               (Bips.P_Idiv, Yfx, 400),   -- 21
               (Bips.P_Equal, Xfx, 700),   -- 40
               (Bips.P_Nequal, Xfx, 700),   -- 40
               (Bips.P_Or, Xfy, 1100),  -- 254
               (Bips.P_Unif, Xfx, 700)    -- 40
              );

            If_Ptr : Lex.Token_Range;
            -- Pointer to if ":-" in Lex_Table.

            Temp_Endp : Lex.Token_Range := Endp;
            Temp_Begp : Lex.Token_Range := Begp;

            function ">" (L, R : Lex.Token_Range) return Boolean renames
              Lex. ">";
            function "+" (L, R : Lex.Token_Range) return Lex.Token_Range
               renames Lex. "+";
            function "=" (L, R : Lex.Token_Range) return Boolean renames
              Lex. "=";
            function "-" (L, R : Lex.Token_Range) return Lex.Token_Range
               renames Lex. "-";
            function "<=" (L, R : Lex.Token_Range) return Boolean renames
              Lex. "<=";

            -- **********************************
            -- *                                *
            -- *   Is_Separator                 *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Is_Separator
              (Token : in Lex.Goal_Value)
               return  Boolean
            is
               P : Bips.Predicates;
            begin
               if Lex.Is_Builtin (Token) then
                  P := Lex.Get_Bip (Token);
                  return (P = Bips.P_Comma
                         or else P = Bips.P_Query
                         or else P = Bips.P_Eot);
               else
                  return False;
               end if;
            end Is_Separator;

            -- **********************************
            -- *                                *
            -- *   Is_Left_Paren                *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Is_Left_Paren
              (Token : in Lex.Goal_Value)
               return  Boolean
            is
               P : Bips.Predicates;
            begin
               if Lex.Is_Builtin (Token) then
                  P := Lex.Get_Bip (Token);
                  return (P = Bips.P_Lrb or else P = Bips.P_Lsqb);
               else
                  return False;
               end if;
            end Is_Left_Paren;

            -- **********************************
            -- *                                *
            -- *   Is_Infix                     *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Is_Infix (Operation : in Associativity) return Boolean is
            begin
               return (Operation = Xfx
                      or else Operation = Xfy
                      or else Operation = Yfy
                      or else Operation = Yfx);
            end Is_Infix;

            -- **********************************
            -- *                                *
            -- *   Is_Prefix                    *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Is_Prefix
              (Operation : in Associativity)
               return      Boolean
            is
            begin
               return (Operation = Fx or else Operation = Fy);
            end Is_Prefix;

            -- **********************************
            -- *                                *
            -- *   Is_Postfix                   *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Is_Postfix
              (Operation : in Associativity)
               return      Boolean
            is
            begin
               return (Operation = Xf or else Operation = Yf);
            end Is_Postfix;

            -- **********************************
            -- *                                *
            -- *   Skip_Bracket_Pair            *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Skip_Bracket_Pair
              (Begp, Endp : in Lex.Token_Range)
               return       Lex.Token_Range
            is

               --| Purpose
               --| Find the position of a right bracket that matches the left
               --bracket in
               --| Lex_Table.
               --| Begp : beginning position for searching
               --| Endp : end position for searching

               Round_Count  : Table_Sizes.Integer_16 := 0;
               Square_Count : Table_Sizes.Integer_16 := 0;
               -- Initialize the counts of round and square brackets.

               Index   : Lex.Token_Range;
               Current : Bips.Predicates;

            begin

               Index := Begp; -- The current pointer to Lex_Table.

               loop

                  if Lex.Is_Builtin (Lex.Lex_Table (Index)) then
                     Current := Lex.Get_Bip (Lex.Lex_Table (Index));
                  else
                     Current := Bips.P_Is; -- junk token
                  end if;

                  -- If the current token is a bracket,
                  -- increase its count accordingly.

                  if Current = Bips.P_Lrb then
                     Round_Count := Round_Count + 1;     -- If it is a left
                                                         --bracket.
                  elsif Current = Bips.P_Lsqb then
                     Square_Count := Square_Count + 1;
                  elsif Current = Bips.P_Rrb then
                     Round_Count := Round_Count - 1;     -- If it is a right
                                                         --bracket.
                  elsif Current = Bips.P_Rsqb then
                     Square_Count := Square_Count - 1;
                  else
                     null;      -- For other tokens, do nothing.
                  end if;

                  if Round_Count = 0 and Square_Count = 0 then
                     return (Index);
                     -- If the bracket are all matched, return
                     -- the position of the last right bracket.
                  end if;

                  exit when Index > Endp;

                  Index := Index + 1;

               end loop;

               -- If there are still items left, loop again, otherwise
               -- get to this point is an error.

               Token_Io.Print (Token_Io.Error_Display, "Unmatched bracket.");

               raise Rule_Errors.Prefix_Error;

            end Skip_Bracket_Pair;

            -- **********************************
            -- *                                *
            -- *   Find_Separator_Position      *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Find_Separator_Position
              (Begp, Endp : in Lex.Token_Range)
               return       Lex.Token_Range
            is

               --| Purpose
               --| Finds from LEX.Lex_Table, between the positions Begp
               --| (beginning position) and Endp (end position), the position
               --of
               --| the first term separator.
               --| A separator is one of ',' (AND) or '?' (query).

               Pos : Lex.Token_Range;
            begin

               Pos := Begp;
               while Pos <= Endp loop  -- Search through the whole range.

                  if Is_Separator (Lex.Lex_Table (Pos)) then
                     -- If the current token is a term separator,
                     return (Pos);
                  -- return its position in LEX.Lex_Table.
                  elsif Is_Left_Paren (Lex.Lex_Table (Pos)) then
                     -- If the token is a left bracket.
                     Pos := Skip_Bracket_Pair (Pos, Endp);
                  end if;
                  Pos := Pos + 1;
                  -- Not found a separator yet, try the next token.

               end loop;

               return (No_Separator);
               -- Can't find a separator in the term.

            end Find_Separator_Position;

            -- **********************************
            -- *                                *
            -- *   Higest_Precedence            *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Highest_Precedence
              (Begp, Endp : in Lex.Token_Range;
               Op_Asso    : in out Associativity;
               Op_Pos     : in out Lex.Token_Range;
               Prec_Out   : out Precedence)
            is

               --| Purpose
               --| Finds between positions Begp (beginning position) and Endp
               --(end position)
               --| of Lex_Table the operator with the highest precedence.  If
               --there are more
               --| than one operators with the same highest precedence this
               --function will
               --| decide according to the associativity which operator to
               --take.  If such an
               --| operator can be found, the precedence of the operator will
               --be returned
               --| as well as the associativity and the position of the
               --operator
               --| through the parameters:
               --|
               --| Prec_Out : the precedence of the operator,
               --| Op_Asso  : the associativity of the operator,
               --| Op_Pos   : the position of the operator in Lex_Table.
               --|
               --| Notes
               --| If a term is enclosed inside a set of parantheses, then the
               --| precedence for it will be 0.
               --| For operators with the same precedence, the following table
               --will be used
               --| to decide which operator to should be parsed first.
               --|
               --|    ASSOCIATIVITY     |   THE OPERATOR TO BE PARSED FIRST
               --|
               ----------------------------------------------------------------
               ----
               --|   xfx fx fy xf yf    |   the first one encountered
               --|
               ----------------------------------------------------------------
               ----
               --|   xfy                |   the first one encountered
               --|
               ----------------------------------------------------------------
               ----
               --|   yfy                |   the first one encountered
               --|                      | (actually any one will do)
               --|
               ----------------------------------------------------------------
               ----
               --|   yfx                |   the rightmost one
               --|  according to Clocksin & Mellish
               --|   f : stands for the operator.
               --|   x : any operator in the argument must have a strictly
               --lower precedence
               --|       than f.
               --|   y : operators of the same or lower precedence than that
               --of f.
               --|   yfx is left associativity          xfy is right
               --associativity
               --|   e.g.  + is defined as yfx
               --|       so  a+b+c   will be parsed into  (+ (+ a b) c)
               --|       ,  is defined as xfy
               --|       so  a,b,c   will be parsed into (, a (, b c))
               --syntactically
               --|                   but this program will parsed it into (a b
               --c)
               --|                   assuming that ',' (AND) is expressed
               --implicitly.

               High_Prec : Precedence := 0;
               -- The highest precedenc seen so far.

               Current_Prec : Precedence := 0;
               -- The precedence of the current operator.

               Current_Asso : Associativity := None;
               -- The associativity of the current operator.

               Current_Ptr : Lex.Token_Range;
               -- The position of the current operator.

               -- **********************************
               -- *                                *
               -- *   Find_Precedence_Association  *  SPEC & BODY
               -- *                                *
               -- **********************************
               procedure Find_Precedence_Association
                 (Tok  : in Lex.Goal_Value;
                  Asso : in out Associativity;
                  Prec : out Precedence)
               is

                  --| Purpose
                  --| Check if Tok is an operator (builtin or user defined).
                  --| If true, return its precedence and also return its
                  --| associativity through the parameters, else return
                  --NOT_OPERATOR.

                  Token : Bips.Predicates;

               begin

                  if Lex.Is_Builtin (Tok) then
                     Token := Lex.Get_Bip (Tok);
                  else
                     Prec := Not_Operator;
                     return;
                  end if;

                  for I in  Op_Table'Range loop
                     -- Search the table of operators

                     if Op_Table (I).Tok_Value = Token then
                        -- If found Tok in Op_Table,

                        Asso := Op_Table (I).Prec_Type;
                        -- return its associativity

                        Prec := Op_Table (I).Precedence_Value;

                        return;
                        -- and return its precedence.

                     end if;
                  end loop;

                  Prec := Not_Operator;

               end Find_Precedence_Association;

            begin   -- Highest_Prec

               if Lex.Is_Builtin_Token (Lex.Lex_Table (Begp), Bips.P_Lrb) and
                  Lex.Is_Builtin_Token (Lex.Lex_Table (Endp), Bips.P_Rrb)
               then

                  Prec_Out := Not_Found;
                  return;

               end if;

               -- Enclosed inside ( ).

               Current_Ptr := Begp;
               -- Set Current_Ptr to point to the first token.

               while Current_Ptr <= Endp loop
                  -- Search through the whole term.

                  Find_Precedence_Association
                    (Lex.Lex_Table (Current_Ptr),
                     Current_Asso,
                     Current_Prec);
                  if Current_Prec /= Not_Operator then

                     -- Check if the current token (LEX.Lex_Table(Current_Ptr))
                     -- is an operator, if yes get its precedence and
                     --associativity.

                     if (Current_Prec > High_Prec or
                        -- If the precedence of the current operator is
                        -- greater than that of the previous one,

                         (Current_Prec = High_Prec and Op_Asso = Yfx)
                        -- or they are in the same precedence but is left
                        --associative,

                          )
                     then
                        -- then replace the previous one by the current
                        --operator.

                        High_Prec := Current_Prec;
                        -- Replace the precedence.

                        Op_Asso := Current_Asso;
                        -- Replace the associativity.

                        Op_Pos := Current_Ptr;
                        -- Replace the position of the operator.

                     end if;
                  elsif Is_Left_Paren (Lex.Lex_Table (Current_Ptr)) then

                     -- If current token is a left bracket,
                     -- then advance Current_Ptr to the right matching bracket.

                     Current_Ptr := Skip_Bracket_Pair (Current_Ptr, Endp);

                  end if;

                  Current_Ptr := Current_Ptr + 1;
                  -- Advance to the next token.

               end loop;

               -- If this term contains no operator,
               -- return the highest precedence seen.

               if High_Prec = 0 then
                  Prec_Out := Not_Found;
               else
                  Prec_Out := High_Prec;
               end if;

            end Highest_Precedence;

            -- **********************************
            -- *                                *
            -- *   Parse_Terms                  *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Parse_Terms (Begp, Endp : in Lex.Token_Range) is

               --| Purpose
               --| Driver to parse terms.  Terms are separted by   ',' (AND)
               --| ';' (OR)    '.' (LEX.EOT)     '?' (query)
               --| or no separator.   The following are some cases of terms :
               --|   a,b|c.        a?        a,b,c,d  (this is from
               --test(a,b,c,d))
               --|   test(a,b,c,d)  (this is from test(a,b,c,d) :- m,n.)
               --| The terms are between positions Begp (beginning position)
               --and Endp
               --| (end position) in Lex_Table.

               Tok_Sep : Lex.Goal_Value;
               -- Token of the separator.

               Tok_Sep_Pos : Lex.Token_Range;
               -- Position of the term separator.

               Temp_Endp : Lex.Token_Range := Endp;
               Temp_Begp : Lex.Token_Range := Begp;

               -- **********************************
               -- *                                *
               -- *   Parse_One_Term               *  SPEC & BODY
               -- *                                *
               -- **********************************
               procedure Parse_One_Term (Begp, Endp : in Lex.Token_Range) is

                  --| Purpose
                  --| To parse a term. A term can be a constant, variable or a
                  --structure. The
                  --| term is between Begp (beginning position) and Endp (end
                  --position) in
                  --| Lex_Table

                  Firsttok, Lasttok : Lex.Goal_Value;
                  Op_Prec           : Precedence;
                  -- Precedence of the operator.

                  Op_Asso : Associativity := Associativity'First;
                  -- Associativity of the operator.

                  Op_Pos : Lex.Token_Range := Lex.Token_Range'First;
                  -- Position of the operator in Lex_Table.

                  Retval    : Boolean;
                  Temp_Endp : Lex.Token_Range := Endp;
                  Temp_Begp : Lex.Token_Range := Begp;

                  -- **********************************
                  -- *                                *
                  -- *   Parse_Fact                   *  SPEC & BODY
                  -- *                                *
                  -- **********************************
                  function Parse_Fact
                    (Begp, Endp : in Lex.Token_Range)
                     return       Boolean
                  is

                  --| Purpose
                  --| Parse a term which has a form of a fact. e.g.
                  --partof(car, wheel)
                  --| which may be a fact or a subgoal of a rule.
                  --| The term is within Begp (beginning position) and Endp
                  --(end position)
                  --| in Lex_Table.

                  begin

                     Store_Tok (T_Lrb);
                     -- Store '(' in Lextab.

                     Store_Tok (Lex.Lex_Table (Begp));
                     -- Store the functor in Lextab

                     if Lex.Is_Builtin_Token
                           (Lex.Lex_Table (Begp + 1),
                            Bips.P_Lrb) and
                        -- If there is a '(' after functor,

                        Lex.Is_Builtin_Token
                           (Lex.Lex_Table (Endp),
                            Bips.P_Rrb)
                     then
                        -- and a ')' at the end of the term (e.g. partof(car,
                        --wheel) )

                        Parse_Terms ((Begp + 2), (Endp - 1));
                        -- discard the parenthesis, and parse the arguments.

                        Store_Tok (T_Rrb);
                        -- Store ')' to close the fact.

                        return (True);

                     else
                        Token_Io.Print
                          (Token_Io.Error_Display,
"The arguments of a functor must be enclosed within ()");
                        return (False);
                     end if;

                  end Parse_Fact;

                  -- **********************************
                  -- *                                *
                  -- *   Parse_Operation              *  SPEC & BODY
                  -- *                                *
                  -- **********************************
                  function Parse_Operation
                    (Begp         : in Lex.Token_Range;
                     Op_Prec      : in Precedence;
                     Op_Asso      : in Associativity;
                     Op_Pos, Endp : in Lex.Token_Range)
                     return         Boolean
                  is

                     --| Purpose
                     --| Parse a term of operation. The operation expression
                     --is within Begp
                     --| (beginning position) and Endp (end position) in
                     --Lex_Table.
                     --| Op_Prec : the precedence of the operator
                     --| Op_Asso : the associativity of the operator
                     --| Op_Pos  : the position of the operator in Lex_Table.
                     --| See the comments in Highest_Precedence for
                     --explanation of
                     --| associativity.

                     L_Op_Prec, R_Op_Prec : Precedence;
                     -- Precedence of the left and right operands.

                     Dummy1 : Associativity   := Associativity'First;
                     Dummy2 : Lex.Token_Range := Lex.Token_Range'First;

                     -- **********************************
                     -- *                                *
                     -- *   Parse_Operand                *  SPEC & BODY
                     -- *                                *
                     -- **********************************
                     procedure Parse_Operand
                       (Begp, Endp : in Lex.Token_Range)
                     is

                     --| Purpose
                     --| Parse operand. This function is called by
                     --Parse_Operation to parse
                     --| an operand. If the operand (beginning from Begp and
                     --ending in Endp)
                     --| is enclosed by a set of parenthesis, the set of
                     --parenthesis will be
                     --| removed. For example, if Parse_Operation tries to
                     --parse
                     --|    (a + b) * c,
                     --| then this function is called with  (a + b)
                     --| and this function will call Parse_Terms with  a + b .

                     begin

                        if Lex.Is_Builtin_Token
                              (Lex.Lex_Table (Begp),
                               Bips.P_Lrb) and
                           Lex.Is_Builtin_Token
                              (Lex.Lex_Table (Endp),
                               Bips.P_Rrb)
                        then
                           Parse_Terms ((Begp + 1), (Endp - 1));
                        -- Remove the set of (), and parse it.

                        else
                           Parse_Terms (Begp, Endp);
                           -- Parse the passed operand.

                        end if;

                     end Parse_Operand;

                     -- **********************************
                     -- *                                *
                     -- *   Print_Tok                    *  SPEC & BODY
                     -- *                                *
                     -- **********************************
                     procedure Print_Tok (Token : in Lex.Goal_Value) is
                     begin
                        Token_Io.Print_Token
                          (Token_Io.Error_Display,
                           Token,
                           0);
                     end Print_Tok;

                  begin  -- Parse_Operation

                     -- Get the precedence of the

                     Highest_Precedence
                       (Begp,
                        (Op_Pos - 1),
                        Dummy1,
                        Dummy2,
                        L_Op_Prec);
                     -- left operand

                     Highest_Precedence
                       ((Op_Pos + 1),
                        Endp,
                        Dummy1,
                        Dummy2,
                        R_Op_Prec);
                     -- and right operand.

                     case Op_Asso is
                        -- Based on the associativity, check if the precedence
                        --of the
                        -- operand are valid.

                        when Xfx =>
                           if L_Op_Prec >= Op_Prec or
                              Op_Prec <= R_Op_Prec
                           then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for xfx :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when Xfy =>
                           if L_Op_Prec >= Op_Prec or
                              Op_Prec < R_Op_Prec
                           then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for xfy :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when Yfy =>
                           if L_Op_Prec > Op_Prec or
                              Op_Prec < R_Op_Prec
                           then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for yfy :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when Yfx =>
                           if L_Op_Prec > Op_Prec or
                              Op_Prec <= R_Op_Prec
                           then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for yfx :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when Fx =>
                           if Op_Prec <= R_Op_Prec then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for fx :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when Fy =>
                           if Op_Prec < R_Op_Prec then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for fy :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when Xf =>
                           if L_Op_Prec >= Op_Prec then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for xf :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when Yf =>
                           if L_Op_Prec > Op_Prec then
                              Token_Io.Print
                                (Token_Io.Error_Display,
                                 "Incorect operand predence for yf :");
                              Print_Tok (Lex.Lex_Table (Op_Pos));
                              return (False);
                           end if;
                        when others =>
                           null;
                     end case;

                     -- Get to this point, the operation is valid.

                     if Lex.Is_Builtin_Token
                          (Lex.Lex_Table (Op_Pos),
                           Bips.P_Ldot)
                     then
                        -- If operator is '|' (list constructor),

                        Store_Tok (T_Period);
                     -- store '.' instead of '|'.

                     else
                        Store_Tok (T_Lrb);
                        -- Store '(' in Lextab.

                        Store_Tok (Lex.Lex_Table (Op_Pos));
                        -- Store the token of the operator.

                     end if;
                     if Is_Infix (Op_Asso) then

                        Parse_Operand (Begp, (Op_Pos - 1));
                        -- Parse the left operand.

                        Parse_Operand ((Op_Pos + 1), Endp);
                     -- Parse the right operand.

                     elsif Is_Prefix (Op_Asso) then

                        if Begp /= Op_Pos then
                           -- If there are items before operator.

                           Token_Io.Print
                             (Token_Io.Error_Display,
                              "Invalid item before prefix operator");
                           return (False);
                        else
                           Parse_Operand ((Begp + 1), Endp);

                        end if;
                     elsif Is_Postfix (Op_Asso) then

                        if Endp /= Op_Pos then
                           -- If there are items after operator,

                           Token_Io.Print
                             (Token_Io.Error_Display,
                              "Invalid items after postfix operator.");
                           return (False);
                        else
                           Parse_Operand (Begp, (Endp - 1));
                           -- discard the operator and parse the operand.

                        end if;
                     end if;

                     if not Lex.Is_Builtin_Token
                              (Lex.Lex_Table (Op_Pos),
                               Bips.P_Ldot)
                     then
                        Store_Tok (T_Rrb);
                        -- Store ')' to close the operation.

                     end if;

                     return (True);

                  end Parse_Operation;

               begin    -- Parse_One_Term

                  if Temp_Begp > Temp_Endp then
                     -- This may be an error.

                     return;
                  end if;
                  if Temp_Begp = Temp_Endp then
                     -- If Temp_Begp and Temp_Endp are pointing to the same
                     --token,

                     Store_Tok (Lex.Lex_Table (Temp_Begp));
                     -- store the token.

                     return;
                  end if;

                  Firsttok := Lex.Lex_Table (Temp_Begp);
                  -- Get the first token in the term.

                  Lasttok := Lex.Lex_Table (Temp_Endp);
                  -- Get the last token in the term.

                  if (Lex.Is_Builtin_Token (Firsttok, Bips.P_Lrb) and   --  (
                                                                        --  )
                      Lex.Is_Builtin_Token (Lasttok, Bips.P_Rrb))
                    or else (Lex.Is_Builtin_Token (Firsttok, Bips.P_Lsqb) and
                     --  [    ]
                             Lex.Is_Builtin_Token (Lasttok, Bips.P_Rsqb))
                  then

                     Store_Tok (T_Lrb);
                     -- Store '(' in Lextab.

                     Temp_Begp := Temp_Begp + 1;
                     Temp_Endp := Temp_Endp - 1;
                     if Temp_Begp <= Temp_Endp then
                        -- Discard the pair of bracket.  If there are terms
                        --inside the
                        -- bracket, parse them.

                        Parse_Terms (Temp_Begp, Temp_Endp);

                     end if;

                     Store_Tok (T_Rrb);
                     -- Store ')' in Lextab.

                     return;
                  end if;

                  -- If not the above cases, the term may be an operation or
                  --in the form of a
                  -- fact.  e.g.   a+10/w > 200     same(one, 1)       not a

                  Highest_Precedence
                    (Temp_Begp,
                     Temp_Endp,
                     Op_Asso,
                     Op_Pos,
                     Op_Prec);
                  -- Get the procedence, associativity, and position of
                  -- the operator with the highest precedence in the term.

                  if Op_Prec = Not_Found then
                     -- If no operator in the term, then parse it as a fact.
                     Retval := Parse_Fact (Temp_Begp, Temp_Endp);
                  else
                     -- It is an operation so parse the operation.
                     Retval :=
                        Parse_Operation
                          (Temp_Begp,
                           Op_Prec,
                           Op_Asso,
                           Op_Pos,
                           Temp_Endp);
                  end if;
                  if not Retval then
                     raise Rule_Errors.Prefix_Error;
                  end if;

               end Parse_One_Term;

            begin  -- Parse_Terms

               loop

                  Tok_Sep_Pos :=
                     Find_Separator_Position (Temp_Begp, Temp_Endp);

                  -- Find the first term seperator of one of ',' '?' LEX.EOT.

                  if Tok_Sep_Pos = No_Separator then
                     -- if not one of , | ? LEX.EOT then it is a term without
                     --separator.
                     -- This can happen for the 'a' of test(a).

                     Parse_One_Term (Temp_Begp, Temp_Endp);
                     -- Parse the term without separator.

                     exit;

                  end if;

                  Tok_Sep := Lex.Lex_Table (Tok_Sep_Pos);
                  -- Get the token of the term separator.

                  if Lex.Is_Builtin_Token (Tok_Sep, Bips.P_Eot) or
                     Lex.Is_Builtin_Token (Tok_Sep, Bips.P_Query)
                  then
                     -- If separator is end of clause or ?,

                     Parse_One_Term (Temp_Begp, (Temp_Endp - 1));
                     -- discard the separator and parse it.

                     exit;
                  elsif Lex.Is_Builtin_Token (Tok_Sep, Bips.P_Comma) then
                     -- If the separator is ',' (AND).
                     -- Note : operator ',' is not explicitly expressed in the
                     --prefix form.

                     Parse_One_Term (Temp_Begp, (Tok_Sep_Pos - 1));
                     -- Discard the separator and parse the term.

                  end if;

                  Tok_Sep_Pos := Tok_Sep_Pos + 1;
                  Temp_Begp   := Tok_Sep_Pos;
                  -- The beginning of the next term is the next token
                  -- after the current separator.

               end loop;

            end Parse_Terms;

            -- **********************************
            -- *                                *
            -- *   Parse_Head                   *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Parse_Head (Begp, Endp : in Lex.Token_Range) is
            begin
               if Begp = Endp - 1 then
                  Store_Tok (T_Lrb);
                  -- Store '(' in Lextab.
                  Parse_Terms (Begp, Endp - 1);
                  -- Parse the query.
                  Store_Tok (T_Rrb);
               -- Store ')' in Lextab to close query.
               else
                  Parse_Terms (Begp, Endp - 1);
                  -- Parse the query.
               end if;
            end Parse_Head;

            -- **********************************
            -- *                                *
            -- *   Parse_Body                   *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Parse_Body (Begp, Endp : in Lex.Token_Range) is
               Start : Lex.Token_Range := Begp;
               Stop  : Lex.Token_Range := Endp;
            begin
               loop
                  Stop := Find_Separator_Position (Start, Stop);
                  if Start = Stop - 1 then
                     if Lex.Is_Builtin_Token
                           (Lex.Lex_Table (Start),
                            Bips.P_Cut)
                       or else Lex.Is_Variable (Lex.Lex_Table (Start))
                     then
                        Parse_Terms (Start, Stop - 1);
                     else
                        Store_Tok (T_Lrb);
                        -- Store '(' in Lextab.
                        Parse_Terms (Start, Stop - 1);
                        -- Parse the query.
                        Store_Tok (T_Rrb);
                        -- Store ')' in Lextab to close query.
                     end if;
                  else
                     Parse_Terms (Start, Stop - 1);
                     -- Parse the query.
                  end if;
                  exit when Stop = Endp;
                  Start := Stop + 1;
                  Stop  := Endp;
               end loop;
            end Parse_Body;

         begin    -- Prefix_Parse_Driver

            if Lex.Is_Builtin_Token (Lex.Lex_Table (Temp_Endp), Bips.P_Query)
              or else Lex.Is_Builtin_Token
                         (Lex.Lex_Table (Temp_Begp),
                          Bips.P_If)
            then
               -- If the clause is a query '?',

               Store_Tok (T_Lrb);
               -- store '(' in Lextab,

               Store_Tok (T_Query);
               -- store '?' in Lextab, and

               if Lex.Is_Builtin_Token
                    (Lex.Lex_Table (Temp_Begp),
                     Bips.P_If)
               then
                  Temp_Begp := Temp_Begp + 1;
               end if;

               if Lex.Is_Builtin_Token
                    (Lex.Lex_Table (Temp_Begp),
                     Bips.P_Load)
               then
                  if Lex.Is_Builtin_Token
                       (Lex.Lex_Table (Temp_Begp + 1),
                        Bips.P_Lrb)
                  then
                     Con_Io.Put_Line
                       (" % File=" &
                        Lex.Get_Sym (Lex.Lex_Table (Temp_Begp + 2)),
                        True);
                     if Load
                          (Lex.Get_Sym (Lex.Lex_Table (Temp_Begp + 2)),
                           False)
                     then
                        null;
                     end if;
                     Lextab_Ptr := Lex.Token_Range'First;   -- Ignore Lextab
                     return;
                  end if;
               end if;

               Parse_Head (Temp_Begp, Temp_Endp);

               -- parse the query.

               Store_Tok (T_Rrb);
            -- Store ')' in Lextab to close query.

            else
               -- Find "if" when the clause is a rule.

               If_Ptr := Temp_Begp;
               while If_Ptr /= Temp_Endp loop
                  -- While not end of clause, find ":-".

                  if Lex.Is_Builtin_Token
                       (Lex.Lex_Table (If_Ptr),
                        Bips.P_If)
                  then
                     -- If the current token is ":-",

                     Store_Tok (T_Lrb);
                     -- store '(' in Lextab,

                     Store_Tok (T_If);
                     -- store ':-" in Lextab, and

                     -- parse the head of the rule.
                     Parse_Head (Temp_Begp, If_Ptr);

                     Store_Tok (T_Lrb);
                     -- Store '(' for subgoals.

                     Parse_Body ((If_Ptr + 1), Temp_Endp);
                     -- Parse the subgoals.

                     Store_Tok (T_Rrb);
                     -- Store ')' to close the subgoals.

                     Store_Tok (T_Rrb);
                     -- Store ')' to close the rule.

                     return;
                  else
                     if Is_Left_Paren (Lex.Lex_Table (If_Ptr)) then
                        -- If current token is a left bracket.

                        If_Ptr := Skip_Bracket_Pair (If_Ptr, Temp_Endp);
                     end if;

                     If_Ptr := If_Ptr + 1;
                     -- The current token is not ":-", try the next token.

                  end if;

               end loop;

               -- The current clause is not a rule, so parse it.
               Parse_Head (Temp_Begp, Temp_Endp);

            end if;

         end Prefix_Parse_Driver;

         -- **********************************
         -- *                                *
         -- *   Store_Tok                    *  BODY
         -- *                                *
         -- **********************************
         procedure Store_Tok (Tok : in Lex.Goal_Value) is

            --| Notes
            --| Store Tok into Lextab.

            function ">=" (L, R : Lex.Token_Range) return Boolean renames
              Lex. ">=";
            function "+" (L, R : Lex.Token_Range) return Lex.Token_Range
               renames Lex. "+";
         begin

            Lextab (Lextab_Ptr) := Tok;
            Lextab_Ptr          := Lextab_Ptr + 1;
            if Lextab_Ptr >= Lextab'Last then
               -- Clauses too long, Lextab overflowed.

               raise Rule_Errors.Prefix_Error;
            end if;

         end Store_Tok;

         -- **********************************
         -- *                                *
         -- *   Purge                        *  BODY
         -- *                                *
         -- **********************************
         procedure Purge is
         begin
            Lextab_Ptr := Lex.Token_Range'First;
         end Purge;

         -- **********************************
         -- *                                *
         -- *   Prefix                       *  BODY
         -- *                                *
         -- **********************************
         procedure Prefix (Lisp_Syntax : in Boolean) is

            --| Notes
            --| Main parse driver to parse all the clauses in the program
            --| note that Lex_Table(End) is EOT (end of tokens), and
            --Lex_Table(0) is
            --| only a beginning symbol, not a token of the Prolog program.
            --| If Lextab_Ptr not advanced, nothing was converted.

            Index : Lex.Token_Range := Lex.Token_Range'First;

            function "+" (L, R : Lex.Token_Range) return Lex.Token_Range
               renames Lex. "+";
            function "<" (L, R : Lex.Token_Range) return Boolean renames
              Lex. "<";
         begin

            if Lisp_Syntax then

               Lextab_Ptr := Lex.Lex_Position;

               Lextab.all (Lex.Lex_Table'First .. Lextab_Ptr) :=
                 Lex.Lex_Table.all (Lex.Lex_Table'First .. Lextab_Ptr);
               Lextab (Lextab_Ptr + 1)                        := Lex.Nil;

            else
               Lextab_Ptr := Lex.Token_Range'First;   -- Initialize for
                                                      --Store_Tok.

               Prefix_Parse_Driver (Index, Lex.Lex_Position);
               -- Call the main prefix converter.
               Lextab (Lextab_Ptr) := Lex.Nil;

               while Index < Lextab_Ptr loop

                  -- For creating intermediate file (prefix format file).

                  Token_Io.Print_Token
                    (Token_Io.Stream_Out,
                     Lextab (Index),
                     0);

                  Index := Index + 1;
               end loop;

               Token_Io.Print (Token_Io.Stream_Out, '.');
               Token_Io.New_Line (Token_Io.Stream_Out);

            end if;

         end Prefix;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Initialize_Prefix             *  BODY
         -- *                                *
         -- **********************************
         procedure Initialize_Prefix
           (In_Toks : in Lexical_Analysis.Token_Range)
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Lextab     :=
              new Lex.Token_Array (Lex.Token_Range'First .. In_Toks);
            Lextab.all := (others => null);
            T_Query    := Lex.Make_Builtin (Bips.P_Query);
            T_Lrb      := Lex.Make_Builtin (Bips.P_Lrb);
            T_Rrb      := Lex.Make_Builtin (Bips.P_Rrb);
            T_Period   := Lex.Make_Builtin (Bips.P_Period);
            T_If       := Lex.Make_Builtin (Bips.P_If);
         end Initialize_Prefix;

      end Prefix;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *  Get_Clause                    *  SPEC
      -- *                                *
      -- **********************************
      function Get_Clause
        (Fp   : in Text_IO.File_Type;
         Lisp : in Boolean := False)
         return Boolean;

      --| Purpose
      --| Get a clause from a rulebase file and load into the clause string.
      --|
      --| Exceptions (none)
      --| Notes
      --|
      --| Modifications
      --| April 26, 1993    Paul Pukite    Initial Version

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *  Get_Clause                    *   BODY
      -- *                                *
      -- **********************************
      function Get_Clause
        (Fp   : in Text_IO.File_Type;
         Lisp : in Boolean := False)
         return Boolean
      is

         --| Purpose
         --| Get a clause from a rulebase file.
         --|
         --| Exceptions (none)
         --| Notes
         --| This has some lexical analysis to determine when a clause stops.
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         Length : Natural;
         Str    : String (1 .. Lexical_Analysis.Clause_String'Length);  -- Tabl
                                                                        --e_Siz
                                                                        --es.Cl
                                                                        --ause_
                                                                        --Lengt
                                                                        --h_Max
                                                                        --);

         procedure Prolog_Clause is
            Ch      : Character;
            Last    : Natural;
            Quote   : Boolean := False;
            S_Quote : Boolean := False;
         begin

            loop
               if (Text_IO.Is_Open (Fp)) then
                  Text_IO.Get_Line (Fp, Str (Length + 1 .. Str'Last), Last);
               else
                  Text_IO.Get_Line (Str (Length + 1 .. Str'Last), Last);
               end if;
               for I in  Length + 1 .. Last loop
                  Ch := Str (I);
                  case (Ch) is
                     when '%' =>
                        exit when not Quote and not S_Quote;
                        Length       := Length + 1;
                        Str (Length) := Ch;
                     when ASCII.LF =>  -- Ascii.HT | ' ' =>
                        null;
                     when '?' =>
                        Length := Length + 1;
                        if not Quote and not S_Quote then
                           Str (Length) := Ch;
                           return;
                        end if;
                     when '.' =>
                        Length := Length + 1;
                        if I /= Last
                          and then ((Str (I + 1) in '0' .. '9') or  -- float
                                    Str (I + 1) = '(' or          -- constructe
                                                                  --d list
                                    Str (I + 1) = '.' or          -- =..
                                    (I > 2 and then Str (I - 1) = '.'))
                        then
                           Str (Length) := Ch;
                        elsif not Quote and not S_Quote then
                           Str (Length) := Ch;
                           return;
                        end if;
                     when others =>
                        if Ch = '"' and not S_Quote then
                           Quote := not Quote;
                        elsif Ch = ''' and not Quote then
                           S_Quote := not S_Quote;
                        end if;
                        if Ch in ' ' .. '~' then
                           Length       := Length + 1;
                           Str (Length) := Ch;
                        else
                           Length       := Length + 1;
                           Str (Length) := ' ';
                        end if;
                  end case;
               end loop;
            end loop;
         end Prolog_Clause;

         procedure Prefix_Clause is
            Ch   : Character;
            Last : Natural;
            Pars : Integer := 0;
         begin

            loop
               if (Text_IO.Is_Open (Fp)) then
                  Text_IO.Get_Line (Fp, Str (Length + 1 .. Str'Last), Last);
               else
                  Text_IO.Get_Line (Str (Length + 1 .. Str'Last), Last);
               end if;
               for I in  Length + 1 .. Last loop
                  Ch := Str (I);
                  case (Ch) is
                     when '%' =>
                        exit;
                     when ASCII.HT | ASCII.LF =>
                        null;
                     when '(' =>
                        Pars         := Pars + 1;
                        Length       := Length + 1;
                        Str (Length) := Ch;
                     when ')' =>
                        Pars         := Pars - 1;
                        Length       := Length + 1;
                        Str (Length) := Ch;
                     when '.' =>
                        Length       := Length + 1;
                        Str (Length) := Ch;
                        if Pars <= 0 then
                           return;
                        end if;
                     when others =>  -- Careful on quote character
                        Length       := Length + 1;
                        Str (Length) := Ch;
                  end case;
               end loop;
            end loop;
         end Prefix_Clause;

      begin

         Length := 0;
         if Lisp then
            Prefix_Clause;
         else
            Prolog_Clause;
         end if;
         if Length = 0 then
            Rule_Processor.Load_Clause (1, ASCII.NUL);
            return False;
         end if;
         Rule_Processor.Load_Clause (Str (1 .. Length));

         return True;

      exception
         when Text_IO.End_Error =>
            raise;
         when others =>
            Con_Io.Put_Line ("exception in Get_Clause");
            raise;
      end Get_Clause;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *  Load                          *  BODY
      -- *                                *
      -- **********************************
      function Load
        (File : in String;
         Lisp : in Boolean := False;
         Tro  : in Boolean := True)
         return Boolean
      is

         --| Purpose
         --| Load a rulebase from a file and interpret. if Lisp is FALSE
         --| use Prolog syntax.  Tail recursion is on if TRO is TRUE.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| May 29, 1993      PP             Exception for name added outside
         --loop

         Fp     : Text_IO.File_Type;
         Result : Boolean;
      begin
         if File = "" then
            null;
         else
            Text_IO.Open (Fp, Text_IO.In_File, File);
         end if;
         loop
            if Get_Clause (Fp, Lisp) then
               Result :=
                  Rule_Processor.Interpret
                    (Lisp_Syntax => Lisp,
                     Do_Tro      => Tro);
            end if;
         end loop;
      exception
         when Text_IO.End_Error =>
            if File = "" then
               null;
            else
               Text_IO.Close (Fp);
            end if;
            return True;
         when Text_IO.Name_Error =>
            Con_Io.Put_Line (File & " not found");
            return False;
         when others =>
            Con_Io.Put_Line ("Load stopped");
            raise;

      end Load;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Builtin_Predicates           *  BODY
      -- *                                *
      -- **********************************
      package body Builtin_Predicates is

         --| Purpose
         --| Package body for Builtin_Predicates
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions
         --| August 6, 1993    PP           Removed Push_Unify after Attach

         package Ll renames Linked_List;
         package Unif renames Unification;

         Nil : constant Lex.Goal_Value := Lex.Nil;

         R_Par : Lex.Goal_Value;
         L_Par : Lex.Goal_Value;

         Integer_Result : Boolean;

         Lisp_Name    : constant String := Getenv ("grp_temp", 
                                                   "temp.lsp");  -- I/O globals
         -- Writing_Fact : Boolean         := False;
         Telling      : Boolean         := False;
         Tell_File    : Text_IO.File_Type;

         Seeing   : Boolean := False;
         See_File : Text_IO.File_Type;

         Trace_On : Boolean := False;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Is_Trace_On                   *  BODY
         -- *                                *
         -- **********************************
         function Is_Trace_On return Boolean is
         begin
            return Trace_On;
         end Is_Trace_On;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Lisp_to_Prolog                *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Lisp_To_Prolog (From, To : in String) is

            --| Purpose
            --| Convert the LISP style internal factbase to Prolog style file.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Str         : String (1 .. Table_Sizes.Clause_Length_Max);
            Length      : Natural;
            Ch          : Character;
            Quote       : Boolean := False;
            Functor     : Boolean := False;
            End_Word    : Boolean := False;
            Parens      : Integer;
            Prolog_File : Text_IO.File_Type;
            Lisp_File   : Text_IO.File_Type;
            Stream      : Boolean;

            procedure Put (Ch : in Character) is
            begin
               if Stream then
                  Text_IO.Put (Tell_File, Ch);    -- Write to Telling file
               else
                  Text_IO.Put (Prolog_File, Ch);  -- Write to "To" file
               end if;
            end Put;

         begin

            Stream := (To = "");
            Text_IO.Open (Lisp_File, Text_IO.In_File, From);
            if not Stream then
               Text_IO.Create (Prolog_File, Text_IO.Out_File, To);
            end if;

            loop
               Text_IO.Get_Line (Lisp_File, Str, Length);
               Parens := 0;
               if Length > 2 then
                  if Str (1) /= '(' or Str (2 .. 3) = ":-" then
                     Length := 0;  -- Don't know how to save rule
                  end if;
               end if;
               for I in  1 .. Length loop
                  Ch := Str (I);
                  if Quote and Ch /= '"' then
                     Put (Ch);
                  else
                     case Ch is
                        when '(' =>
                           Functor := True;
                           Parens  := Parens + 1;
                        when ')' =>
                           if Str (I - 1) = '(' then
                              Put ('[');
                              Put (']');
                              Put (',');  -- empty list
                              Functor := False;
                           else
                              Put (Ch);
                              End_Word := True;
                           end if;
                           Parens := Parens - 1;
                        when '"' =>
                           Quote := not Quote;
                           Put (Ch);
                        when ' ' =>
                           End_Word := True;
                        when others =>
                           Put (Ch);
                     end case;
                  end if;
                  if End_Word and Functor then
                     Put ('(');
                     Functor  := False;
                     End_Word := False;
                  elsif End_Word and Parens > 0 then
                     if Str (I + 1) /= ')' then
                        Put (',');
                     end if;
                     End_Word := False;
                  end if;
               end loop;
               if Length > 0 then
                  Put ('.');
                  if Stream then
                     Text_IO.New_Line (Tell_File);
                  else
                     Text_IO.New_Line (Prolog_File);
                  end if;
               end if;
               End_Word := False;
            end loop;

         exception
            when Text_IO.End_Error =>
               Text_IO.Close (Lisp_File);
               if not Stream then
                  Text_IO.Close (Prolog_File);
               end if;
            when others =>
               Text_IO.Close (Lisp_File);
               if not Stream then
                  Text_IO.Close (Prolog_File);
               end if;
               Text_IO.Put_Line ("Prefix->Prolog");
         end Lisp_To_Prolog;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Tell                          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Tell (Str : in String) return Boolean is

         --| Purpose
         --| Redirect the output to Str device.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| April 29, 1993    PP             Modified for file redirection

         begin
            -- Writing_Fact := False;
            -- Token_Io.Open_File (Lisp_Name, Token_Io.Aux_Display);
            Text_IO.Create (Tell_File, Text_IO.Out_File, Str);
            Telling := True;
            return True;
         exception
            when others =>
               Con_Io.Put ("Tell error");
               return False;
         end Tell;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Told                          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Told return Boolean is

         --| Purpose
         --| Close the current redirected output stream.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version
         --| April 29, 1993    PP             Modified for file redirection
         --| May 20, 1993      PP             Added Telling := FALSE

         begin
            -- Token_Io.Close_File (Token_Io.Aux_Display);
            -- if Writing_Fact then
            --    Lisp_To_Prolog (From => Lisp_Name, To => "");
            -- end if;
            Text_IO.Close (Tell_File);
            Telling := False;
            return True;
         exception
            when others =>
               Con_Io.Put ("Told error");
               return False;
         end Told;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  See                           *  SPEC & BODY
         -- *                                *
         -- **********************************
         function See (Str : in String) return Boolean is

         --| Purpose
         --| Redirect the input from Str device.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 31, 1993    Paul Pukite    Initial Version

         begin
            Text_IO.Open (See_File, Text_IO.In_File, Str);
            Seeing := True;
            return True;
         exception
            when others =>
               Con_Io.Put ("See error");
               return False;
         end See;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Seen                          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Seen return Boolean is

         --| Purpose
         --| Close the current redirected input stream.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| Oct 31, 1993    Paul Pukite    Initial Version

         begin
            Text_IO.Close (See_File);
            Seeing := False;
            return True;
         exception
            when others =>
               Con_Io.Put ("Seen error");
               return False;
         end Seen;

         -- **********************************
         -- *                                *
         -- *   Parenthetic                  *  BODY
         -- *                                *
         -- **********************************
         function Parenthetic (Token : in Lex.Goal_Value) return Boolean is
         begin
            if Lex.Is_Builtin (Token) then
               return Lex.Get_Bip (Token) in P_Lrb .. P_Rsqb;
            end if;
            return False;
         end Parenthetic;
         -- pragma INLINE ( Parenthetic );

         -- **********************************
         -- *                                *
         -- *   Operation                    *  BODY
         -- *                                *
         -- **********************************
         function Operation (Token : in Lex.Goal_Value) return Boolean is
         begin
            if Lex.Is_Builtin (Token) then
               return Lex.Get_Bip (Token) in P_Is .. P_Ldot;
            end if;
            return False;
         end Operation;
         -- pragma INLINE ( Operation );

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Update_Goal                  *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Update_Goal
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Lex.Goal_Value
         is

            --| Purpose
            --| Update_Goal creates a copy of the goal starting at current
            --goal.
            --| Return will contain substituted values in place of variables
            --in the
            --| original goal.  Variables in the copy are thus unbound
            --variables which
            --| may get values assigned to them in the process of the
            --evaluation.
            --|
            --| Exceptions
            --|
            --| Notes
            --| This is a recursive call.
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions
            --| July 6, 1993      PP           Removed unused Temp variable,
            --added Is_Variable->Is_List->Update recursion

            Copy_Front,                   -- copy of CAR of goal
              Copy_Back : Lex.Goal_Value;   -- copy of CDR of goal

            New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            Return_Value  : Lex.Goal_Value;

         begin

            if Lex.Is_List (Goal) then    -- Recurse over other elements of
                                          --list.
               Copy_Front   := Update_Goal (Lex.Car (Goal), New_Frame_Ptr);
               Copy_Back    := Update_Goal (Lex.Cdr (Goal), New_Frame_Ptr);
               Return_Value := Ll.Set_Car_Cdr (Copy_Front, Copy_Back);
            else  -- Is an atomic or null goal.
               if Lex.Is_Variable (Goal) then
                  -- Get values of variables.
                  Unif.Lookup (Goal, New_Frame_Ptr, Return_Value);
                  if Lex.Is_List (Return_Value) then
                     Return_Value :=
                        Update_Goal (Return_Value, New_Frame_Ptr);
                  end if;
               else
                  Return_Value := Goal;
               end if;

            end if;

            return Return_Value;

         end Update_Goal;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Assert                       *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Assert
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Assert involves Clause_List manipulation and storage.  It
            --creates an
            --| updated copy of the clause to be stored using Update_Goal.
            --| This is added to Clause_List either at the start or at the end
            --of the
            --| grouping corresponding to the PID of the goal.  ASSERTA adds
            --to the
            --| beginning of the list.  ASSERT (i.e. ASSERTZ) adds to the end
            --of the list.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions
            --| July 6, 1993      PP           Fixed Update_Goal recursion

            Which_Assert, Pid, Clause : Lex.Goal_Value;
            Local_Clause_List         : Lex.Goal_Value;

         begin

            Which_Assert := Lex.Car (Goal);

            Clause := Lex.Cadr (Goal);

            Clause := Update_Goal (Clause, Frame_Ptr);
            if Lex.Is_Atomic (Clause) then            -- For single atoms
               Clause := Ll.Set_Car_Cdr (Clause, Nil);
            end if;

            if Lex.Is_Builtin_Token (Which_Assert, P_Assert) then
               Ll.Update_Clause_List (Clause);
               return True;
            end if;

            --| Otherwise, P_ASSERTA.  Assert at the beginning of the clause
            --list.

            Pid := Ll.Find_Principal_Id (Clause);

            Local_Clause_List :=
               Ll.Associated_List (Lex.Cdr (Ll.Clause_List), Pid);
            if Lex.Is_Nil (Local_Clause_List) then
               Local_Clause_List := Ll.Set_Car_Cdr (Pid, Nil);
               Ll.Construct (Ll.Clause_List, Local_Clause_List);
            end if;
            Clause := Ll.Set_Car_Cdr (Clause, Lex.Cdr (Local_Clause_List));
            Ll.Set_Cdr (Local_Clause_List, Clause);

            return True;

         end Assert;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Retract                      *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Retract
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Retract is opposite of Assert, removes the links to the list
            --associated
            --| with the clause.
            --|
            --| Exceptions
            --|
            --| Notes
            --| Modifies the global list LL.Clause_List.
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| October 30, 1991  PP           Fixed Is_Nil part
            --| April 26, 1993    PP           Heap extensions
            --| July 8, 1993      PP           Added Set_CAR_CDR, Atomic to
            --single atoms.  Added RetVal instead of return.

            Pid, Subgoal, Local_Clause_List, Assoc_Part, Current_Clause :
              Lex.Goal_Value;
            Last                                                        :
              Lex.Goal_Value := Nil;
            Atomic, Retval                                              :
              Boolean := False;
            New_Frame_Ptr                                               :
              Ver.Frame_Range;
            Local_Frame_Ptr                                             :
              Ver.Frame_Range := Frame_Ptr;
            function "+" (L, R : Ver.Frame_Range) return Ver.Frame_Range
               renames Ver. "+";
         begin

            Subgoal := Lex.Cadr (Goal);
            if Lex.Is_Variable (Subgoal) then
               Unif.Lookup (Subgoal, Local_Frame_Ptr, Subgoal);
            end if;

            if Lex.Is_Atomic (Subgoal) then  -- single atoms
               Atomic := True;
               Pid    := Subgoal; --was-> Subgoal := LEX.CDR ( Goal );
            else
               Pid := Ll.Find_Principal_Id (Subgoal);
            end if;

            Assoc_Part := Ll.Associated_List (Lex.Cdr (Ll.Clause_List), Pid);
            if Lex.Is_Nil (Assoc_Part) then
               -- Nothing to retract.
               return False;
            end if;

            if Atomic then
               Subgoal := Ll.Set_Car_Cdr (Subgoal, Nil);
            end if;

            Local_Clause_List := Lex.Cdr (Assoc_Part);

            while Lex.Is_Goal (Local_Clause_List) loop
               Current_Clause := Lex.Car (Local_Clause_List);
               New_Frame_Ptr  := Ver.Get_Next_Frame;
               Retval         :=
                  Ver.Copy_Clause (New_Frame_Ptr + 1, Current_Clause);

               -- Match the argument pattern to goals that can be retracted
               Retval :=
                  Unif.Unify
                    (Subgoal,
                     Current_Clause,
                     Local_Frame_Ptr,
                     New_Frame_Ptr);
               if Retval then
                  if Lex.Is_Nil (Lex.Cdr (Local_Clause_List)) then
                     Ll.Set_Car (Local_Clause_List, Nil);
                     if Lex.Is_Nil (Last) then
                        Ll.Set_Cdr (Assoc_Part, Nil);
                     else
                        Ll.Set_Cdr (Last, Nil);
                     end if;
                  else
                     Ll.Set_Car
                       (Local_Clause_List,
                        Lex.Cadr (Local_Clause_List));
                     Ll.Set_Cdr
                       (Local_Clause_List,
                        Lex.Cddr (Local_Clause_List));
                  end if;
                  exit;
               end if;

               Last := Local_Clause_List;

               Local_Clause_List := Lex.Cdr (Local_Clause_List);

            end loop;

            return Retval;

         end Retract;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Findall                      *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Findall
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is
            --| Purpose
            --| Findall finds all the solutions to a given goal and
            --| collects the values of the variable to be unified into a list.
            --This
            --| activity is controlled through a recursive call to
            --Verify.Resolve.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Old_Frame_Ptr    : Ver.Frame_Range;
            Solution         : Lex.Goal_Value;
            Variable, A_Goal : Lex.Goal_Value;
            Local_Frame_Ptr  : Ver.Frame_Range := Frame_Ptr;
         begin

            --|  Findall must be in format of findall(X, goal(X), Z).
            --|  Otherwise, check to see if enough args are in the goal before
            --starting.
            --|      if ( Goal <= NIL or LEX.CDR ( Goal ) <= NIL or LEX.CDDR (
            --Goal ) <= NIL
            --|           or LEX.CDR ( LEX.CDDR ( Goal ) ) <= NIL ) then
            --|         return FALSE;
            --|      end if;

            Old_Frame_Ptr := Local_Frame_Ptr;
            Variable      := Lex.Cadr (Goal);
            Unif.Lookup (Variable, Local_Frame_Ptr, Variable);
            if not Lex.Is_Variable (Variable) then
               -- FIRST argument must be a variable.
               return False;
            end if;

            Ver.Set_Findall_Variable (Variable);   -- Match against this
                                                   --variable.

            Local_Frame_Ptr := Old_Frame_Ptr;
            A_Goal          := Lex.Caddr (Goal);
            if Lex.Is_Variable (A_Goal) then
               Unif.Lookup (A_Goal, Local_Frame_Ptr, A_Goal);
            end if;

            Local_Frame_Ptr := Old_Frame_Ptr;
            Variable        := Lex.Cadr (Lex.Cddr (Goal));
            Unif.Lookup (Variable, Local_Frame_Ptr, Variable);
            if not Lex.Is_Variable (Variable) then
               -- SECOND argument must be a variable.
               return False;
            end if;

            -- Find all matches to the query.

            Solution :=
               Ver.Resolve
                 (A_Query        => A_Goal,
                  Frame_Ptr      => Local_Frame_Ptr,
                  Multiple_Goals => True);

            Unif.Attach (Variable, Old_Frame_Ptr, Solution, Local_Frame_Ptr);
            return True;

         end Findall;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Logical_Not                  *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Logical_Not
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Logical_Not processes a 'not' operation as a builtin.
            --|
            --| Exceptions
            --|
            --| Notes
            --| Recursion to Verify.Resolve procedure.
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Solution : Lex.Goal_Value;
         begin

            Solution :=
               Ver.Resolve
                 (A_Query        => Lex.Cadr (Goal),
                  Frame_Ptr      => Frame_Ptr,
                  Multiple_Goals => False);

            -- If succeeds, return as failure and vice versa.
            return (not Lex.Is_Goal (Solution));

         end Logical_Not;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Evaluate_Expression          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Evaluate_Expression
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Lex.Calc_Flt
         is

            --| Purpose
            --| Evaluation of arithmetic expressions, assuming only integer
            --numbers.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions
            --| August 11, 1993   PP           Added ASCII string computation

            Value         : Lex.Calc_Flt;
            Pid           : Predicates;
            Arg1, Arg2    : Lex.Goal_Value;
            New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            Temp          : Lex.Goal_Value;

            function String_Value (Str : in String) return Lex.Calc_Flt is
               Value : Lex.Calc_Flt := 0.0;
            begin
               for I in  Str'Range loop
                  Value := Value * Lex.Calc_Flt (I - Str'First + 1) * 128.0 +
                           Lex.Calc_Flt (Character'Pos (Str (I)));
               end loop;
               Integer_Result := False;
               return Value;
            end String_Value;

         begin

            if Lex.Is_Token (Goal) then -- and not Is_Builtin ( Goal ) then
               -- Easiest expressions are those just one atom.

               if Lex.Is_Integer (Goal) then   -- If this atom is an integer,

                  Value := Lex.Calc_Flt (Lex.Get_Int (Goal));

               elsif Lex.Is_Float (Goal) then

                  Value          := Lex.Get_Flt (Goal);
                  Integer_Result := False;

               elsif Lex.Is_Variable (Goal) then
                  -- Can not evaluate unbound variable.
                  Unif.Lookup (Goal, New_Frame_Ptr, Temp);

                  if Lex.Is_Integer (Temp) then

                     Value := Lex.Calc_Flt (Lex.Get_Int (Temp));

                  elsif Lex.Is_Float (Temp) then

                     Value          := Lex.Get_Flt (Temp);
                     Integer_Result := False;

                  elsif Lex.Is_Atomic (Goal) then

                     Value := String_Value (Lex.Get_Sym (Goal));

                  else
                     -- Found unbound variable in expression.
                     raise Rule_Errors.Unbound_Variable_Error;
                  end if;

               elsif Lex.Is_Atomic (Goal) then

                  Value := String_Value (Lex.Get_Sym (Goal));

               else -- Nonnumeric quantity in expression.
                  raise Rule_Errors.Nonnumeric_Error;
               end if;

            else -- Expression of more than one atom.
               Pid := Lex.Get_Bip (Lex.Car (Goal));   -- Get the arithmetic
                                                      --operator.

               Arg1 := Lex.Cadr (Goal);
               Arg2 := Lex.Car (Lex.Cddr (Goal));

               -- Expression is ( Pid Arg1 Arg2 ) in Prefix notation.
               -- This is more efficient as a case statement but some
               -- compilers don't take it.

               case Pid is
               when P_Plus =>     --elsif Pid = P_BMINUS then  --
                  Value := Evaluate_Expression (Arg1, Frame_Ptr) +
                           Evaluate_Expression (Arg2, Frame_Ptr);
               when P_Bminus =>   --elsif Pid = P_BMINUS then  --
                  Value := Evaluate_Expression (Arg1, Frame_Ptr) -
                           Evaluate_Expression (Arg2, Frame_Ptr);
               when P_Mult =>    --elsif Pid = P_MULT then    --
                  Value := Evaluate_Expression (Arg1, Frame_Ptr) *
                           Evaluate_Expression (Arg2, Frame_Ptr);
               when P_Div =>     --elsif Pid = P_DIV then     --
                  Value := Evaluate_Expression (Arg1, Frame_Ptr) /
                           Evaluate_Expression (Arg2, Frame_Ptr);
               when P_Uminus =>  --elsif Pid = P_UMINUS then  --
                  Value := -Evaluate_Expression (Arg1, Frame_Ptr);
               when P_Mod =>     --elsif Pid = P_MOD then     --
                  Value :=
                    Lex.Calc_Flt (Lex.Calc_Int (Evaluate_Expression
                                                   (Arg1,
                                                    Frame_Ptr)) mod
                                  Lex.Calc_Int (Evaluate_Expression
                                                   (Arg2,
                                                    Frame_Ptr)));
               when P_Idiv =>    --elsif Pid = P_IDIV then    --
                  Value :=
                    Lex.Calc_Flt (Lex.Calc_Int (Evaluate_Expression
                                                   (Arg1,
                                                    Frame_Ptr)) /
                                  Lex.Calc_Int (Evaluate_Expression
                                                   (Arg2,
                                                    Frame_Ptr)));
               when P_Integer =>  --elsif Pid = P_INTEGER then  --
                  Value          := Evaluate_Expression (Arg1, Frame_Ptr);
                  Integer_Result := True;
               when P_Float =>  --elsif Pid = P_FLOAT then  --
                  Value          := Evaluate_Expression (Arg1, Frame_Ptr);
                  Integer_Result := False;
               when others =>    --else                       --
                  -- Unexpected function in arithmetic expression.
                  raise Rule_Errors.Evaluate_Error;
               end case; --end if;                    --

            end if;

            return Value;

         end Evaluate_Expression;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Arithmetic_Expression        *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Arithmetic_Expression
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Evaluate truth value of arithmetic expressions.
            --| Expression must be of the form ( Pid Arg1 Arg2 ).
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Success              : Boolean := False;
            Arg1, Arg2, Location : Lex.Goal_Value;
            Pid                  : Predicates;
            Ival1, Ival2         : Lex.Calc_Int;
            Fval1, Fval2         : Lex.Calc_Flt;
         begin

            Pid := Lex.Get_Bip (Lex.Car (Goal));

            Arg1 := Lex.Cadr (Goal);
            Arg2 := Lex.Car (Lex.Cddr (Goal));

            if Pid = P_Is then -- Assignment of values

               if Lex.Is_Variable (Arg2) then
                  -- Right side of arithmetic 'is' must be computable.
                  raise Rule_Errors.Compute_Error;
               end if;

               Integer_Result := True;
               Fval2          := Evaluate_Expression (Arg2, Frame_Ptr);
               if Integer_Result then
                  Ival2 := Lex.Calc_Int (Fval2);
               end if;

               if Lex.Is_Variable (Arg1) then
                  -- Add value or lookup in integer table. Unify the value
                  --with Arg1.
                  if Integer_Result then
                     Location := Lex.Add_Integer (Ival2);
                  else
                     Location := Lex.Add_Float (Fval2);
                  end if;
                  Unif.Attach (Arg1, Frame_Ptr, Location, Frame_Ptr);
                  Success := True;

               else -- Compare the value with Arg1.
                  Fval1 := Evaluate_Expression (Arg1, Frame_Ptr);
                  if Integer_Result then
                     Ival1 := Lex.Calc_Int (Fval1);
                     if Ival1 = Ival2 then
                        Success := True;
                     end if;
                  else
                     if Fval1 = Fval2 then
                        Success := True;
                     end if;
                  end if;
               end if;

            else
               if Lex.Is_Variable (Arg1) or Lex.Is_Variable (Arg2) then
                  -- Unbound variable in arithmetic relation.
                  raise Rule_Errors.Unbound_Relation_Error;
               end if;
               Fval1 := Evaluate_Expression (Arg1, Frame_Ptr);
               Fval2 := Evaluate_Expression (Arg2, Frame_Ptr);

               -- Do logical or relational operators.
               -- This is more efficient as a case statement but some
               -- compilers don't take it.

               if Pid = P_Sequal then   -- when P_SEQUAL =>
                  if Fval1 = Fval2 then
                     Success := True;
                  end if;
               elsif Pid = P_Lt then    -- when P_LT =>
                  if Fval1 < Fval2 then
                     Success := True;
                  end if;
               elsif Pid = P_Gt then    -- when P_GT =>
                  if Fval1 > Fval2 then
                     Success := True;
                  end if;
               elsif Pid = P_Le then    -- when P_LE =>
                  if Fval1 <= Fval2 then
                     Success := True;
                  end if;
               elsif Pid = P_Ge then    -- when P_GE =>
                  if Fval1 >= Fval2 then
                     Success := True;
                  end if;
               elsif Pid = P_Ne then    -- when P_NE =>
                  if Fval1 /= Fval2 then
                     Success := True;
                  end if;
               else                     -- when others =>
                  -- Illegal parameter in arithmetic expression.
                  raise Rule_Errors.Relation_Error;

               end if;                  -- end case;

            end if;

            return Success;

         end Arithmetic_Expression;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Listing                      *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Listing
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
         is

            --| Purpose
            --| Listing of all clauses of the Goal PID
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| November 10, 1991  Paul Pukite  Initial Version
            --| April 26, 1993     PP           Heap extensions

            List, List_Clauses, Pid : Lex.Goal_Value;

            procedure Print_Listing (Clauses : in Lex.Goal_Value) is
               Element : Lex.Goal_Value;
               Local   : Lex.Goal_Value := Clauses;
            begin

               loop
                  exit when Lex.Is_Nil (List_Clauses);
                  Element := Lex.Car (List_Clauses);
                  Pid     := Ll.Find_Principal_Id (Element);
                  if not Lex.Is_Builtin (Pid) then    -- do not list buitins
                                                      --like ";"
                     Token_Io.Print_Driver
                       (Token_Io.Aux_Display,
                        Element,
                        Ver.Frame_Range'First);
                     Token_Io.New_Line (Token_Io.Aux_Display);
                  end if;
                  List_Clauses := Lex.Cdr (List_Clauses);
               end loop;

            end Print_Listing;

         begin

            if Lex.Is_Nil (Goal) or else Lex.Is_Nil (Lex.Cadr (Goal)) then
               List := Lex.Cdr (Ll.Clause_List);
               loop
                  exit when Lex.Is_Nil (List);
                  List_Clauses := Lex.Cdr (Lex.Car (List));
                  Print_Listing (List_Clauses);
                  List := Lex.Cdr (List);
               end loop;
            else
               List         := Lex.Cadr (Goal);
               Pid          := Ll.Find_Principal_Id (List);
               List_Clauses :=
                  Lex.Cdr
                    (Ll.Associated_List (Lex.Cdr (Ll.Clause_List), Pid));
               Print_Listing (List_Clauses);
            end if;

         end Listing;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Concat                       *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Concat
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Concatenate a list of items together.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version
            --| April 13, 1993    PP             Don't concat ""

            List, Var     : Lex.Goal_Value;
            Var_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            Str           : String (1 .. Table_Sizes.Word_Length_Max);
            Pos           : Lex.Max_String  := 1;

            procedure Add (Val : in String) is
               Length : Lex.Max_String := Val'Length;
            begin
               if Val (Val'First) = '"' then  -- don't concat ""
                  if Val'Last = Val'First + 1
                    and then Val (Val'Last) = '"'
                  then
                     return;
                  end if;
               end if;
               Str (Pos .. Pos + Length - 1) := Val (Val'First .. Val'Last);
               Pos                           := Pos + Length;
            end Add;

            procedure Len
              (Goal      : in Lex.Goal_Value;
               Frame_Ptr : in Ver.Frame_Range)
            is

               New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
               New_Goal      : Lex.Goal_Value  := Goal;

            begin

               if Lex.Is_Variable (Goal) then
                  -- Get values of variables.
                  Unif.Lookup (Goal, New_Frame_Ptr, New_Goal);
               end if;

               if Lex.Is_List (New_Goal) then
                  -- Recurse over other elements of list.
                  Len (Lex.Car (New_Goal), New_Frame_Ptr);
                  Len (Lex.Cdr (New_Goal), New_Frame_Ptr);
               elsif Lex.Is_Integer (New_Goal) then
                  Add (Token_Io.Intstr (Lex.Get_Int (New_Goal)));
               elsif Lex.Is_Float (New_Goal) then
                  Add (Token_Io.Fltstr (Lex.Get_Flt (New_Goal)));
               elsif Lex.Is_Atomic (New_Goal) or
                     Lex.Is_Builtin (New_Goal) or
                     Lex.Is_Variable (New_Goal)
               then
                  if not Lex.Is_Builtin_Token (New_Goal, P_Period) then
                     -- Don't include pipe dot
                     Add (Lex.Get_Sym (New_Goal));
                  end if;
               end if;
            end Len;

         begin -- Concat

            List := Lex.Cadr (Goal);

            Var := Lex.Caddr (Goal);

            if Lex.Is_Variable (Var) then
               Unif.Lookup (Var, Var_Frame_Ptr, Var);
            end if;

            Len (List, Frame_Ptr);

            --             if Lex.Is_Variable (Var) and Pos > 1 then
            --                Unif.Attach
            --                  (Var, Frame_Ptr,
            --                   Lex.Make_Atom (Lex.Add_Word (Str (1 .. Pos -
            --1))), Frame_Ptr);
            --                return True;
            --             else
            --                return False;
            --             end if;

            if Pos > 1 then
               if Lex.Is_Variable (Var) then
                  Unif.Attach
                    (Var,
                     Frame_Ptr,
                     Lex.Make_Atom (Lex.Add_Word (Str (1 .. Pos - 1))),
                     Frame_Ptr);
                  return True;
               elsif Lex.Is_Atomic (Var) then
                  return Str (1 .. Pos - 1) = Lex.Get_Sym (Var);
               else
                  return False;
               end if;
            else
               return False;
            end if;

         end Concat;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_String                    *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Get_String
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      String
         is

            --| Purpose
            --| Convert a atom or variable to its bound string.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Var            : Lex.Goal_Value;
            Temp_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
         begin
            Var := Lex.Cadr (Goal);

            if Lex.Is_Variable (Var) then
               Unif.Lookup (Var, Temp_Frame_Ptr, Var);
            end if;
            if Lex.Is_Atomic (Var) then
               return Lex.Get_Sym (Var);
            else
               return "";
            end if;
         end Get_String;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Read                         *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Read
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range;
            Dde_On    : Boolean := False)
            return      Boolean
         is

            --| Purpose
            --| Read a symbol from the console or from DDE.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version
            --| Oct   11, 1993    PP             Returned INTEGER DDE State
            --info

            Var           : Lex.Goal_Value;
            Var_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            Value         : Lex.Calc_Int    := 0;
            Fvalue        : Lex.Calc_Flt    := 0.0;
            Str           : String (1 .. Table_Sizes.Word_Length_Max);
            Last, Pos     : Lex.Max_String  := 1;
            Is_Int        : Boolean         := True;
            Is_Flt        : Boolean         := False;
            Status        : Lex.Goal_Value;
            State         : Integer;

            Id        : Lex.Calc_Int;
            Key, Atom : Lex.Goal_Value;

         begin -- Read

            if Dde_On then
               Key    := Lex.Cadr (Goal);
               Atom   := Lex.Caddr (Goal);
               Var    := Lex.Caddr (Lex.Cdr (Goal));
               Status := Lex.Caddr (Lex.Cddr (Goal));

               -- Last term Var must be variable
               --                Var_Frame_Ptr := Frame_Ptr;
               --                if Lex.Is_Variable (Var) then
               --                   Unif.Lookup (Var, Var_Frame_Ptr, Var);
               --                end if;
               --               if not Lex.Is_Variable (Var) then
               --                  return False;
               --               end if;

               -- First term keyword must be integer
               Var_Frame_Ptr := Frame_Ptr;
               if Lex.Is_Variable (Key) then
                  Unif.Lookup (Key, Var_Frame_Ptr, Key);
               end if;
               if Lex.Is_Integer (Key) then
                  Id := Lex.Get_Int (Key);
               else
                  return False;
               end if;

               -- Second term keyword must be converted into string
               Var_Frame_Ptr := Frame_Ptr;
               if Lex.Is_Variable (Atom) then
                  Unif.Lookup (Atom, Var_Frame_Ptr, Atom);
               end if;

               -- Check last term for variable
               Var_Frame_Ptr := Frame_Ptr;
               if Lex.Is_Variable (Var) then
                  Unif.Lookup (Var, Var_Frame_Ptr, Var);
               end if;
               if Lex.Is_Variable (Var) then
                  null;
               else
                  -- Check for bound last term equality
                  if Lex.Is_Atomic (Atom) and Lex.Is_Atomic (Var) then
                     Con_Io.Exchange
                       (Id,
                        Lex.Get_Sym (Atom),
                        Str,
                        Last,
                        State);
                     return Str (1 .. Last) = Lex.Get_Sym (Var);
                  elsif Lex.Is_Atomic (Atom) and Lex.Is_Integer (Var) then
                     Con_Io.Exchange
                       (Id,
                        Lex.Get_Sym (Atom),
                        Str,
                        Last,
                        State);
                     return Integer'Value (Str (1 .. Last)) =
                            Lex.Get_Int (Var);
                  elsif Lex.Is_Atomic (Atom) and Lex.Is_Float (Var) then
                     Con_Io.Exchange
                       (Id,
                        Lex.Get_Sym (Atom),
                        Str,
                        Last,
                        State);
                     return Float'Value (Str (1 .. Last)) =
                            Lex.Get_Flt (Var);
                  else
                     return False;
                  end if;
               end if;

               if Lex.Is_Atomic (Atom) or Lex.Is_Builtin (Atom) then
                  Con_Io.Exchange (Id, Lex.Get_Sym (Atom), Str, Last, State);
               elsif Lex.Is_Integer (Atom) then
                  Con_Io.Exchange
                    (Id,
                     Token_Io.Intstr (Lex.Get_Int (Atom)),
                     Str,
                     Last,
                     State);
               elsif Lex.Is_Float (Atom) then
                  Con_Io.Exchange
                    (Id,
                     Token_Io.Fltstr (Lex.Get_Flt (Atom), Short => False),
                     Str,
                     Last,
                     State);
               else
                  return False;
               end if;

               if Lex.Is_Nil (Status) then
                  null;
               else
                  -- Last term Status
                  Var_Frame_Ptr := Frame_Ptr;
                  if Lex.Is_Variable (Status) then
                     Unif.Lookup (Status, Var_Frame_Ptr, Status);
                  end if;
                  if Lex.Is_Variable (Status) then
                     Unif.Attach
                       (Status,
                        Frame_Ptr,
                        Lex.Add_Integer (State),
                        Frame_Ptr);
                  else
                     if Lex.Get_Int (Status) /= State then
                        return False;
                     end if;
                  end if;
               end if;

               if Last < 0 or State = 0 then
                  return False;
               end if;

            else
               Var := Lex.Cadr (Goal);

               if Lex.Is_Variable (Var) then
                  Unif.Lookup (Var, Var_Frame_Ptr, Var);
               end if;

               if not Lex.Is_Variable (Var) then
                  return False;
               end if;

               if Seeing then
                  Text_IO.Get_Line (See_File, Str, Last);
               else
                  Con_Io.Put ("? ");
                  Con_Io.Get_Line (Str, Last);
               end if;
               if Last = 0 then
                  return False;
               end if;
            end if;

            for I in  1 .. Last loop
               Pos := I;
               if Str (I) in '0' .. '9' then
                  null;
               else
                  Is_Int := False;
               end if;
            end loop;

            if Is_Int then
               Iio.Get (Str (1 .. Pos), Value, Last);
            else
               begin
                  Fio.Get (Str (1 .. Pos), Fvalue, Last);
                  Is_Flt := Pos = Last;
               exception
                  when others =>
                     null;
               end;
            end if;

            if Is_Int then
               Unif.Attach
                 (Var,
                  Frame_Ptr,
                  Lex.Add_Integer (Value),
                  Frame_Ptr);
            elsif Is_Flt then
               Unif.Attach
                 (Var,
                  Frame_Ptr,
                  Lex.Add_Float (Fvalue),
                  Frame_Ptr);
            else
               Unif.Attach
                 (Var,
                  Frame_Ptr,
                  Lex.Make_Atom (Lex.Add_Word (Str (1 .. Pos))),
                  Frame_Ptr);
            end if;

            return True;

         exception
            when Text_IO.End_Error =>
               return False;
            when others =>
               Con_Io.Put ("Read error");
               return False;

         end Read;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Tabs                         *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Tabs
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Output a number of tabs, right now a tab is a space.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| Oct 26, 1993    Paul Pukite    Initial Version

            Num           : Lex.Goal_Value;
            New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
         begin

            Num := Lex.Cadr (Goal);

            if Lex.Is_Variable (Num) then
               Unif.Lookup (Num, New_Frame_Ptr, Num);
            end if;

            if not Lex.Is_Integer (Num) then
               return False;
            end if;
            for I in  1 .. Lex.Get_Int (Num) loop
               if Telling then
                  Text_IO.Put (Tell_File, ' ');
               else
                  Con_Io.Put (' ');
               end if;
            end loop;
            return True;

         end Tabs;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Save_File                    *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Save_File
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Save a database file.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Name          : Lex.Goal_Value;
            New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
         begin

            Name := Lex.Cadr (Goal);

            if Lex.Is_Variable (Name) then
               Unif.Lookup (Name, New_Frame_Ptr, Name);
            end if;

            if Lex.Is_Atomic (Name) then
               -- Creating
               Token_Io.Open_File
                 (File_Name => Lisp_Name,
                  Fp        => Token_Io.Aux_Display);
               Listing (Nil, Frame_Ptr);
               Token_Io.Close_File (Fp => Token_Io.Aux_Display);

               -- Converting
               Lisp_To_Prolog (From => Lisp_Name, To => Lex.Get_Sym (Name));
               return True;
            else
               return False;
            end if;

         end Save_File;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Same                         *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Same
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Are 2 goals identical?
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Left, Right     : Lex.Goal_Value;
            Left_Frame_Ptr  : Ver.Frame_Range := Frame_Ptr;
            Right_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
         begin

            Left := Lex.Cadr (Goal);
            if Lex.Is_Variable (Left) then
               Unif.Lookup (Left, Left_Frame_Ptr, Left);
            end if;

            Right := Lex.Caddr (Goal);
            if Lex.Is_Variable (Right) then
               Unif.Lookup (Right, Right_Frame_Ptr, Right);
            end if;

            if Lex.Is_Variable (Left) and Lex.Is_Variable (Right) then
               null;
            elsif Lex.Is_Variable (Left) and
                  not Lex.Is_Variable (Right)
            then
               Unif.Attach (Left, Left_Frame_Ptr, Right, Right_Frame_Ptr);
            elsif Lex.Is_Variable (Right) and
                  not Lex.Is_Variable (Left)
            then
               Unif.Attach (Right, Right_Frame_Ptr, Left, Left_Frame_Ptr);
            else
               if not Unif.Unify
                        (Left,
                         Right,
                         Left_Frame_Ptr,
                         Right_Frame_Ptr)
               then
                  return False;
               end if;
            end if;
            return True;

         end Same;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Not_Same                     *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Not_Same
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Are 2 goals different?
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Left, Right     : Lex.Goal_Value;
            Left_Frame_Ptr  : Ver.Frame_Range := Frame_Ptr;
            Right_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
         begin

            Left := Lex.Cadr (Goal);
            if Lex.Is_Variable (Left) then
               Unif.Lookup (Left, Left_Frame_Ptr, Left);
            end if;

            Right := Lex.Caddr (Goal);
            if Lex.Is_Variable (Right) then
               Unif.Lookup (Right, Right_Frame_Ptr, Right);
            end if;

            if not Lex.Is_Variable (Left) and
               not Lex.Is_Variable (Right)
            then
               if not Unif.Unify
                        (Left,
                         Right,
                         Left_Frame_Ptr,
                         Right_Frame_Ptr)
               then
                  return True;
               end if;
            end if;
            return False;

         end Not_Same;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Length                       *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Length
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Get the length of a list.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Value         : Lex.Calc_Int    := 0;
            List, Var     : Lex.Goal_Value;
            Var_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;

            procedure Len
              (Goal      : in Lex.Goal_Value;
               Frame_Ptr : in Ver.Frame_Range)
            is

               New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
               New_Goal      : Lex.Goal_Value  := Goal;

            begin

               if Lex.Is_Variable (Goal) then
                  -- Get values of variables.
                  Unif.Lookup (Goal, New_Frame_Ptr, New_Goal);
               end if;

               if Lex.Is_List (New_Goal) then
                  -- Recurse over other elements of list.
                  Len (Lex.Car (New_Goal), New_Frame_Ptr);
                  Len (Lex.Cdr (New_Goal), New_Frame_Ptr);
               elsif Lex.Is_Numeric (New_Goal) or
                     Lex.Is_Atomic (New_Goal)
               then
                  Value := Value + 1;
               end if;
            end Len;

         begin -- Length

            List := Lex.Cadr (Goal);

            Var := Lex.Caddr (Goal);
            if Lex.Is_Variable (Var) then
               Unif.Lookup (Var, Var_Frame_Ptr, Var);
            end if;

            Len (List, Frame_Ptr);

            if Lex.Is_Variable (Var) then
               Unif.Attach
                 (Var,
                  Frame_Ptr,
                  Lex.Add_Integer (Value),
                  Frame_Ptr);
               return True;
            else
               return (Lex.Is_Integer (Var)
                      and then Value = Lex.Get_Int (Var));
            end if;

         end Length;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Arg                          *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Arg
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Get the Nth argument of a list.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Value          : Lex.Calc_Int    := 0;
            End_Value      : Lex.Calc_Int;
            Pos, List, Var : Lex.Goal_Value;
            Match          : Lex.Goal_Value  := Lex.Nil;
            Var_Frame_Ptr  : Ver.Frame_Range := Frame_Ptr;

            procedure Len
              (Goal      : in Lex.Goal_Value;
               Frame_Ptr : in Ver.Frame_Range)
            is

               New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
               New_Goal      : Lex.Goal_Value  := Goal;

            begin

               if Lex.Is_Variable (Goal) then
                  -- Get values of variables.
                  Unif.Lookup (Goal, New_Frame_Ptr, New_Goal);
               end if;

               if Lex.Is_List (New_Goal) then
                  -- Recurse over other elements of list.
                  Len (Lex.Car (New_Goal), New_Frame_Ptr);
                  Len (Lex.Cdr (New_Goal), New_Frame_Ptr);
               elsif Lex.Is_Numeric (New_Goal) or
                     Lex.Is_Atomic (New_Goal)
               then
                  Value := Value + 1;
                  if End_Value = Value then
                     Match := New_Goal;
                  end if;
               end if;
            end Len;

         begin -- Arg

            Pos  := Lex.Cadr (Goal);
            List := Lex.Caddr (Goal);
            Var  := Lex.Caddr (Lex.Cdr (Goal));

            if Lex.Is_Variable (Pos) then
               Unif.Lookup (Pos, Var_Frame_Ptr, Pos);
            end if;
            if Lex.Is_Integer (Pos) then
               End_Value := Lex.Get_Int (Pos);
            else
               return False;
            end if;

            Len (List, Frame_Ptr);

            Var_Frame_Ptr := Frame_Ptr;
            if Lex.Is_Variable (Var) then
               Unif.Lookup (Var, Var_Frame_Ptr, Var);
            end if;

            if Lex.Is_Variable (Var) then
               Unif.Attach (Var, Frame_Ptr, Match, Frame_Ptr);
               if Lex.Is_Nil (Match) then
                  return False;
               else
                  return True;
               end if;
            else
               return Lex.Same (Var, Match);  -- if last term is bound
               --return False;
            end if;

         end Arg;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print                        *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Print
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Boolean
         is

            --| Purpose
            --| Print an item or a list of items consecutively.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version
            --| May 20, 1993      PP             Added more Float digits if
            --Telling

            List : Lex.Goal_Value;

            procedure Len
              (Goal      : in Lex.Goal_Value;
               Frame_Ptr : in Ver.Frame_Range)
            is

               New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
               New_Goal      : Lex.Goal_Value  := Goal;

               procedure Put (Str : in String) is
               begin
                  if Telling then
                     Text_IO.Put (Tell_File, Str);
                  else
                     Con_Io.Put (Str);
                  end if;
               end Put;

            begin

               if Lex.Is_Variable (Goal) then
                  -- Get values of variables.
                  Unif.Lookup (Goal, New_Frame_Ptr, New_Goal);
               end if;

               if Lex.Is_List (New_Goal) then
                  -- Recurse over other elements of list.
                  Len (Lex.Car (New_Goal), New_Frame_Ptr);
                  Len (Lex.Cdr (New_Goal), New_Frame_Ptr);
               elsif Lex.Is_Integer (New_Goal) then
                  Put (Token_Io.Intstr (Lex.Get_Int (New_Goal)));
               elsif Lex.Is_Float (New_Goal) then
                  Put
                    (Token_Io.Fltstr
                        (Lex.Get_Flt (New_Goal),
                         Short => not Telling));
               elsif Lex.Is_Atomic (New_Goal) or
                     Lex.Is_Builtin (New_Goal) or
                     Lex.Is_Variable (New_Goal)
               then
                  if not Lex.Is_Builtin_Token (New_Goal, P_Period) then
                     -- Don't include pipe dot
                     Put (Lex.Get_Sym (New_Goal));
                  end if;
               end if;
            end Len;

         begin -- Print

            List := Lex.Cadr (Goal);
            Len (List, Frame_Ptr);
            return True;

         end Print;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Is_Type                      *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Is_Type
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range;
            Content   : in Lex.Contents)
            return      Boolean
         is
            --| Purpose
            --| Determines if a variable argument is currently instantiated.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| November 10, 1991  Paul Pukite  Initial Version

            Temp_Goal     : Lex.Goal_Value  := Lex.Cadr (Goal);
            New_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            Answer        : Boolean;
         begin
            if Lex.Is_Variable (Temp_Goal) then
               Unif.Lookup (Temp_Goal, New_Frame_Ptr, Temp_Goal);
            end if;
            case Content is
               when Lex.Var =>
                  Answer := Lex.Is_Variable (Temp_Goal);
               when Lex.Sym =>
                  Answer := Lex.Is_Atomic (Temp_Goal);
               when Lex.Int =>
                  Answer := Lex.Is_Integer (Temp_Goal);
               when Lex.Flt =>
                  Answer := Lex.Is_Float (Temp_Goal);
               when others =>
                  Answer := False;
            end case;
            return Answer;
         end Is_Type;

         -- **********************************
         -- *                                *
         -- *   Evaluate_Builtin             *  BODY
         -- *                                *
         -- **********************************
         function Evaluate_Builtin
           (Goal      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Builtin_Result
         is

            --| Notes
            --| Main builtin and math driver routine - called from Query.

            Success : Boolean := False;
            Head    : Predicates;
         begin

            Head := Lex.Get_Bip (Lex.Car (Goal));
            -- First take care of non-arithmetic builtins.
            -- This is more efficient as a case statement but some
            -- compilers don't take it.

            case Head is

            when P_Not =>  --if Head = P_NOT then
                           ----
               Success := Logical_Not (Goal, Frame_Ptr);

            when P_Sequal | P_Lt | P_Gt | --elsif ( Head = P_SEQUAL or Head =
                                          --P_LT or Head = P_GT or  --
P_Le | P_Ge | P_Ne | --        Head = P_LE or Head = P_GE or Head = P_NE or
                     ----
P_Is =>   --        Head = P_IS ) then                                --
               -- Copy the builtin function to temporary location and evaluate.
               Success :=
                  Arithmetic_Expression
                    (Update_Goal (Goal, Frame_Ptr),
                     Frame_Ptr);

            -- Otherwise determine if a standard builtin function.
            -- Process arithmetic and logical operations.

            when P_Findall =>             --elsif Head = P_FINDALL then
                                          ----
               Success := Findall (Goal, Frame_Ptr);
            when P_Assert | P_Asserta =>  --elsif ( Head = P_ASSERT or Head =
                                          --P_ASSERTA ) then --
               Success := Assert (Goal, Frame_Ptr);
            when P_Retract =>             --elsif Head = P_RETRACT then
                                          ----
               Success := Retract (Goal, Frame_Ptr);
            when P_Fail =>                --elsif Head = P_FAIL then
                                          ----
               Success := False;

            -- Optional Builtin

            when P_Trace =>               --elsif Head = P_TRACE then
                                          ----
               Trace_On := not Trace_On;
               Success  := True;

            when P_Var =>                 --elsif Head = P_VAR then
                                          ----
               Success := Is_Type (Goal, Frame_Ptr, Lex.Var);     -- if
                                                                  --instantiate
                                                                  --d variable
            when P_Length =>              --elsif Head = P_LENGTH then
                                          ----
               Success := Length (Goal, Frame_Ptr);
            when P_Arg =>                 --elsif Head = P_ARG then
                                          ----
               Success := Arg (Goal, Frame_Ptr);
            when P_Write =>               --elsif Head = P_WRITE then
                                          ----
               -- Writing_Fact := True;
               Token_Io.Print_Driver
                 (Token_Io.Aux_Display,
                  Lex.Cadr (Goal),
                  Frame_Ptr);
               Token_Io.New_Line (Token_Io.Aux_Display);
               Success := True;
            when P_Listing =>             --elsif Head = P_LISTING then
                                          ----
               Listing (Goal, Frame_Ptr);
               Success := True;
            when P_Atom =>                --elsif Head = P_ATOM then
                                          ----
               Success := Is_Type (Goal, Frame_Ptr, Lex.Sym);
            when P_Integer =>             --elsif Head = P_INTEGER then
                                          ----
               Success := Is_Type (Goal, Frame_Ptr, Lex.Int);
            when P_Float =>               --elsif Head = P_FLOAT then
                                          ----
               Success := Is_Type (Goal, Frame_Ptr, Lex.Flt);
            when P_Concat =>              --elsif Head = P_CONCAT then
                                          ----
               Success := Concat (Goal, Frame_Ptr);
            when P_Read =>                --elsif Head = P_READ then
                                          ----
               Success := Read (Goal, Frame_Ptr);
            when P_Display =>             --elsif Head = P_DISPLAY then
                                          ----
               Con_Io.Put (Get_String (Goal, Frame_Ptr));
               Success := True;
            when P_Onlyone =>             --elsif Head = P_ONLYONE then
                                          ----
               Con_Io.Put (">");
               Ver.Only_One := True;
               Success      := True;
            when P_Multiple =>            --elsif Head = P_MULTIPLE then
                                          ----
               Con_Io.Put ("-");
               Ver.Only_One := False;
               Success      := False;
            when P_Load =>                --elsif Head = P_LOAD then
                                          ----
               Success := Load (Get_String (Goal, Frame_Ptr));
            when P_Equal | P_Unif =>      --elsif Head = P_EQUAL then
                                          ----
               Success := Same (Goal, Frame_Ptr);
            when P_Nequal =>                 --elsif Head = P_NEQUAL then
                                             ----
               Success := Not_Same (Goal, Frame_Ptr);
            when P_Gc =>                  --elsif Head = P_GC then
                                          ----
               Ll.Set_Collect;
               Success := True;
            when P_Save =>                --elsif Head = P_SAVE then
                                          ----
               Success := Save_File (Goal, Frame_Ptr);
            when P_Tell =>                --elsif Head = P_TELL then
                                          ----
               Success := Tell (Get_String (Goal, Frame_Ptr));
            when P_Told =>                --elsif Head = P_TOLD then
                                          ----
               Success := Told;
            when P_System =>                 --elsif Head = P_SAVE then
                                             ----
               Success :=
                  Con_Io.Execute
                    (Get_String (Goal, Frame_Ptr),
                     Post => False);
            when P_Nl =>                  --elsif Head = P_NL then
                                          ----
               if Telling then
                  Text_IO.New_Line (Tell_File);
               else
                  Con_Io.New_Line;
               end if;
               Success := True;
            when P_Tab =>                 --elsif Head = P_TAB then
                                          ----
               Success := Tabs (Goal, Frame_Ptr);
            when P_Print =>               --elsif Head = P_PRINT then
                                          ----
               Success := Print (Goal, Frame_Ptr);
            when P_Dde =>                 --elsif Head = P_DDE then
                                          ----
               Success := Read (Goal, Frame_Ptr, Dde_On => True);
            when P_Post =>                --elsif Head = P_POST then
                                          ----
               Success :=
                  Con_Io.Execute (Get_String (Goal, Frame_Ptr), Post => True);
            when P_True =>                --elsif Head = P_TRUE then
                                          ----
               Success := True;
            when P_See =>                 --elsif Head = P_SEE then
                                          ----
               Success := See (Get_String (Goal, Frame_Ptr));
            when P_Seen =>                --elsif Head = P_SEEN then
                                          ----
               Success := Seen;
            when P_Or | P_Ifthen | P_Call =>
               return Interpret;
            when others =>                --else
                                          ----
               -- This function has not been implemented.
               -- Use Is_Builtin prior to calling Evaluate_Builtin
               raise Rule_Errors.Builtin_Error;

            end case;                     --end if;
                                          ----

            if Success then
               return Succeeded;
            else
               return Failed;
            end if;

         end Evaluate_Builtin;

         -- **********************************
         -- *                                *
         -- *   Initialize_Bips              *  BODY
         -- *                                *
         -- **********************************
         procedure Initialize_Bips
           (In_Toks : in Lex.Token_Range;
            Hash    : in Lex.Symbol_Hash_Table_Range)
         is
         begin
            -- Aug 28, 1993 added
            -- Points to free position in Predicate_Table.                  --
            --ISO Prolog conventions(*)
            Predicate_Table (P_Is)       := Lex.Make_Symbol ("is");
            Predicate_Table (P_Not)      := Lex.Make_Symbol ("not");
            Predicate_Table (P_Ifthen)   := Lex.Make_Symbol ("->");
            Predicate_Table (P_Uminus)   := Lex.Make_Symbol ("-");
            Predicate_Table (P_Bminus)   := Lex.Make_Symbol ("-");
            Predicate_Table (P_Exp)      := Lex.Make_Symbol ("**");
            Predicate_Table (P_Mult)     := Lex.Make_Symbol ("*");
            Predicate_Table (P_Plus)     := Lex.Make_Symbol ("+");
            Predicate_Table (P_Lt)       := Lex.Make_Symbol ("<");
            Predicate_Table (P_Gt)       := Lex.Make_Symbol (">");
            Predicate_Table (P_Div)      := Lex.Make_Symbol ("/");
            Predicate_Table (P_Ne)       := Lex.Make_Symbol ("\=="); -- switche
                                                                     --d from
                                                                     --/=, /==
                                                                     --(*)
            Predicate_Table (P_Le)       := Lex.Make_Symbol ("=<");  -- switche
                                                                     --d from
                                                                     --<=
                                                                     --(*)
            Predicate_Table (P_Ge)       := Lex.Make_Symbol (">=");
            Predicate_Table (P_Sequal)   := Lex.Make_Symbol ("==");  -- switche
                                                                     --d from =
            Predicate_Table (P_Period)   := Lex.Make_Symbol (".");
            Predicate_Table (P_Comma)    := Lex.Make_Symbol (",");
            Predicate_Table (P_If)       := Lex.Make_Symbol (":-");
            Predicate_Table (P_Query)    := Lex.Make_Symbol ("?");
            Predicate_Table (P_Ldot)     := Lex.Make_Symbol ("|");
            Predicate_Table (P_Lrb)      := Lex.Make_Symbol ("(");
            Predicate_Table (P_Rrb)      := Lex.Make_Symbol (")");
            Predicate_Table (P_Lsqb)     := Lex.Make_Symbol ("[");
            Predicate_Table (P_Rsqb)     := Lex.Make_Symbol ("]");
            Predicate_Table (P_Cut)      := Lex.Make_Symbol ("!");
            Predicate_Table (P_Findall)  := Lex.Make_Symbol ("findall");
            Predicate_Table (P_Assert)   := Lex.Make_Symbol ("assert");
            Predicate_Table (P_Retract)  := Lex.Make_Symbol ("retract");
            Predicate_Table (P_Fail)     := Lex.Make_Symbol ("fail");
            Predicate_Table (P_Asserta)  := Lex.Make_Symbol ("asserta");
            Predicate_Table (P_Trace)    := Lex.Make_Symbol ("trace");
            Predicate_Table (P_Var)      := Lex.Make_Symbol ("var");
            Predicate_Table (P_Length)   := Lex.Make_Symbol ("length");
            Predicate_Table (P_Write)    := Lex.Make_Symbol ("write");
            Predicate_Table (P_Listing)  := Lex.Make_Symbol ("listing");
            Predicate_Table (P_Atom)     := Lex.Make_Symbol ("atom");
            Predicate_Table (P_Integer)  := Lex.Make_Symbol ("integer");
            Predicate_Table (P_Float)    := Lex.Make_Symbol ("float");
            Predicate_Table (P_Mod)      := Lex.Make_Symbol ("mod");
            Predicate_Table (P_Arg)      := Lex.Make_Symbol ("arg");
            Predicate_Table (P_Concat)   := Lex.Make_Symbol ("concat");
            Predicate_Table (P_Gc)       := Lex.Make_Symbol ("gc");
            Predicate_Table (P_Idiv)     := Lex.Make_Symbol ("//");  -- switche
                                                                     --d from
                                                                     --div (*)
            Predicate_Table (P_Read)     := Lex.Make_Symbol ("read");
            Predicate_Table (P_Display)  := Lex.Make_Symbol ("display");
            Predicate_Table (P_Onlyone)  := Lex.Make_Symbol ("only_one");
            Predicate_Table (P_Load)     := Lex.Make_Symbol ("consult");
            -- switched from load
            Predicate_Table (P_Equal)    := Lex.Make_Symbol ("=");
            Predicate_Table (P_Nequal)   := Lex.Make_Symbol ("\=");  -- switche
                                                                     --d from
                                                                     --/=  (*)
            Predicate_Table (P_Or)       := Lex.Make_Symbol (";");
            Predicate_Table (P_Save)     := Lex.Make_Symbol ("save");
            Predicate_Table (P_Nl)       := Lex.Make_Symbol ("nl");
            Predicate_Table (P_Multiple) := Lex.Make_Symbol ("multiple");
            Predicate_Table (P_System)   := Lex.Make_Symbol ("system");
            Predicate_Table (P_Tell)     := Lex.Make_Symbol ("tell");
            Predicate_Table (P_Told)     := Lex.Make_Symbol ("told");
            Predicate_Table (P_Tab)      := Lex.Make_Symbol ("tab");
            Predicate_Table (P_Print)    := Lex.Make_Symbol ("prin");   -- swit
                                                                        --ched
                                                                        --from
                                                                        --print
            Predicate_Table (P_Dde)      := Lex.Make_Symbol ("dde");
            Predicate_Table (P_Post)     := Lex.Make_Symbol ("post");
            Predicate_Table (P_True)     := Lex.Make_Symbol ("true");
            Predicate_Table (P_Call)     := Lex.Make_Symbol ("call");
            Predicate_Table (P_Unif)     := Lex.Make_Symbol ("=..");
            Predicate_Table (P_See)      := Lex.Make_Symbol ("see");
            Predicate_Table (P_Seen)     := Lex.Make_Symbol ("seen");
            Predicate_Table (P_Eot)      := null;

            Lex.Initialize_Lex (In_Toks, Hash);

            L_Par := Lex.Make_Builtin (P_Lrb);
            R_Par := Lex.Make_Builtin (P_Rrb);

         end Initialize_Bips;

      end Builtin_Predicates;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Verify                       *  BODY
      -- *                                *
      -- **********************************
      package body Verify is

         --| Purpose
         --| Package body for Verify
         --|
         --| Exceptions
         --|
         --| Notes
         --| The programs in this file are driven by Query and Resolve.
         --| Query and then Resolve are called from interpret after
         --| checking whether the current clause is to be evaluated.
         --| Some of the routines are similar to the general CAR, CDR related
         --| routines in Linked_List.
         --| Unlike the management of lists in Linked_List, frame is a stack,
         --hence
         --| it does not implement garbage collection.
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions
         --| August 6, 1993    PP           Set_Frame_Cell updates UNIF for
         --speed

         --  package Int_Out is new Text_IO.Integer_IO ( INTEGER );

         package Bips renames Builtin_Predicates;
         package Ll renames Linked_List;
         package Unif renames Unification;

         Control_Depth : Control_Stack_Range;

         Tail_Recursion_Optimization : Boolean := False;

         Findall_Variable : Lex.Goal_Value;  -- Variable used by findall
                                             --builtin.

         Logical_Inferences : Rule_Errors.Count;

         --  There are two basic ways in which Prolog variable-value pairs are
         --  formed. These are structure copying and structure sharing. For
         --  interpreters structure sharing is usually better.
         type Frame_Cell is record
            Variable  : Lex.Goal_Value;   -- Variable which is to be given a
                                          --value.
            Value     : Lex.Goal_Value;   -- Value is in the context of a
                                          --frame reference.
            Reference : Frame_Range;
         end record;

         type Frame_Array is array (Frame_Range range <>) of Frame_Cell;
         type Frame_Access is access Frame_Array;   -- HEAP MODE
         Frame : Frame_Access;                      -- HEAP MODE

         Dummy : Boolean;

         Builtin_Mode : Bips.Builtin_Result;

         type Goal_Record is record
            Goal  : Lex.Goal_Value;
            Frame : Frame_Range;
         end record;

         type Goal_Array is array (Goal_Stack_Range range <>) of Goal_Record;
         type Goal_Access is access Goal_Array;

         Subgoals_Max : Goal_Stack_Range := Table_Sizes.Subgoals_Max;

         type Control is (Start_Or_End, Cut, Unified, Builtin_Succeeded);

         Nil : constant Lex.Goal_Value := Lex.Nil;

         -- A Control Stack controls program stack usage during recursion.

         Control_Stack_Ptr : Control_Stack_Range := Control_Stack_Range'First;

         type Control_Stack_Record is record
            Lead_Goal,                    -- leading goal in Goal_List
              Next_Clause,                   -- pointer to next clause for
                                             --Lead_Goal
              Clause                       : Lex.Goal_Value;      -- clause to
                                                                  --be applied
                                                                  --to
                                                                  --Lead_Goal
            Is_Rule                        : Boolean;             -- is clause
                                                                  --a fact or
                                                                  --rule ?
            Old_Frame_Ptr,                -- frame pointer for leading goal
              New_Frame_Ptr                : Frame_Range;   -- indicator of
                                                            --end of current
                                                            --frame
            Old_Unify_Ptr,                -- start of Lead_Goal's frame in
                                          --U_Stack
              New_Unify_Ptr                : Unif.Unification_Stack_Range;
            -- end of Lead_Goal's frame in U_Stack
            Start_Goals, Goal_Stack_Ptr, Save_Goal_Stack_Ptr :
              Goal_Stack_Range;
            -- save old stack position if fail.
            Recurse_Flag : Control;
         end record;

         type Control_Stack_Block is access Control_Stack_Record;

         type Control_Array is
           array (Control_Stack_Range range <>) of Control_Stack_Block;
         type Control_Access is access Control_Array;
         Control_Stack : Control_Access;

         Goal_Stack     : Goal_Access;
         Goal_Stack_Ptr : Goal_Stack_Range := Goal_Stack_Range'First;

         type Subgoals_List (Max_Subgoals : Goal_Stack_Range) is record
            Subgoals : Goal_Array (Goal_Stack_Range'First .. Max_Subgoals);
         end record;
         type Subgoal_Access is access Subgoals_List;

         ---------------- Tasking ------------------------
         -- Tasking is used if the Multiple builtin predicate is called.
         -- The task pauses after a successful resolution, to return the
         -- bound goals, then it will continue.
         -- Therefore, use the Only_One builtin predicate if tasking is
         -- to be avoided.

         task type Query_Task is
            -- pragma PRIORITY ( 10 );
            entry Go (Current_Clause : in Lex.Goal_Value);
            entry Result
              (This_Query : in Lex.Goal_Value;
               Solution   : in Lex.Goal_Value;
               At_Frame   : in Frame_Range);
            entry Get
              (This_Query : out Lex.Goal_Value;
               Solution   : out Lex.Goal_Value;
               At_Frame   : out Frame_Range);
         end Query_Task;
         type Query_Task_Access is access Query_Task;
         Queryer : Query_Task_Access;

         task type Run_Task is
            entry Start (Current_Clause : in Lex.Goal_Value);
         end Run_Task;
         type Run_Task_Access is access Run_Task;
         Runner : Run_Task_Access;

         Task_On      : Boolean := not Only_One;
         Is_Top_Level : Boolean := False;

         ---------------- End Tasking ------------------------

         procedure Free is new Unchecked_Deallocation (
            Name => Subgoal_Access,
            Object => Subgoals_List);

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_TRO                       *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Tro (On : in Boolean) is
         begin
            Tail_Recursion_Optimization := On;
         end Set_Tro;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Findall_Variable          *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Findall_Variable (Var : in Lex.Goal_Value) is
         begin
            Findall_Variable := Var;
         end Set_Findall_Variable;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Control_Depth             *  BODY
         -- *                                *
         -- **********************************
         function Get_Control_Depth return Table_Sizes.Integer_Ptr is
         begin
            return Table_Sizes.Integer_Ptr (Control_Depth);
         end Get_Control_Depth;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Number_of_Inferences          *  BODY
         -- *                                *
         -- **********************************
         function Number_Of_Inferences return Rule_Errors.Count is
         begin
            return Logical_Inferences;
         end Number_Of_Inferences;

         -- **********************************
         -- *                                *
         -- *   Set_Frame_Cell               *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Frame_Cell
           (Pointer          : in Frame_Range;
            Var_Arg, Val_Arg : in Lex.Goal_Value;
            Ref_Arg          : in Frame_Range)
         is
         begin
            Frame (Pointer) :=
              (Variable  => Var_Arg,
               Value     => Val_Arg,
               Reference => Ref_Arg);
            Unif.Set_Variable (Pointer, Var_Arg);
         end Set_Frame_Cell;

         -- **********************************
         -- *                                *
         -- *   Set_Frame_Variable           *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Set_Frame_Variable
           (Pointer : in Frame_Range;
            Value   : in Lex.Goal_Value)
         is
         begin
            Frame (Pointer).Variable := Value;
         end Set_Frame_Variable;

         -- **********************************
         -- *                                *
         -- *   Set_Frame_Value              *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Frame_Value
           (Pointer : in Frame_Range;
            Value   : in Lex.Goal_Value)
         is
         begin
            Frame (Pointer).Value := Value;
         end Set_Frame_Value;

         -- **********************************
         -- *                                *
         -- *   Set_Frame_Reference          *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Frame_Reference
           (Pointer, Ref_Value : in Frame_Range)
         is
         begin
            Frame (Pointer).Reference := Ref_Value;
         end Set_Frame_Reference;

         -- **********************************
         -- *                                *
         -- *   Frame_Variable               *  BODY
         -- *                                *
         -- **********************************
         function Frame_Variable
           (Pointer : in Frame_Range)
            return    Lex.Goal_Value
         is
         begin
            return (Frame (Pointer).Variable);
         end Frame_Variable;

         -- **********************************
         -- *                                *
         -- *   Frame_Value                  *  BODY
         -- *                                *
         -- **********************************
         function Frame_Value
           (Pointer : in Frame_Range)
            return    Lex.Goal_Value
         is
         begin
            return (Frame (Pointer).Value);
         end Frame_Value;

         -- **********************************
         -- *                                *
         -- *   Frame_Reference              *  BODY
         -- *                                *
         -- **********************************
         function Frame_Reference
           (Pointer : in Frame_Range)
            return    Frame_Range
         is
         begin
            return (Frame (Pointer).Reference);
         end Frame_Reference;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Get_Solutions                *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Get_Solutions
           (Multiple      : in Boolean;
            Query         : in Lex.Goal_Value;
            Frame_Ptr     : in Frame_Range;
            Solution_List : in out Lex.Goal_Value;
            Answer        : out Boolean)
         is

            --| Purpose
            --| Get_Solutions retrieves one or more solutions that have been
            --found
            --| through Resolve.
            --| Multiple determines whether to return TRUE or FALSE depending
            --on the
            --| type of answer which is desired.  This is controlled by its
            --setting in
            --| Query.  If a findall is detected, then the function is true,
            --otherwise
            --| it is as set in Query.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions
            --| July 6, 1993      PP           Added Update_Goals recursion

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Find_Solutions               *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Find_Solutions
              (List      : in Lex.Goal_Value;
               Frame_Ptr : in Frame_Range)
            is

               --| Purpose
               --| Add the value of the current variable(s) to the
               --Solution_List. Internal
               --| to Get_Solutions.
               --|
               --| Exceptions
               --|
               --| Notes
               --|
               --| Modifications
               --| October 25, 1991  Paul Pukite  Initial Version
               --| April 26, 1993    PP           Heap extensions

               Element, Value  : Lex.Goal_Value;
               Local_List      : Lex.Goal_Value := List;
               Local_Frame_Ptr : Frame_Range    := Frame_Ptr;

               function Update_Goal
                 (Goal      : in Lex.Goal_Value;
                  Frame_Ptr : in Frame_Range)
                  return      Lex.Goal_Value
               is
                  Copy_Front,                   -- copy of CAR of goal
                    Copy_Back           : Lex.Goal_Value;   -- copy of CDR of
                                                            --goal
                  New_Frame_Ptr         : Frame_Range := Frame_Ptr;
                  Return_Value          : Lex.Goal_Value;

               begin

                  if Lex.Is_List (Goal) then
                     -- Recurse over other elements of list.
                     Copy_Front   :=
                        Update_Goal (Lex.Car (Goal), New_Frame_Ptr);
                     Copy_Back    :=
                        Update_Goal (Lex.Cdr (Goal), New_Frame_Ptr);
                     Return_Value := Ll.Set_Car_Cdr (Copy_Front, Copy_Back);
                  else   -- Is an atomic or null goal.
                     if Lex.Is_Variable (Goal) then
                        -- Get values of variables.
                        Unif.Lookup (Goal, New_Frame_Ptr, Return_Value);
                        if Lex.Is_List (Return_Value) then
                           Return_Value :=
                              Update_Goal (Return_Value, New_Frame_Ptr);
                        end if;
                     else
                        Return_Value := Goal;
                     end if;

                  end if;

                  return (Return_Value);

               end Update_Goal;

            begin
               while Lex.Is_Goal (Local_List) loop
                  Element    := Lex.Car (Local_List);
                  Local_List := Lex.Cdr (Local_List);
                  if Lex.Is_List (Element) then
                     Find_Solutions (Element, Local_Frame_Ptr);
                  elsif Lex.Same (Element, Findall_Variable) then
                     Value := Update_Goal (Element, Local_Frame_Ptr);
                     if Lex.Is_Nil (Solution_List) then
                        Solution_List :=
                           Ll.Set_Car_Cdr (Value, Solution_List);
                     else
                        Ll.Construct (Solution_List, Value);
                     end if;
                     return;
                  end if;
               end loop;
            end Find_Solutions;

         begin -- Get_Solutions

            if not Multiple then
               Solution_List := Lex.Wild_Card;
               Answer        := True;
            else
               Find_Solutions (Query, Frame_Ptr);
               Answer := False;
            end if;

         end Get_Solutions;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Get_Next_Clause              *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Get_Next_Clause
           (Pid         : in Lex.Goal_Value;
            Is_Rule     : in out Boolean;
            Next_Clause : in out Lex.Goal_Value;
            Clause      : out Lex.Goal_Value)
         is

            --| Purpose
            --| Get_Next_Clause retrieves an alternate clause that could be
            --unified
            --| during the resolution process. It uses the information stored
            --| in the table Clause_List and PID.  It starts with Next_Clause
            --= 0.
            --| On later calls, Next_Clause is updated to the next position
            --| within Clause_List.  When this position in Clause_List
            --contains a 0
            --| indicating no more clauses, Get_Next_Clause returns a NIL to
            --Clause.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| November 9, 1991  PP           Shortened Is_Rule
            --| April 26, 1993    PP           Heap extensions

            Clauses, Local_Clause : Lex.Goal_Value;
            function "=" (L, R : Lex.Goal_Value) return Boolean renames
              Lex. "=";
         begin

            if Next_Clause = Ll.Clause_List then
               -- Try to get the first clause for PID,

               Clauses :=
                 (Lex.Cdr
                     (Ll.Associated_List (Lex.Cdr (Ll.Clause_List), Pid)));
            else
               Clauses := Next_Clause;
               -- get list of rest of clauses otherwise.

            end if;

            if not Lex.Is_List (Clauses) then
               -- If there are no more clauses for this PID, then return NIL.

               Clause := Nil;

            else
               Next_Clause := Lex.Cdr (Clauses);
               -- Set Next_Clause to point to next clause,

               Local_Clause := Lex.Car (Clauses);
               -- but return the current clause.
               Clause := Local_Clause;

               -- Info on type of clause.
               Is_Rule :=
                  Lex.Is_Builtin_Token (Lex.Car (Local_Clause), Bips.P_If);
            end if;
         end Get_Next_Clause;

         -- **********************************
         -- *                                *
         -- *   Get_Next_Frame               *  BODY
         -- *                                *
         -- **********************************
         function Get_Next_Frame return Frame_Range is
         begin

            if Next_Frame >= Frame'Last then
               raise Rule_Errors.Frame_Error;
            end if;

            return (Next_Frame + 1);

         end Get_Next_Frame;

         -- **********************************
         -- *                                *
         -- *   Copy_Clause                  *  BODY
         -- *                                *
         -- **********************************
         function Copy_Clause
           (New_Frame_Ptr : in Frame_Range;
            Clause        : in Lex.Goal_Value)
            return          Boolean
         is
            Variable     : Lex.Goal_Value;
            Local_Clause : Lex.Goal_Value := Clause;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Copy_All_Vars                *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Copy_All_Vars is

               --| Purpose
               --| Copy all variables in a clause at once to frame area.  This
               --is internal
               --| to Copy_Clause.
               --|
               --| Exceptions
               --|
               --| Notes
               --|
               --| Modifications
               --| October 25, 1991  Paul Pukite  Initial Version
               --| April 26, 1993    PP           Heap extensions

               Var, Next_Variable : Lex.Goal_Value;
            begin
               Next_Variable := Variable;
               Var           := Variable;
               loop
                  Var           := Next_Variable;
                  Next_Variable := Lex.Get_Prev_Var (Next_Variable);
                  exit when Lex.Is_Nil (Next_Variable);
               end loop;

               loop
                  Next_Frame := Get_Next_Frame;
                  Set_Frame_Cell (Next_Frame, Var, Var, New_Frame_Ptr);
                  Var := Lex.Get_Next_Var (Var);
                  exit when Lex.Is_Nil (Var);
               end loop;

            end Copy_All_Vars;

         begin

            while Lex.Is_Goal (Local_Clause) loop
               Variable     := Lex.Car (Local_Clause);
               Local_Clause := Lex.Cdr (Local_Clause);
               if Lex.Is_List (Variable)
                 and then Copy_Clause (New_Frame_Ptr, Variable)
               then
                  return (True);
               end if;
               if Lex.Is_Variable (Variable) then
                  Copy_All_Vars;
                  return (True);
               end if;
            end loop;
            return (False);

         end Copy_Clause;

         -- **********************************
         -- *                                *
         -- *   Query                        *  BODY
         -- *                                *
         -- **********************************
         procedure Query
           (Current_Clause : in Lex.Goal_Value;
            This_Query     : out Lex.Goal_Value;
            Solution       : out Lex.Goal_Value;
            At_Frame       : out Frame_Range)
         is

            --| Notes
            --| Query calls the main evaluation routine Resolve.  After the
            --truth
            --| of Resolve is determined, Query returns the solution
            --parameters.

            Start_Frame : Frame_Range;
            -- Pointer to the start of frames.

            This : Lex.Goal_Value;

         begin

            -- Initialize calls to start resolve and calls to Unify.
            Logical_Inferences := Unif.Unification_Attempts (Reset => True);

            This := Lex.Cadr (Current_Clause);
            -- Get the clause corresponding to the '?'.

            Start_Frame := Frame_Range'First + 1;
            -- This can be changed if some of the bindings of
            -- a former evaluation are needed.

            Unif.Set_Unify_Ptr (Unif.Unification_Stack_Range'First);
            Next_Frame := Frame_Range'First;
            -- Global variable points to next frame,
            -- push This and the frame pointer into goal stack.

            Dummy := Copy_Clause (Start_Frame, This);
            -- Create space for all local variables in the first goal.

            Control_Depth := Control_Stack_Range'First;

            Control_Stack_Ptr := Control_Stack_Range'First;

            Goal_Stack_Ptr := Goal_Stack_Range'First;

            -- Perform the evaluation.

            Solution :=
               Resolve
                 (A_Query        => This,
                  Frame_Ptr      => Start_Frame,
                  Multiple_Goals => False);

            Goal_Stack_Ptr := Goal_Stack_Range'First;
            This_Query     := This;
            At_Frame       := Start_Frame;

         end Query;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Clear_Frame                  *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Clear_Frame
           (Old_Unify_Ptr, New_Unify_Ptr : in Unif.Unification_Stack_Range)
         is

            --| Purpose
            --| Clearing the frame resets the variables belonging to the
            --| current goal in Resolve.  The unification stack holds
            --| between Old_Unify_Ptr and New_Unify_Ptr all the I such that
            --| Frame(I).CDRP should be reset.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Frame_Binding : Frame_Range;
            Goal_Binding  : Lex.Goal_Value;
            Temp_Frame    : Frame_Range;
            function "+"
              (L, R : Unif.Unification_Stack_Range)
               return Unif.Unification_Stack_Range renames Unif. "+";
         begin

            for I in  Old_Unify_Ptr + 1 .. New_Unify_Ptr loop

               Frame_Binding := Unif.Get_Unify_From (I);
               -- Check the unification stack to find
               -- bindings caused by the now failed unification.

               Goal_Binding := Frame_Variable (Frame_Binding);

               Temp_Frame := Unif.Get_Unify_To (I);

               if not Lex.Is_Variable (Goal_Binding) then
                  -- Overwriting deduction variable value area.
                  raise Rule_Errors.Variable_Overwrite_Error;
               end if;

               Set_Frame_Value (Frame_Binding, Goal_Binding);
               -- Reset the value of this variable to an uninitialized value.

               Set_Frame_Reference (Frame_Binding, Temp_Frame);
               -- Reset the frame pointer as well.
               -- Unify_Ptr is reset elsewhere.

            end loop;

         end Clear_Frame;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Restore_Frame                *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Restore_Frame (New_Frame_Ptr : in Frame_Range) is

         --| Purpose
         --| Restore the newly created frame to NIL so that it can be reused.
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         begin

            for I in  New_Frame_Ptr .. Next_Frame loop
               -- Clear all of the frame locations between the two frame
               --pointers.

               Set_Frame_Cell
                 (Pointer => I,
                  Var_Arg => Nil,
                  Val_Arg => Nil,
                  Ref_Arg => Frame_Range'First);

            end loop;

            Next_Frame := New_Frame_Ptr - 1;
            -- Update the global variable which points to next available frame.

         end Restore_Frame;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print_Stack                  *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Print_Stack
           (Pos : in Control_Stack_Range := Control_Stack_Ptr)
         is

         --| Purpose
         --| Print_Stack prints the control (environment) stack to display.
         --|
         --| Exceptions (none)
         --| Notes
         --| Only for debugging.
         --|
         --| Modifications
         --| September 8, 1991  Paul Pukite   Initial Version

         --     C : Control_Stack_Record := Control_Stack ( Pos );

         begin
            --     if Pos = Control_Stack_Range'FIRST then
            --        Text_IO.Put_Line -- CutRef
            --        ("CSP Goal NxCl Cls OldF NewF OdU NwU Strt GS SGS R F
            --Goal");
            --     end if;
            --     Int_Out.Put ( INTEGER ( Pos ), Width => 4 );
            --     Int_Out.Put ( INTEGER ( C.Lead_Goal ), Width => 5 );
            --     Int_Out.Put ( INTEGER ( C.Next_Clause ), Width => 5 );
            --     Int_Out.Put ( INTEGER ( C.Clause ), Width => 5 );
            --     Int_Out.Put ( INTEGER ( C.Old_Frame_Ptr ), Width => 5 );
            --     Int_Out.Put ( INTEGER ( C.New_Frame_Ptr ), Width => 5 );
            --     Int_Out.Put ( INTEGER ( C.Old_Unify_Ptr ), Width => 4 );
            --     Int_Out.Put ( INTEGER ( C.New_Unify_Ptr ), Width => 4 );
            --     Int_Out.Put ( INTEGER ( C.Start_Goals ), Width => 4 );
            --     Int_Out.Put ( INTEGER ( C.Goal_Stack_Ptr ), Width => 3 );
            --     Int_Out.Put ( INTEGER ( C.Save_Goal_Stack_Ptr ), Width => 3
            --);
            --     if C.Is_Rule then Text_IO.Put ( " T" ); else  Text_IO.Put (
            --" F" ); end if;
            --     Text_IO.Put ( " " & Control'IMAGE ( C.Recurse_Flag )(1..3)
            --& " " );
            --     if LEX.Is_List ( C.Lead_Goal ) then
            --        Token_IO.Print_Token ( Token_IO.Aux_Display,
            --LEX.CAR(C.Lead_Goal), Frame_Range'FIRST );
            --     end if;
            --     Text_IO.New_Line;
            null;
         end Print_Stack;

         pragma Page;

         -- **********************************
         -- *                                *
         -- *   Resolve                      *  BODY
         -- *                                *
         -- **********************************
         function Resolve
           (A_Query        : in Lex.Goal_Value;
            Frame_Ptr      : in Frame_Range;
            Multiple_Goals : in Boolean)
            return           Lex.Goal_Value
         is

            --| Notes
            --| The following procedure does the main Prolog deduction.  It is
            --called
            --| with a list of relations, or 'goals' to be solved.  It picks
            --off the
            --| first such relation and solves it using the the resolution
            --technique.
            --| After solving the first relation, the result is used in
            --calling the
            --| same deduction procedure on the rest of the relations to be
            --solved.
            --| Trace is used to do rudimentary deugging.

            Proved    : Boolean        := False;
            Solution  : Lex.Goal_Value := Nil;
            Top_Level : Boolean        := False;

            Cs : Control_Stack_Record;
            Gs : Subgoal_Access;
            -- Be wary of exceptions at this point, MIGHT not release memory

            -- **********************************
            -- *                                *
            -- *   Print_Goals                  *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Print_Goals is
            begin
               if Cs.Goal_Stack_Ptr = Goal_Stack_Range'First then
                  return;
               end if;
               for I in  Goal_Stack_Range'First .. Cs.Goal_Stack_Ptr - 1 loop
                  if Lex.Is_List (Gs.Subgoals (I).Goal) then
                     Token_Io.Print_Token
                       (Token_Io.Aux_Display,
                        Lex.Car (Gs.Subgoals (I).Goal),
                        Frame_Range'First);
                  else
                     Token_Io.Print_Token
                       (Token_Io.Aux_Display,
                        Gs.Subgoals (I).Goal,
                        Frame_Range'First);
                  end if;
               end loop;
            exception
               when others =>
                  Token_Io.New_Line (Token_Io.Aux_Display);
            end Print_Goals;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Clear_and_Restore            *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Clear_And_Restore is

            --| Purpose
            --| Clear_and_Restore clears the frame and then restores.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            begin
               Clear_Frame (Cs.Old_Unify_Ptr, Cs.New_Unify_Ptr);
               Restore_Frame (Cs.New_Frame_Ptr);
               Unif.Set_Unify_Ptr (Cs.Old_Unify_Ptr);
            end Clear_And_Restore;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Increment_Goal_Stack         *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Increment_Goal_Stack is

            --| Purpose
            --| Increment_Goal_Stack makes the next goal in the Goal_Stack
            --available.
            --| Internal to Resolve.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            begin
               if Cs.Goal_Stack_Ptr = Subgoals_Max then
                  raise Rule_Errors.Goal_Stack_Error;
               end if;
               Cs.Goal_Stack_Ptr := Cs.Goal_Stack_Ptr + 1;
            end Increment_Goal_Stack;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Push_Goals                   *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Push_Goals
              (Goals          : in Lex.Goal_Value;
               Goal_Frame_Ptr : in Frame_Range)
            is
            --| Purpose
            --| Push the goals in Goals onto top of Goal_Stack along with the
            --frame
            --| pointer.  Push the first goal in list after pushing in the
            --rest.
            --| Internal to Resolve.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version

            begin
               if Lex.Is_Nil (Goals) then
                  return;
               end if;
               -- This reverses the order at the same time.

               Push_Goals (Lex.Cdr (Goals), Goal_Frame_Ptr);
               Gs.Subgoals (Cs.Goal_Stack_Ptr) :=
                 (Lex.Car (Goals),
                  Goal_Frame_Ptr);
               Increment_Goal_Stack;

            end Push_Goals;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Check_Cut_and_TRO            *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Check_Cut_And_Tro is

               --| Purpose
               --| Check for and do Tail Recursion Optimization and Cut
               --Optimization
               --| if necessary. Internal to Resolve.
               --|
               --| Exceptions
               --|
               --| Notes
               --|
               --| Modifications
               --| October 25, 1991  Paul Pukite  Initial Version
               --| April 26, 1993    PP           Heap extensions

               I : Control_Stack_Range := Control_Stack_Ptr;

               -- **********************************
               -- *                                *
               -- *   Do_Cut                       *  SPEC & BODY
               -- *                                *
               -- **********************************
               procedure Do_Cut is
               begin
                  I := I - 1;  -- clause before the cut
                  loop
                     if I = Control_Stack_Range'First or
                        (Control_Stack (I).Old_Frame_Ptr < Cs.Old_Frame_Ptr and
                         Control_Stack (I).New_Frame_Ptr <= Cs.Old_Frame_Ptr)
                     then
                        -- Start of clause
                        if Control_Stack (I).New_Frame_Ptr <
                           Cs.Old_Frame_Ptr
                        then
                           I := I + 1; -- in case undershoots because of TRO
                        end if;
                        exit;
                     end if;
                     I := I - 1;
                  end loop;
                  Control_Stack (I).Recurse_Flag  := Cut;
                  Control_Stack (I).New_Unify_Ptr := Unif.Get_Unify_Ptr;
                  Control_Stack_Ptr               := I;
                  Token_Io.Trace
                    ("OPTC",
                     Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                     Cs.Lead_Goal,
                     Cs.Old_Frame_Ptr);
               end Do_Cut;

               -- **********************************
               -- *                                *
               -- *   Do_TRO                       *  SPEC & BODY
               -- *                                *
               -- **********************************
               procedure Do_Tro is
               begin

                  loop
                     I := I - 1;

                     exit when I = Control_Stack_Range'First;

                     declare
                        Cstack : Control_Stack_Record renames Control_Stack (I)
.all;
                        function "=" (L, R : Lex.Goal_Value) return Boolean
                           renames Lex. "=";
                     begin
                        if Cstack.Lead_Goal = Cs.Lead_Goal
                          and then
                           -- Matches to a recursive call.
                           Cstack.Clause = Cs.Clause
                          and then
                           -- with same PID
                           Cstack.Save_Goal_Stack_Ptr =
                           Cs.Save_Goal_Stack_Ptr
                        then

                           if Cstack.Old_Frame_Ptr < Cs.Old_Frame_Ptr then
                              --if CStack.Old_Unify_Ptr = CStack.New_Unify_Ptr
                              --then
                              --   Do_More; -- more could be done here for
                              --optimizing frames but
                              --end if;     -- it gets more complex and occurs
                              --rarely
                              Token_Io.Trace
                                ("TAIL",
                                 Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                                 Cs.Lead_Goal,
                                 Cs.Old_Frame_Ptr);
                              Control_Stack_Ptr := I;
                              exit;
                           end if;

                        elsif Lex.Is_Goal (Cstack.Next_Clause)
                          or else Cstack.Old_Frame_Ptr < Cs.Old_Frame_Ptr
                        then
                           -- Handles untried alternatives or
                           -- handles different context.
                           exit;
                        end if;
                     end;

                  end loop;

               end Do_Tro;

            begin  -- Check_Cut_and_TRO

               if Cs.Recurse_Flag = Cut then
                  Do_Cut;
               elsif Tail_Recursion_Optimization then
                  if Cs.Goal_Stack_Ptr /= Goal_Stack_Range'First
                    and then Lex.Is_Nil (Cs.Next_Clause)
                    and then Cs.Recurse_Flag = Unified
                  then
                     Do_Tro;
                  end if;
               end if;

            end Check_Cut_And_Tro;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Back_Track                   *  SPEC & BODY
            -- *                                *
            -- **********************************
            procedure Back_Track is

            --| Purpose
            --| Backtrack is used to return to a choice point.
            --| If a goal failed, then restore it to the stack to try
            --| backtracking.  Note that on a cut false, make no
            --| restoration of the goal.  Internal procedure to Resolve.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            begin
               Gs.Subgoals (Cs.Goal_Stack_Ptr) :=
                 (Cs.Lead_Goal,
                  Cs.Old_Frame_Ptr);
               Increment_Goal_Stack;
            end Back_Track;

            --X1804: CSU
            -- **********************************
            -- *                                *
            -- *   Try_Clauses                  *  SPEC & BODY
            -- *                                *
            -- **********************************
            function Try_Clauses return Boolean is

               --| Purpose
               --| Try_Clauses attempts to unify any of the clauses associated
               --| with a Lead_Goal.  Internal procedure to Resolve.
               --|
               --| Exceptions
               --|
               --| Notes
               --|
               --| Modifications
               --| October 25, 1991  Paul Pukite  Initial Version

               Clause_Head, Subgoal_List, Pid, Args : Lex.Goal_Value;

            begin

               if Lex.Is_Atomic (Cs.Lead_Goal) then
                  Pid  := Cs.Lead_Goal;
                  Args := Nil;
               else
                  Pid  := Lex.Car (Cs.Lead_Goal);
                  Args := Lex.Cdr (Cs.Lead_Goal);
                  if Lex.Is_Variable (Pid) then
                     Unif.Lookup
                       (Argument     => Pid,
                        Frame_Ptr    => Cs.Old_Frame_Ptr,
                        Return_Value => Pid);
                  end if;
               end if;

               loop

                  Get_Next_Clause
                    (Pid         => Pid,
                     Is_Rule     => Cs.Is_Rule,
                     Next_Clause => Cs.Next_Clause,
                     Clause      => Cs.Clause);

                  exit when not Lex.Is_Goal (Cs.Clause);

                  Cs.New_Frame_Ptr := Get_Next_Frame;
                  Dummy            :=
                     Copy_Clause
                       (New_Frame_Ptr => Cs.New_Frame_Ptr,
                        Clause        => Cs.Clause);
                  if Cs.Is_Rule then
                     Clause_Head  := Lex.Cadr (Cs.Clause);
                     Subgoal_List := Lex.Car (Lex.Cddr (Cs.Clause));
                  else
                     Clause_Head  := Cs.Clause;
                     Subgoal_List := Nil;
                  end if;

                  Cs.Old_Unify_Ptr       := Unif.Get_Unify_Ptr;
                  Cs.Save_Goal_Stack_Ptr := Cs.Goal_Stack_Ptr;

                  if Unif.Unify
                       (Source        => Args,
                        Target        => Lex.Cdr (Clause_Head),
                        Old_Frame_Ptr => Cs.Old_Frame_Ptr,
                        New_Frame_Ptr => Cs.New_Frame_Ptr)
                  then

                     Cs.New_Unify_Ptr := Unif.Get_Unify_Ptr;

                     Push_Goals
                       (Goals          => Subgoal_List,
                        Goal_Frame_Ptr => Cs.New_Frame_Ptr);

                     Cs.Recurse_Flag := Unified;

                     return (True);

                  end if;

                  Proved           := False;
                  Cs.New_Unify_Ptr := Unif.Get_Unify_Ptr;

                  Clear_And_Restore;

               end loop;

               Back_Track;

               return (False);

            end Try_Clauses;

            pragma Page;

         begin -- Verify

            if Is_Top_Level then
               Top_Level    := True;
               Is_Top_Level := False;
            end if;

            Cs :=
              (Lead_Goal           => Nil,
               Next_Clause         => Nil,
               Clause              => Nil,
               Is_Rule             => False,
               Old_Frame_Ptr       => Frame_Range'First,
               New_Frame_Ptr       => Frame_Range'First,
               Old_Unify_Ptr       => Unif.Unification_Stack_Range'First,
               New_Unify_Ptr       => Unif.Unification_Stack_Range'First,
               Start_Goals         => Goal_Stack_Ptr,
               Goal_Stack_Ptr      => Goal_Stack_Range'First,
               Save_Goal_Stack_Ptr => Goal_Stack_Range'First,
               Recurse_Flag        => Start_Or_End);

            Gs := new Subgoals_List (Subgoals_Max);
            --      GS.Subgoals := ( others => ( NIL, Frame_Range'FIRST ) );
            for I in  Gs.Subgoals'Range loop
               Gs.Subgoals (I) := (Nil, Frame_Range'First);
            end loop;

            Gs.Subgoals (Goal_Stack_Range'First) := (A_Query, Frame_Ptr);
            Increment_Goal_Stack;

            loop

               loop  -- Continue Resolve

                  Rule_Errors.Check_Condition
                    (Inferences   => Logical_Inferences,
                     Unifications => Unif.Unification_Attempts);
                  --GNAT delay (0.0);

                  if Control_Stack (Control_Stack_Ptr) = null then
                     Control_Stack (Control_Stack_Ptr) :=
                       new Control_Stack_Record;
                  end if;
                  Control_Stack (Control_Stack_Ptr).all := Cs;
                  if Goal_Stack_Ptr >=
                     Goal_Stack'Last - Cs.Goal_Stack_Ptr
                  then
                     raise Rule_Errors.Goal_Stack_Error;
                  end if;
                  Goal_Stack (
                     Goal_Stack_Ptr .. Goal_Stack_Ptr + Cs.Goal_Stack_Ptr) :=
                    Gs.Subgoals (Goal_Stack_Range'First .. Cs.Goal_Stack_Ptr);
                  Control_Stack (Control_Stack_Ptr).Start_Goals :=
                    Goal_Stack_Ptr;

                  if Control_Stack_Ptr = Control_Stack'Last then
                     raise Rule_Errors.Control_Stack_Error;
                  else
                     Print_Stack;
                     if Control_Stack_Ptr > Control_Stack_Range'First then
                        Check_Cut_And_Tro;
                     end if;
                     Goal_Stack_Ptr    :=
                       Control_Stack (Control_Stack_Ptr).Start_Goals +
                       Cs.Goal_Stack_Ptr;
                     Control_Stack_Ptr := Control_Stack_Ptr + 1;
                     if Control_Stack_Ptr > Control_Depth then
                        Control_Depth := Control_Stack_Ptr;
                     end if;
                  end if;

                  Logical_Inferences := Logical_Inferences + 1;

                  Cs.Recurse_Flag := Start_Or_End;
                  Cs.Lead_Goal    := Nil;
                  Proved          := False;

                  if Cs.Goal_Stack_Ptr = Goal_Stack_Range'First then
                     -- Doesn't get here on the first pass

                     Get_Solutions
                       (Multiple      => Multiple_Goals,
                        Query         => A_Query,
                        Frame_Ptr     => Frame_Ptr,
                        Solution_List => Solution,
                        Answer        => Proved);

                     if Proved then
                        Token_Io.Trace
                          ("*YES",
                           Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                           Cs.Lead_Goal,
                           Cs.Old_Frame_Ptr);
                        -- Goal has succeeded so leave this goal control frame.
                        if Task_On and Top_Level then
                           Queryer.Result (A_Query, Solution, Frame_Ptr);
                           Proved := False;
                           -- There are race conditions here if multiple
                           --solution is on
                           -- Allow the querying task to print out the
                           --solutions before
                           -- it starts backtracking to fill in the token_pos
                           --array
                           delay 0.01;
                           Back_Track;
                        end if;
                     else
                        Token_Io.Trace
                          ("*NO ",
                           Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                           Cs.Lead_Goal,
                           Cs.Old_Frame_Ptr);
                        -- Goal has failed so restore the goal stack to the
                        --previous
                        -- environment or control frame.
                        Back_Track;
                     end if;
                     exit;
                  end if;

                  Cs.Goal_Stack_Ptr := Cs.Goal_Stack_Ptr - 1;  -- Next goal in
                                                               --line

                  Cs.Lead_Goal     := Gs.Subgoals (Cs.Goal_Stack_Ptr).Goal;
                  Cs.Old_Frame_Ptr := Gs.Subgoals (Cs.Goal_Stack_Ptr).Frame;

                  if Lex.Is_Builtin_Token (Cs.Lead_Goal, Bips.P_Cut) then
                     Cs.Recurse_Flag := Cut;
                  else
                     if Lex.Is_Variable (Cs.Lead_Goal) then
                        -- Find the term for this variable.
                        Unif.Lookup
                          (Argument     => Cs.Lead_Goal,
                           Frame_Ptr    => Cs.Old_Frame_Ptr,
                           Return_Value => Cs.Lead_Goal);
                        exit when not (Lex.Is_Atomic (Cs.Lead_Goal) or
                                       Lex.Is_List (Cs.Lead_Goal) or
                                       Lex.Is_Builtin (Cs.Lead_Goal));
                     end if;
                     Token_Io.Trace
                       ("CALL",
                        Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                        Cs.Lead_Goal,
                        Cs.Old_Frame_Ptr);
                     -- Make a call to a goal designated by CS.Lead_Goal.

                     Cs.Old_Unify_Ptr := Unif.Get_Unify_Ptr;

                     if Lex.Is_Builtin (Lex.Car (Cs.Lead_Goal)) then
                        Builtin_Mode :=
                           Bips.Evaluate_Builtin
                             (Goal      => Cs.Lead_Goal,
                              Frame_Ptr => Cs.Old_Frame_Ptr);
                     else
                        Builtin_Mode := Bips.Interpret;
                     end if;
                     case Builtin_Mode is
                        when Bips.Succeeded =>
                           Cs.New_Unify_Ptr := Unif.Get_Unify_Ptr;
                           Cs.Recurse_Flag  := Builtin_Succeeded;
                        -- If the builtin goals succeeded then continue
                        -- with rest of goals.
                        when Bips.Failed =>
                           Cs.New_Unify_Ptr := Unif.Get_Unify_Ptr;

                           -- Clear off the bindings caused by a failure of a
                           --builtin.
                           Clear_Frame (Cs.Old_Unify_Ptr, Cs.New_Unify_Ptr);

                           Back_Track;  -- Go back to previous goal
                           exit;
                        when Bips.Interpret =>
                           Cs.New_Frame_Ptr := Get_Next_Frame;
                           Cs.Next_Clause   := Ll.Clause_List;

                           -- Try_Clauses calls the unification procedure and
                           -- indexes through the associated clauses.  If no
                           --clauses
                           -- are left, then exit the loop.

                           exit when not Try_Clauses;

                     end case; -- Builtin
                     Token_Io.Trace
                       ("EXIT",
                        Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                        Cs.Lead_Goal,
                        Cs.Old_Frame_Ptr);
                  end if; -- Cut

               end loop;

               --GNAT delay (0.0);

               loop   -- End Resolve Process

                  if Control_Stack_Ptr = Control_Stack_Range'First then
                     Cs.Recurse_Flag := Start_Or_End;
                  else
                     Control_Stack_Ptr := Control_Stack_Ptr - 1;
                     Cs                :=
                       Control_Stack (Control_Stack_Ptr).all;
                     Gs.Subgoals (Goal_Stack_Range'First .. Cs.Goal_Stack_Ptr)
                        :=
                       Goal_Stack (
                        Cs.Start_Goals .. Cs.Start_Goals + Cs.Goal_Stack_Ptr);
                     Goal_Stack_Ptr    := Cs.Start_Goals + Cs.Goal_Stack_Ptr;
                  end if;

                  case Cs.Recurse_Flag is

                     when Unified =>

                        if not Proved then
                           Token_Io.Trace
                             ("REDO",
                              Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                              Cs.Lead_Goal,
                              Cs.Old_Frame_Ptr);
                           Cs.Goal_Stack_Ptr := Cs.Save_Goal_Stack_Ptr;
                           Clear_And_Restore;
                           -- Redo an accociated clause after a failure.
                           -- Exit if no alternative (associated) clauses.
                           Cs.Recurse_Flag := Start_Or_End;

                           exit when Try_Clauses;

                        end if;

                     when Cut =>

                        if not Proved then
                           -- This is equivalent to ignoring the cut.
                           Cs.Goal_Stack_Ptr := Cs.Save_Goal_Stack_Ptr;
                           Clear_Frame (Cs.Old_Unify_Ptr, Cs.New_Unify_Ptr);
                        end if;

                     when Builtin_Succeeded =>

                        if not Proved then
                           -- Exit from a failed builtin
                           Clear_Frame (Cs.Old_Unify_Ptr, Cs.New_Unify_Ptr);
                           Back_Track;
                        end if;

                     when Start_Or_End =>
                        Token_Io.Trace
                          ("FINI",
                           Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                           Cs.Lead_Goal,
                           Cs.Old_Frame_Ptr);
                        -- End of resolution process.
                        Free (Gs);
                        return (Solution);

                  end case;
                  Token_Io.Trace
                    ("EXIT",
                     Table_Sizes.Integer_Ptr (Control_Stack_Ptr),
                     Cs.Lead_Goal,
                     Cs.Old_Frame_Ptr);
               end loop;

            end loop;

            -- exception
            --    when others =>
            --       Free ( GS );
            --       raise;

         end Resolve;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Initialize_Ver                *  BODY
         -- *                                *
         -- **********************************
         procedure Initialize_Ver
           (Frames   : in Frame_Range;
            Goals    : in Goal_Stack_Range;
            Subgoals : in Goal_Stack_Range;
            Control  : in Control_Stack_Range)
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Frame             :=
              new Frame_Array (Frame_Range'First .. Frames);
            Goal_Stack        :=
              new Goal_Array (Goal_Stack_Range'First .. Goals);
            Subgoals_Max      := Subgoals;
            Control_Stack     :=
              new Control_Array (Control_Stack_Range'First .. Control);
            Control_Stack.all := (others => null);
            Control_Stack.all := (Control_Stack.all'Range =>null);
         end Initialize_Ver;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Query_Task                    *  BODY
         -- *                                *
         -- **********************************
         task body Query_Task is

            --| Purpose
            --| Works with All_Query to wait for Runner to finish.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Task_Current_Clause : Lex.Goal_Value;
            Task_This_Query     : Lex.Goal_Value;
            Task_Solution       : Lex.Goal_Value := Nil;
            Task_At_Frame       : Frame_Range;
         begin
            loop
               select
                  accept Go (Current_Clause : in Lex.Goal_Value) do
                     Task_Current_Clause := Current_Clause;
                  end Go;
               or
                  terminate;
               end select;
               if Lex.Is_Nil (Task_Solution) then
                  Runner.Start (Task_Current_Clause);
               end if;
               accept Result (
                 This_Query  : in Lex.Goal_Value;
                  Solution   : in Lex.Goal_Value;
                  At_Frame   : in Frame_Range) do
                  Task_This_Query := This_Query;
                  Task_Solution   := Solution;
                  Task_At_Frame   := At_Frame;
               end Result;
               accept Get (
                 This_Query  : out Lex.Goal_Value;
                  Solution   : out Lex.Goal_Value;
                  At_Frame   : out Frame_Range) do
                  This_Query := Task_This_Query;
                  Solution   := Task_Solution;
                  At_Frame   := Task_At_Frame;
               end Get;
            end loop;
         end Query_Task;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Run_Task                      *  BODY
         -- *                                *
         -- **********************************
         task body Run_Task is

            --| Purpose
            --| Works with All_Query by sending a query on the Runner thread.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Task_Current_Clause : Lex.Goal_Value;
            This_Query          : Lex.Goal_Value;
            Solution            : Lex.Goal_Value;
            At_Frame            : Frame_Range;
         begin
            loop
               select
                  accept Start (Current_Clause : in Lex.Goal_Value) do
                     Task_Current_Clause := Current_Clause;
                  end Start;
               or
                  terminate;
               end select;
               Is_Top_Level := True;
               begin
                  Query
                    (Current_Clause => Task_Current_Clause,
                     This_Query     => This_Query,
                     Solution       => Solution,
                     At_Frame       => At_Frame);
               exception
                  when others =>
                     null;
               end;
               Queryer.Result (This_Query, Nil, At_Frame);
            end loop;
         end Run_Task;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  All_Query                     *  BODY
         -- *                                *
         -- **********************************
         procedure All_Query
           (Current_Clause : in Lex.Goal_Value;
            This_Query     : out Lex.Goal_Value;
            Solution       : out Lex.Goal_Value;
            At_Frame       : out Frame_Range)
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            Task_On := not Only_One;
            if Task_On then
               if Queryer = null then
                  Queryer := new Query_Task;
                  Runner  := new Run_Task;
               end if;
               Queryer.Go (Current_Clause => Current_Clause);
               Queryer.Get
                 (This_Query => This_Query,
                  Solution   => Solution,
                  At_Frame   => At_Frame);
            else
               Query
                 (Current_Clause => Current_Clause,
                  This_Query     => This_Query,
                  Solution       => Solution,
                  At_Frame       => At_Frame);
            end if;
         end All_Query;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Stop                          *  BODY
         -- *                                *
         -- **********************************
         procedure Stop is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            null;
            --APEX does not like abort -- abort Runner;
            --APEX does not like abort -- abort Queryer;
         end Stop;

      end Verify;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Token_IO                     *  BODY
      -- *                                *
      -- **********************************
      package body Token_Io is

         --| Purpose
         --| Package body for Token_IO
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions

         package Ll renames Linked_List;
         package Unif renames Unification;
         package Bips renames Builtin_Predicates;

         Output_File : Text_IO.File_Type;

         Pretty_Print     : Boolean := False;
         Start_Pp         : Boolean := False;
         Balance          : Integer := 0;
         Print_Long_Float : Boolean := False;
         Show_Error       : Boolean := False;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  FltStr                        *  BODY
         -- *                                *
         -- **********************************
         function Fltstr
           (Val   : in Lex.Calc_Flt;
            Short : in Boolean := True)
            return  String
         is

            --| Purpose
            --| See spec.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version

            Numstr : String (1 .. Lex.Calc_Flt'Base'Digits + 7);

         begin
            if Short then
               return S (Val);
            else
               Fio.Put (Numstr, Val);
               for I in  Numstr'Range loop
                  if Numstr (I) /= ' ' then
                     return Numstr (I .. Numstr'Last);
                  end if;
               end loop;
               return "";
            end if;
            --        -- if Short then
            --        --          Fio.Put (Numstr, Val, 1, 2);
            --        -- else
            --        Fio.Put (Numstr, Val, 6, 0);
            --        --end if;
            --        for I in Numstr'Range loop
            --       if Numstr (I) /= ' ' then
            --           return Numstr (I .. Numstr'Last);
            --       end if;
            --        end loop;
            --        return "";
         end Fltstr;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  IntStr                        *  BODY
         -- *                                *
         -- **********************************
         function Intstr (Val : in Lex.Calc_Int) return String is

            --| Purpose
            --| See spec.
            --|
            --| Exceptions (none)
            --| Notes
            --|
            --| Modifications
            --| April 26, 1993    Paul Pukite    Initial Version
            --| December 5, 1999

            -- Add space at the beginning
            Numstr : String (1 .. Lex.Calc_Int'Base'Width + 1);
         begin
            Iio.Put (Numstr, Val);
            for I in  Numstr'Range loop
               if Numstr (I) /= ' ' then
                  return Numstr (I .. Numstr'Last);
               end if;
            end loop;
            return "";
         end Intstr;

         -- **********************************
         -- *                                *
         -- *   Print_Statistics             *  BODY
         -- *                                *
         -- **********************************
         procedure Print_Statistics is
         begin
            -- return;  -- !!!! comment out return if procedure needed
            if Con_Io.Execute ("PRINT_STATISTICS") then
               Print (Aux_Display, "<links =");
               Print
                 (Aux_Display,
                  Rule_Errors.Count'Base'Image (Ll.Number_Of_Links));
               Print (Aux_Display, " frames =");
               Print
                 (Aux_Display,
                  Ver.Frame_Range'Base'Image (Ver.Next_Frame));
               Print (Aux_Display, " inferences =");
               Print
                 (Aux_Display,
                  Rule_Errors.Count'Base'Image (Ver.Number_Of_Inferences));
               Print (Aux_Display, " unifies =");
               Print
                 (Aux_Display,
                  Rule_Errors.Count'Base'Image (Unif.Unification_Attempts));
               Print (Aux_Display, " stack =");
               Print
                 (Aux_Display,
                  Table_Sizes.Integer_Ptr'Base'Image (Ver.Get_Control_Depth) &
                  ">");
               New_Line (Aux_Display);
               Print (Aux_Display, "<symbs =");
               Print
                 (Aux_Display,
                  Rule_Errors.Count'Base'Image (Lex.Number_Of_Symbols));
               Print (Aux_Display, " goals =");
               Print
                 (Aux_Display,
                  Rule_Errors.Count'Base'Image (Lex.Number_Of_Goals) & ">");
               New_Line (Aux_Display);
            end if;
         end Print_Statistics;

         --X1804: CSU-- **********************************
         -- *                                *
         -- *   Print_Out                    *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Print_Out
           (Fp        : in Io_Flag;
            List      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
         is

            --| Purpose
            --| Print_Out determines atomic tokens or lists for printing.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            First, Rest : Lex.Goal_Value;
         begin
            if Lex.Is_Token (List) then
               -- Check first whether a simple token or some similar item is
               -- to be printed; if so, print and exit.
               Print_Token (Fp, List, Frame_Ptr);
               return;
            end if;

            if Lex.Is_Nil (List) then
               Print (Fp, ')');
               -- Matching '(' supplied by earlier Print_Out or Print_Goals.
               return;
            end if;

            First := Lex.Car (List);
            -- Recursively consider sublists.

            Rest := Lex.Cdr (List);
            if Lex.Is_Token (First) then
               -- Routine to print symbols.
               Print_Token (Fp, First, Frame_Ptr);
            else
               Print (Fp, '(');
               Print_Out (Fp, First, Frame_Ptr);
            end if;

            Print_Out (Fp, Rest, Frame_Ptr);
            -- Rest should be always list ( >= 0 )

         end Print_Out;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print_Goals                  *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Print_Goals
           (Fp        : in Io_Flag;
            Item      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
         is
         begin

            if Lex.Is_Token (Item) then
               Print_Token (Fp, Item, Frame_Ptr);
            else
               Print (Fp, '(');
               Print_Out (Fp, Item, Frame_Ptr);
            end if;

         end Print_Goals;

         -- **********************************
         -- *                                *
         -- *   Print_Driver                 *  BODY
         -- *                                *
         -- **********************************
         procedure Print_Driver
           (Fp        : in Io_Flag;
            Item      : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
         is
         begin
            Pretty_Print := False;
            Start_Pp     := False;
            Balance      := 0;
            Print_Goals (Fp, Item, Frame_Ptr);
         end Print_Driver;

         -- **********************************
         -- *                                *
         -- *   Print_Variables              *  BODY
         -- *                                *
         -- **********************************
         procedure Print_Variables
           (Fp        : in Io_Flag;
            Arg       : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
         is
            --| Notes
            --| Print repeated values of variables.

            First, Rest     : Lex.Goal_Value;
            Local_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            function "=" (L, R : Ver.Frame_Range) return Boolean renames
              Ver. "=";
            function "+" (L, R : Lex.Token_Range) return Lex.Token_Range
               renames Lex. "+";
         begin

            if Lex.Is_Variable (Arg) then

               First := Arg;
               if Local_Frame_Ptr /= Ver.Frame_Range'First then
                  Unif.Lookup (Arg, Local_Frame_Ptr, First);
               end if;

               Print (Fp, "  ");
               Print_Token (Fp, Arg, Ver.Frame_Range'First);
               -- Print the variable name.
               Print (Fp, " := ");

               Print_Driver (Fp, First, Local_Frame_Ptr);
               -- Print value of variable.

               New_Line (Fp);

            elsif Lex.Is_List (Arg) then
               Rest  := Lex.Cdr (Arg);
               First := Lex.Car (Arg);
               Print_Variables (Fp, First, Local_Frame_Ptr);
               Print_Variables (Fp, Rest, Local_Frame_Ptr);
            end if;

         end Print_Variables;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Print_Symbol                 *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Print_Symbol
           (Fp    : in Io_Flag;
            Token : in Lex.Goal_Value)
         is

            --| Purpose
            --| Print_Symbol determines the type of atomic token for printing.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            procedure Print_Atom (Str : in String) is
            begin
               if not (Str (Str'First) in 'a' .. 'z') then
                  Print (Fp, '"' & Str & '"');
                  return;
               end if;
               for I in  Str'Range loop
                  if Str (I) = ' ' then
                     Print (Fp, '"' & Str & '"');
                     return;
                  end if;
               end loop;
               Print (Fp, Str);
            end Print_Atom;

         begin

            if Lex.Is_Integer (Token) then
               Print (Fp, Intstr (Lex.Get_Int (Token)));
            elsif Lex.Is_Float (Token) then
               if Print_Long_Float then
                  Print (Fp, Fltstr (Lex.Get_Flt (Token), Short => False));
               else
                  Print (Fp, Fltstr (Lex.Get_Flt (Token)));
               end if;
            elsif Lex.Is_Atomic (Token) then
               Print_Atom (Lex.Get_Sym (Token));
            elsif Lex.Is_Builtin (Token) then
               if Lex.Is_Builtin_Token (Token, Bips.P_If) then
                  Pretty_Print := True;
                  Start_Pp     := False;
                  Balance      := 1;
               end if;
               Print (Fp, Lex.Get_Sym (Token));
            elsif Lex.Is_Variable (Token) then
               Print (Fp, Lex.Get_Sym (Token));
            end if;

         end Print_Symbol;

         -- **********************************
         -- *                                *
         -- *   Print_Token                  *  BODY
         -- *                                *
         -- **********************************
         procedure Print_Token
           (Fp        : in Io_Flag;
            Token     : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
         is

            --| Notes
            --| Basic printing routine.
            --| Note that this prints a trailing space after each token.

            Value           : Lex.Goal_Value;
            Local_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            function ">" (L, R : Ver.Frame_Range) return Boolean renames
              Ver. ">";
         begin

            if Lex.Is_Nil (Token) then  -- ()
               return;
            end if;

            if Lex.Is_Variable (Token)
              and then Local_Frame_Ptr > Ver.Frame_Range'First
            then
               Unif.Lookup (Token, Local_Frame_Ptr, Value);
               if not Lex.Is_Variable (Value) then
                  Print_Goals (Fp, Value, Local_Frame_Ptr);
                  return;
               end if;
            end if;

            Print_Symbol (Fp, Token);
            Print (Fp, ' ');

         end Print_Token;

         -- **********************************
         -- *                                *
         -- *   Trace                        *  BODY
         -- *                                *
         -- **********************************
         procedure Trace
           (Str   : in Description;
            Level : in Table_Sizes.Integer_Ptr;
            Goal  : in Lex.Goal_Value;
            Frame : in Ver.Frame_Range)
         is
         begin

            if Bips.Is_Trace_On then
               Print
                 (Aux_Display,
                  "<" & Table_Sizes.Integer_Ptr'Base'Image (Level) & " ");
               Print (Aux_Display, Str & " > ");
               if Lex.Is_List (Goal) then
                  Print_Token (Aux_Display, Lex.Car (Goal), Frame);
                  New_Line (Aux_Display);
                  Print_Variables (Aux_Display, Lex.Cdr (Goal), Frame);
               else
                  Print_Token (Aux_Display, Goal, Frame);
                  New_Line (Aux_Display);
               end if;
            end if;
         exception
            when others =>
               Print (Aux_Display, "??????");
               New_Line (Aux_Display);

         end Trace;

         -- **********************************
         -- *                                *
         -- *   Print                        *  BODY
         -- *                                *
         -- **********************************
         procedure Print (Fp : in Io_Flag; Str : in String) is
         begin
            case (Fp) is
               when Error_Display =>
                  Show_Error := True;
                  Con_Io.Put_Line ("Exception: " & Str);
                  Con_Io.Put ("-----> At: ");
                  Print_Symbol
                    (Stream_Out,
                     Lex.Lex_Table (Lex.Token_Range'First));
                  Con_Io.New_Line;
                  Show_Error := False;
               when Aux_Display =>
                  if Text_IO.Is_Open (Output_File) then
                     Text_IO.Put (Output_File, Str);
                  else
                     Con_Io.Put (Str, True);
                  end if;
               when Stream_Out =>
                  Con_Io.Put (Str, not Show_Error);
               when Nul_Bucket =>
                  null;
            end case;

         end Print;

         -- **********************************
         -- *                                *
         -- *   Print                        *  BODY
         -- *                                *
         -- **********************************
         procedure Print (Fp : in Io_Flag; Ch : in Character) is

         begin
            if Pretty_Print then
               if Ch = '(' then
                  Balance := Balance + 1;
                  if Start_Pp and (Balance = 3) then
                     New_Line (Fp);
                     Print (Fp, "    ");
                  end if;
               elsif Ch = ')' then
                  Balance := Balance - 1;
                  if Balance = 0 then
                     Pretty_Print := False;
                     Start_Pp     := False;
                  elsif Balance = 1 then
                     Start_Pp := True;
                  end if;
               end if;
            end if;

            case (Fp) is
               when Aux_Display =>
                  if Text_IO.Is_Open (Output_File) then
                     Text_IO.Put (Output_File, Ch);
                  else
                     Con_Io.Put (Ch, True);
                  end if;
               when Stream_Out =>
                  Con_Io.Put (Ch, True);
               when Nul_Bucket =>
                  null;
               when Error_Display =>
                  Text_IO.Put_Line ("Not available");
            end case;

         end Print;

         -- **********************************
         -- *                                *
         -- *   New_Line                     *  BODY
         -- *                                *
         -- **********************************
         procedure New_Line (Fp : in Io_Flag) is
         begin

            case (Fp) is
               when Aux_Display =>
                  if Text_IO.Is_Open (Output_File) then
                     Text_IO.New_Line (Output_File);
                  else
                     Con_Io.New_Line (True);
                  end if;
               when Stream_Out =>
                  Con_Io.New_Line (True);
               when Error_Display | Nul_Bucket =>
                  null;
            end case;

         end New_Line;

         -- **********************************
         -- *                                *
         -- *   Close_File                   *  BODY
         -- *                                *
         -- **********************************
         procedure Close_File (Fp : in Io_Flag) is
         begin
            if Fp = Aux_Display then
               Text_IO.Close (Output_File);
               Print_Long_Float := False;
            end if;
         end Close_File;

         -- **********************************
         -- *                                *
         -- *   Open_File                    *  BODY
         -- *                                *
         -- **********************************
         procedure Open_File (File_Name : in String; Fp : in Io_Flag) is
         begin
            if Fp = Aux_Display then
               Text_IO.Create (Output_File, Text_IO.Out_File, File_Name);
               Print_Long_Float := True;
            end if;
         exception
            when others =>
               Text_IO.Put_Line ("unhandled exception in Open_File");
               raise;
         end Open_File;

      end Token_Io;

      --X1804: CSC
      -- **********************************
      -- *                                *
      -- *   Unification                  *  BODY
      -- *                                *
      -- **********************************
      package body Unification is

         --| Purpose
         --| Package body for Unification
         --|
         --| Exceptions
         --|
         --| Notes
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| April 26, 1993    PP           Heap extensions
         --| August 6, 1993    PP           Optimization

         package Bips renames Builtin_Predicates;

         type Unify_Record is record
            Carp : Ver.Frame_Range;
            Cdrp : Ver.Frame_Range;
         end record;

         --  trail
         type Unification_Array is
           array (Unification_Stack_Range range <>) of Unify_Record;
         type Unification_Access is access Unification_Array;  -- HEAP MODE
         Unification_Stack : Unification_Access;               -- HEAP MODE

         Unify_Ptr : Unification_Stack_Range;

         type Variable_Array is
           array (Ver.Frame_Range range <>) of Lex.Instance;
         type Variable_Access is access Variable_Array;   -- HEAP MODE
         Variables : Variable_Access;                     -- HEAP MODE

         Cache_Frame_Ptr : Ver.Frame_Range;
         Cache_On        : Boolean := False;

         Attempts : Rule_Errors.Count;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Unification_Attempts          *  SPEC
         -- *                                *
         -- **********************************
         function Unification_Attempts
           (Reset : Boolean := False)
            return  Rule_Errors.Count
         is
         begin
            if Reset then
               Attempts := 0;
            end if;
            return Attempts;
         end Unification_Attempts;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Unify_List                   *  SPEC & BODY
         -- *                                *
         -- **********************************
         function Unify_List
           (Source, Target               : in Lex.Goal_Value;
            Old_Frame_Ptr, New_Frame_Ptr : in Ver.Frame_Range)
            return                         Boolean
         is

            --| Purpose
            --| Unify_List unifies arguments which are given in the form of
            --lists.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions
            --| August 16, 1993   PP           Removed count of unifications

            Source_First, Target_First, Source_Rest, Target_Rest :
              Lex.Goal_Value;

         begin

            -- Attempts := Attempts + 1;

            if not Lex.Is_List (Source)
              or else not Lex.Is_List (Target)
            then
               return Unify (Source, Target, Old_Frame_Ptr, New_Frame_Ptr);
            end if;

            Source_First := Lex.Car (Source);
            Target_First := Lex.Car (Target);

            -- If one of the lists is of the form [X|Y], this gets parsed into
            --the
            -- form (. X Y). This means "the list with CAR X and CDR Y."
            -- works by calling unify on the CAR's and by calling Unify_List on
            -- the CDRs.  If one of the lists of the special form described
            --here,
            -- then change the way CAR and CDR are computed for
            -- these lists to be handled in the same way as other lists.

            if Lex.Is_Builtin_Token (Source_First, Bips.P_Period) then
               Source_First := Lex.Cadr (Source);
               Source_Rest  := Lex.Caddr (Source);
            else
               Source_Rest := Lex.Cdr (Source);
            end if;

            if Lex.Is_Builtin_Token (Target_First, Bips.P_Period) then
               Target_First := Lex.Cadr (Target);
               Target_Rest  := Lex.Caddr (Target);
            else
               Target_Rest := Lex.Cdr (Target);
            end if;

            if Unify
                 (Source_First,
                  Target_First,
                  Old_Frame_Ptr,
                  New_Frame_Ptr)
            then
               return (Unify_List
                          (Source_Rest,
                           Target_Rest,
                           Old_Frame_Ptr,
                           New_Frame_Ptr));
            end if;

            return False;

         end Unify_List;

         -- **********************************
         -- *                                *
         -- *   Unify                        *  BODY
         -- *                                *
         -- **********************************
         function Unify
           (Source, Target               : in Lex.Goal_Value;
            Old_Frame_Ptr, New_Frame_Ptr : in Ver.Frame_Range)
            return                         Boolean
         is
            Local_Frame_Ptr     : Ver.Frame_Range := Old_Frame_Ptr;
            Local_Source        : Lex.Goal_Value  := Source;
            Local_Target        : Lex.Goal_Value  := Target;
            Local_New_Frame_Ptr : Ver.Frame_Range := New_Frame_Ptr;
         begin

            -- Attempts := Attempts + 1;

            -- Find the ultimate values bound to the Local_Source and
            -- Local_Target.  If either of these is nonvariable,
            -- lookup has no effect.  If the value is a list,
            -- then this list appears with its own context in the frame.

            -- At least one of Local_Source or Local_Target should be a
            --variable.
            -- If Local_Source is not a variable, then Local_Target must
            -- be a variable, and attach the Local_Source to the Local_Target's
            -- value cell in the context of Local_New_Frame_Ptr.
            -- In structure sharing, any non variable can be considered as a
            -- LISP-type object whether atom or list.
            -- Therefore it is only necessary to fill the cell for
            -- Local_Target within context Local_New_Frame_Ptr with the three
            --items:
            --    Local_Target,   Local_Source,   Local_Frame_Ptr.

            if Lex.Is_Variable (Local_Source) then
               Lookup (Local_Source, Local_Frame_Ptr, Local_Source);
               if Lex.Is_Variable (Local_Source) then
                  Cache_On := True;
                  Attach
                    (Local_Source,
                     Local_Frame_Ptr,
                     Local_Target,
                     Local_New_Frame_Ptr);
                  return True;
               end if;
            end if;

            if Lex.Is_Variable (Local_Target) then
               Lookup (Local_Target, Local_New_Frame_Ptr, Local_Target);
               if Lex.Is_Variable (Local_Target) then
                  Cache_On := True;
                  Attach
                    (Local_Target,
                     Local_New_Frame_Ptr,
                     Local_Source,
                     Local_Frame_Ptr);
                  return True;
               end if;
            end if;

            if Lex.Is_List (Local_Source)
              and then Lex.Is_List (Local_Target)
            then
               return Unify_List
                        (Local_Source,
                         Local_Target,
                         Local_Frame_Ptr,
                         Local_New_Frame_Ptr);
            -- This also includes handling of '|'.
            else
               -- Stopping condition for recursive calls.
               -- Note that complex lists would need the
               -- the same number of arguments to be unified successfully.
               return Lex.Same (Local_Source, Local_Target);
            end if;

         end Unify;

         -- **********************************
         -- *                                *
         -- *   Find                         *  BODY
         -- *                                *
         -- **********************************
         function Find
           (Argument  : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
            return      Ver.Frame_Range
         is

            --| Notes
            --| Find finds the Argument in frame, using linear search.

            Var : Lex.Instance;
         begin

            Var := Lex.Get_Variable (Argument);
            -- Search for most recent allocation.
            for I in  Frame_Ptr .. Ver.Next_Frame loop
               if Lex. "=" (Variables (I), Var) then
                  return (I);
               end if;
            end loop;

            -- Lost track of variable (could not find).
            raise Rule_Errors.Lost_Track_Variable_Error;

         end Find;

         -- **********************************
         -- *                                *
         -- *   Lookup                       *  BODY
         -- *                                *
         -- **********************************
         procedure Lookup
           (Argument     : in Lex.Goal_Value;
            Frame_Ptr    : in out Ver.Frame_Range;
            Return_Value : out Lex.Goal_Value)
         is

            --| Notes
            --| Lookup the value of a variable in the frame area.  If lookup
            --yields
            --| another variable, then continue to lookup until an unbound
            --| variable or to a final bound value.

            Local_Frame_Ptr, Found_Frame : Ver.Frame_Range;
            Value                        : Lex.Goal_Value;
            Local_Return_Value           : Lex.Goal_Value := Argument;
            function "=" (L, R : Ver.Frame_Range) return Boolean renames
              Ver. "=";

         begin

            while Lex.Is_Variable (Local_Return_Value) loop
               Local_Frame_Ptr := Frame_Ptr;
               Found_Frame     := Find (Local_Return_Value, Local_Frame_Ptr);
               Value           := Ver.Frame_Value (Found_Frame);
               Frame_Ptr       := Ver.Frame_Reference (Found_Frame);
               exit when (Lex.Same (Value, Local_Return_Value)
                         and then Frame_Ptr = Local_Frame_Ptr);
               Local_Return_Value := Value;
            end loop;

            Return_Value    := Local_Return_Value;
            Cache_Frame_Ptr := Found_Frame;
         end Lookup;

         -- **********************************
         -- *                                *
         -- *   Attach                       *  BODY
         -- *                                *
         -- **********************************
         procedure Attach
           (Argument  : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range;
            Value     : in Lex.Goal_Value;
            Value_Ptr : in Ver.Frame_Range)
         is

            --| Notes
            --| Function to perform the binding of a variable.  To attach
            --value to
            --| Argument first call find to see where the binding must be
            --placed.
            --| Then place the value in the corresponding value cell.

            Found_Frame : Ver.Frame_Range;

         begin

            if Cache_On then
               Cache_On    := False;
               Found_Frame := Cache_Frame_Ptr;
            else
               Found_Frame := Find (Argument, Frame_Ptr);
            end if;

            Ver.Set_Frame_Value (Found_Frame, Value);

            Ver.Set_Frame_Reference (Found_Frame, Value_Ptr);

            if Unify_Ptr >= Unification_Stack'Last then
               raise Rule_Errors.Unify_Stack_Error;
            end if;
            Unify_Ptr                     := Unify_Ptr + 1;
            Unification_Stack (Unify_Ptr) := (Found_Frame, Frame_Ptr);

         end Attach;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Initialize_Unif               *  BODY
         -- *                                *
         -- **********************************
         procedure Initialize_Unif
           (Length : in Unification_Stack_Range;
            Frames : in Ver.Frame_Range)
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         begin
            -- Should free if stack is not null
            Unification_Stack := new Unification_Array   -- HEAP MODE
              (Unification_Stack_Range'First .. Length);
            Variables         :=
              new Variable_Array (Ver.Frame_Range'First .. Frames);
         end Initialize_Unif;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Variable                  *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Variable
           (Frame_Ptr : in Ver.Frame_Range;
            Variable  : in Lex.Goal_Value)
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         begin
            Variables (Frame_Ptr) := Lex.Get_Variable (Variable);
         end Set_Variable;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Unify_Ptr                 *  BODY
         -- *                                *
         -- **********************************
         function Get_Unify_Ptr return Unification_Stack_Range is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         begin
            return Unify_Ptr;
         end Get_Unify_Ptr;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Unify_From                *  BODY
         -- *                                *
         -- **********************************
         function Get_Unify_From
           (Ptr  : in Unification_Stack_Range)
            return Ver.Frame_Range
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         begin
            return Unification_Stack (Ptr).Carp;
         end Get_Unify_From;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Get_Unify_To                  *  BODY
         -- *                                *
         -- **********************************
         function Get_Unify_To
           (Ptr  : in Unification_Stack_Range)
            return Ver.Frame_Range
         is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         begin
            return Unification_Stack (Ptr).Cdrp;
         end Get_Unify_To;

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *  Set_Unify_Ptr                 *  BODY
         -- *                                *
         -- **********************************
         procedure Set_Unify_Ptr (Ptr : in Unification_Stack_Range) is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| August 5, 1993    Paul Pukite    Initial Version

         begin
            Unify_Ptr := Ptr;
         end Set_Unify_Ptr;

      end Unification;

      --
      -- Main procedure for running starting up
      --
      procedure Aes
        (Ini_File : in String     := "";
         Console  : in Boolean    := True;
         Screen   : in Boolean    := True;
         Ini      : in Allocation := Default)
      is
         Result      : Boolean;
         Str         : String (1 .. Ini.Clause);  -- MAGIC
         Last        : Integer;
         Ch          : Character;
         Lisp        : Boolean    := Getenv ("grp_lisp", "") = "1";
         Tro         : Boolean    := True;
         The_Default : Allocation := Ini;

         procedure Read_Initialize is
            Fp  : Text_IO.File_Type;
            Val : Integer;
            type Defaults is (
               Infers,
               Unifs,
               Clause,
               Hash,
               Input,
               Output,
               Frames,
               Goals,
               Sgoals,
               Trail,
               Cstack);

            package Eio is new Text_IO.Enumeration_IO (Defaults);
            Default : Defaults;

         begin
            Text_IO.Open (Fp, Text_IO.In_File, Ini_File);
            loop
               Eio.Get (Fp, Default);
               Iio.Get (Fp, Val);
               case Default is
               when Infers =>
                  null; -- The_Default.Infers := Val;
               when Unifs =>
                  null; -- The_Default.Unifs := Val;
               when Clause =>
                  The_Default.Clause := Val;
               when Hash =>
                  The_Default.Hash := Val;
               when Input =>
                  The_Default.In_Toks := Val;
               when Output =>
                  The_Default.Out_Toks := Val;
               when Frames =>
                  The_Default.Frames := Val;
               when Goals =>
                  The_Default.Goals := Val;
               when Sgoals =>
                  The_Default.Subgoals := Val;
               when Trail =>
                  The_Default.Trail := Val;
               when Cstack =>
                  The_Default.Control := Val;
               end case;
            end loop;
            -- Text_IO.Close ( FP );

         exception
            when Text_IO.End_Error =>
               Text_IO.Close (Fp);
            when others =>
               Text_IO.Put_Line ("Bad INI file.");
               if Text_IO.Is_Open (Fp) then
                  Text_IO.Close (Fp);
               end if;
         end Read_Initialize;

      begin

         Con_Io.Set_Textio (On => Screen);
         Con_Io.Set_Console (On => Console);

         if Ini_File /= "" then
            Read_Initialize;
         end if;

         Rule_Processor.Initialize (The_Default);     --  Initialize major
                                                      --data areas

         loop
            exit when not Console;

            Token_Io.Print (Token_Io.Aux_Display, "AES> ");

            Text_IO.Get (Ch);

            if Ch = '%' or Ch = ASCII.CR then
               Text_IO.Get_Line (Str, Last);
            elsif Ch = '[' then
               Text_IO.Get_Line (Str, Last);
               Result := Load (File => Str (1 .. Last - 1), Lisp => Lisp);
            else
               Rule_Processor.Load_Clause (1, Ch);
            end if;

            Result := Load (File => "", Lisp => Lisp, Tro => Tro);

            Token_Io.New_Line (Token_Io.Aux_Display);
            -- delay(2.0);

         end loop;
         Con_Io.Set_Console (On => True);

      exception
         when Text_IO.End_Error =>
            Token_Io.Print (Token_Io.Aux_Display, " ** END");
            Token_Io.New_Line (Token_Io.Aux_Display);
            Rule_Processor.Stop;
         when others =>
            raise;

      end Aes;

      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------

      package Ll renames Linked_List;
      package Lex renames Lexical_Analysis;
      package Ver renames Verify;
      package Bips renames Builtin_Predicates;
      package Unif renames Unification;

      Nil : constant Lex.Goal_Value := Lex.Nil;

      Token_Position : Lex.Token_Range;  -- local pointer to tokens

      Number_Functors : Integer;
      Load_Clause_Pos : Natural := 0;

      Tok_Lrb, Tok_Query, Tok_Rrb, Tok_Eot : Lex.Goal_Value;

      Cclause : Lex.Goal_Value;
      --  current clause being interpreted
      Task_Querying : Boolean := False;

      Initialized   : Boolean := False;
      Query_Invoked : Integer := 0;

      Out_Tokens : Lex.Token_Access;   -- Tokens to be accessed by external
                                       --application
      Token_Pos  : Lex.Token_Range;   -- Output token position pointer

      --X1804: CSU
      -- **********************************
      -- *                                *
      -- *   Bind_Tokens                  *  SPEC & BODY
      -- *                                *
      -- **********************************
      procedure Bind_Tokens
        (Item      : in Lex.Goal_Value;
         Frame_Ptr : in Ver.Frame_Range)
      is

         --| Purpose
         --| Bind_Tokens creates a static copy of a bound variable created
         --| during the query process and stores it in the output token
         --| array Out_Tokens.
         --|
         --| Exceptions
         --|
         --| Notes
         --| The static binding differentiates this from Update_Goal.
         --| This is a recursive call.
         --|
         --| Modifications
         --| October 25, 1991  Paul Pukite  Initial Version
         --| November 9, 1991  PP           Added output binding
         --| April 26, 1993    PP           Heap extensions

         --X1804: CSU
         -- **********************************
         -- *                                *
         -- *   Bind_a_Token                 *  SPEC & BODY
         -- *                                *
         -- **********************************
         procedure Bind_A_Token
           (Token     : in Lex.Goal_Value;
            Frame_Ptr : in Ver.Frame_Range)
         is
            --| Purpose
            --| Bind_a_Token binds an atomic token. Internal to Bind_Tokens.
            --|
            --| Exceptions
            --|
            --| Notes
            --|
            --| Modifications
            --| October 25, 1991  Paul Pukite  Initial Version
            --| April 26, 1993    PP           Heap extensions

            Value           : Lex.Goal_Value;
            Local_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
            function ">" (L, R : Ver.Frame_Range) return Boolean renames
              Ver. ">";
            function "+" (L, R : Lex.Token_Range) return Lex.Token_Range
               renames Lex. "+";
            function "=" (L, R : Lex.Token_Range) return Boolean renames
              Lex. "=";
         begin
            if Lex.Is_Variable (Token)
              and then Local_Frame_Ptr > Ver.Frame_Range'First
            then
               Unif.Lookup (Token, Local_Frame_Ptr, Value);
               if not Lex.Is_Variable (Value) then
                  Bind_Tokens (Value, Local_Frame_Ptr);
                  return;
               end if;
            end if;

            if Lex.Is_Builtin_Token (Token, Bips.P_Period) then
               return;
            end if;

            if Lex.Is_Numeric (Token) or
               Lex.Is_Atomic (Token) or
               Lex.Is_Builtin (Token)
            then
               Out_Tokens (Token_Pos) := Token;
               Token_Pos              := Token_Pos + 1;
               if Token_Pos = Out_Tokens'Last then
                  raise Rule_Errors.Output_Error;
               end if;
            end if;

         end Bind_A_Token;

      begin
         if Lex.Is_Token (Item) then         -- Check first whether a token
            Bind_A_Token (Item, Frame_Ptr);  -- is to be stored.
            return;
         elsif Lex.Is_Nil (Item) then
            return;
         end if;
         Bind_Tokens (Lex.Car (Item), Frame_Ptr);
         Bind_Tokens (Lex.Cdr (Item), Frame_Ptr); -- Rest should be a list

      end Bind_Tokens;

      --X1804: CSU
      -- **********************************
      -- *                                *
      -- *   Output_Variables             *  SPEC & BODY
      -- *                                *
      -- **********************************
      procedure Output_Variables
        (Arg       : in Lex.Goal_Value;
         Frame_Ptr : in Ver.Frame_Range)
      is

         --| Purpose
         --| Output_Variables stores symbolic or numeric representations
         --| of the variable arguments represented in the Arg goal.
         --| Stored in Out_Tokens.  See Bind_Tokens.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --|
         --| November  9, 1991  Paul Pukite   Initial Version
         --| April 26, 1993     PP            Heap extensions

         First, Rest     : Lex.Goal_Value;
         Local_Frame_Ptr : Ver.Frame_Range := Frame_Ptr;
         function "=" (L, R : Ver.Frame_Range) return Boolean renames Ver. "=";
         function "+" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "+";
      begin

         if Lex.Is_Variable (Arg) then

            First := Arg;
            if Local_Frame_Ptr /= Ver.Frame_Range'First then
               Unif.Lookup (Arg, Local_Frame_Ptr, First);
            end if;

            Bind_Tokens (First, Local_Frame_Ptr);
            -- Store value of variable.

            Out_Tokens (Token_Pos) := Lex.Nil;
            Token_Pos              := Token_Pos + 1;

         elsif Lex.Is_List (Arg) then
            First := Lex.Car (Arg);
            Rest  := Lex.Cdr (Arg);
            Output_Variables (First, Local_Frame_Ptr);
            Output_Variables (Rest, Local_Frame_Ptr);
         end if;
      end Output_Variables;

      -- **********************************
      -- *                                *
      -- *   Initialize                   *  BODY
      -- *                                *
      -- **********************************
      procedure Initialize (Sizes : Allocation) is --PP := Table_Sizes.Default
                                                   --) is

         --| Notes
         --| Initialize the major data areas.
         --| This consists of the various tables which hold the main
         --structures.

         Result : Boolean;
      -- Sizes : Table_Sizes.Allocation := Table_Sizes.Default;

      begin

         -- Initialize names were unique in case packages are combined
         if not Initialized then
            Lex.Clause_String := new String'(1 .. Sizes.Clause => ASCII.NUL);
            Out_Tokens        :=
              new Lex.Token_Array (
               Lex.Token_Range'First .. Lex.Token_Range (Sizes.Out_Toks));
            Out_Tokens.all    := (others => null);
            Bips.Initialize_Bips
              (Lex.Token_Range (Sizes.In_Toks),
               Lex.Symbol_Hash_Table_Range (Sizes.Hash));
         end if;
         Ll.Initialize_Links;
         if not Initialized then
            Prefix.Initialize_Prefix (Lex.Token_Range (Sizes.In_Toks));

            Tok_Lrb   := Lex.Make_Builtin (Bips.P_Lrb);
            Tok_Rrb   := Lex.Make_Builtin (Bips.P_Rrb);
            Tok_Query := Lex.Make_Builtin (Bips.P_Query);
            Tok_Eot   := Lex.Make_Builtin (Bips.P_Eot);

            Unif.Initialize_Unif
              (Unif.Unification_Stack_Range (Sizes.Trail),
               Ver.Frame_Range (Sizes.Frames));
            Ver.Initialize_Ver
              (Ver.Frame_Range (Sizes.Frames),
               Ver.Goal_Stack_Range (Sizes.Goals),
               Ver.Goal_Stack_Range (Sizes.Subgoals),
               Ver.Control_Stack_Range (Sizes.Control));
         end if;

         Load_Clause_Pos := 0;

         --  Rule_Errors.Set_Condition ( Flag => Rule_Errors.None );

         -- Builtin "or"
         Result :=
            Interpret
              (Lisp_Syntax => True,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => "(:-(; X Y)(X)).",  -- "X;Y:-X."
               Clause2     => "(:-(; X Y)(Y))."); -- "X;Y:-Y."

         Result :=
            Interpret
              (Lisp_Syntax => True,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => "(:-(call X)(X)).",      -- "call(X):-X."
               Clause2     => "(:-(-> X Y)(X ! Y))."); -- "X->Y:-X,!,Y."

         -- argv(Key,_,Value):-dde(1,Key,Value).  %% if key exists, return
         --value
         -- argv (Key, Default, Default).         %% else use default
         Result :=
            Interpret
              (Lisp_Syntax => False,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => "argv(K,_,V):-dde(1,K,V),!.",
               Clause2     => "argv(K,D,D).");

         -- argv(Key):-dde(0,Key,_).              %% if key exists, success
         -- getenv(Key,Value):-dde(-1,Key,Value).
         Result :=
            Interpret
              (Lisp_Syntax => False,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => "argv(K):-dde(0,K,_).",
               Clause2     => "getenv(K,V):-dde(-1,K,V).");
         Result :=
            Interpret
              (Lisp_Syntax => False,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => "getenv(K,_,V):-getenv(K,V),!.",
               Clause2     => "getenv(K,Default,Default).");
         Result :=
            Interpret
              (Lisp_Syntax => False,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => "retractall(X) :- X, retract(X), fail.",
               Clause2     => "retractall(_).");
         Result :=
            Interpret
              (Lisp_Syntax => False,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => "member (Part, [Part|List]).",
               Clause2     =>
                 "member (Part, [Other|List]) :- member (Part, List).");
         Result :=
            Interpret
              (Lisp_Syntax => False,  -- silent display
               Do_Tro      => True,
               Clauses     => 2,
               Clause1     => 
                 "add([Fact|L]) :- Fact(N,_),M is N + 1,asserta(Fact(M,L)).",
               Clause2     =>
                 "add([Fact|L]) :- asserta(Fact(1,L)).");

         --          -- argv(Key,_,Value):-dde(1,Key,Value).  %% if key
         --exists, return value
         --          -- argv (Key, Default, Default).         %% else use
         --default
         --          Result := Interpret (Lisp_Syntax => True,  -- silent
         --display
         --                               Do_Tro => True,
         --                               Clauses => 2,
         --                               Clause1 => "(:-(argv K _ V)((dde 1 K
         --V))).",
         --                               Clause2 => "(argv K D D).");
         --
         --          -- argv(Key):-dde(0,Key,_).              %% if key
         --exists, success
         --          -- getenv(Key,Value):-dde(-1,Key,Value).
         --          Result := Interpret (Lisp_Syntax => True,  -- silent
         --display
         --                               Do_Tro => True,
         --                               Clauses => 2,
         --                               Clause1 => "(:-(argv K)((dde 0 K
         --_))).",
         --                               Clause2 => "(:-(getenv K V)((dde 2 K
         --V))).");
         --
         Initialized := True;
      end Initialize;

      -- **********************************
      -- *                                *
      -- *   Start_Token_Get              *  BODY
      -- *                                *
      -- **********************************
      procedure Start_Token_Get is
      begin
         Token_Position := Lex.Token_Range'First;
      end Start_Token_Get;

      -- **********************************
      -- *                                *
      -- *   Get_Symbol_String            *  BODY
      -- *                                *
      -- **********************************
      procedure Get_Symbol_String
        (Output_String : out String;
         Last          : out Integer)
      is

         Length : Lex.Max_String;
         Token  : Lex.Goal_Value;
         function "+" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "+";

      begin

         Token          := Out_Tokens (Token_Position);
         Token_Position := Token_Position + 2;  -- Skips +2 to jump over NIL

         Length                      := Lex.Get_Sym (Token)'Length;
         Output_String (Output_String'First .. Output_String'First + Length -1) 
                                     := Lex.Get_Sym (Token) (1 .. Length);
         Output_String (Length + 1)  := ASCII.NUL;

         Last := Length + 1;
      end Get_Symbol_String;

      -- **********************************
      -- *                                *
      -- *   Get_Integer                  *  BODY
      -- *                                *
      -- **********************************
      procedure Get_Integer (Value : out Integer) is
         Token : Lexical_Analysis.Goal_Value;
         function "+" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "+";
      begin
         Token          := Out_Tokens (Token_Position);
         Token_Position := Token_Position + 2; -- Skips +2 to jump over NIL
         Value          := Lex.Get_Int (Token);
      end Get_Integer;

      -- **********************************
      -- *                                *
      -- *   Get_Float                    *  BODY
      -- *                                *
      -- **********************************
      procedure Get_Float (Value : out Float) is
         Token : Lexical_Analysis.Goal_Value;
         function "+" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "+";
      begin
         Token          := Out_Tokens (Token_Position);
         Token_Position := Token_Position + 2; -- Skips +2 to jump over NIL

         Value := Lex.Get_Flt (Token);
      end Get_Float;

      -- **********************************
      -- *                                *
      -- *   Get_Symbol_String_List       *  BODY
      -- *                                *
      -- **********************************
      procedure Get_Symbol_String_List
        (Output_String : out String;
         Last          : out Integer)
      is
         function "-" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "-";
      begin
         Get_Symbol_String (Output_String, Last);
         Token_Position := Token_Position - 1; -- Go back to check for NIL
      end Get_Symbol_String_List;

      -- **********************************
      -- *                                *
      -- *   Get_Integer_List             *  BODY
      -- *                                *
      -- **********************************
      procedure Get_Integer_List (Value : out Integer) is
         function "-" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "-";
      begin
         Get_Integer (Value);
         Token_Position := Token_Position - 1; -- Go back to check for NIL
      end Get_Integer_List;

      -- **********************************
      -- *                                *
      -- *   Get_Float_List               *  BODY
      -- *                                *
      -- **********************************
      procedure Get_Float_List (Value : out Float) is
         function "-" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "-";
      begin
         Get_Float (Value);
         Token_Position := Token_Position - 1; -- Go back to check for NIL
      end Get_Float_List;

      -- **********************************
      -- *                                *
      -- *   Is_End_List                  *  BODY
      -- *                                *
      -- **********************************
      function Is_End_List return Boolean is
         function "+" (L, R : Lex.Token_Range) return Lex.Token_Range renames
           Lex. "+";
      begin
         if Lex.Is_Nil (Out_Tokens (Token_Position)) then
            Token_Position := Token_Position + 1;  -- Skip NIL
            return True;
         else
            return False;
         end if;
      end Is_End_List;

      -- **********************************
      -- *                                *
      -- *   Start_Fact_Input             *  BODY
      -- *                                *
      -- **********************************
      procedure Start_Fact_Input (Query : in Boolean := False) is
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         Lex.Clear_Table;
         Number_Functors := 0;
         if Query = True then
            Number_Functors := Number_Functors + 1;
            Lex.Push_Lex (Tok_Lrb);
            Lex.Push_Lex (Tok_Query);
         end if;
      end Start_Fact_Input;

      -- **********************************
      -- *                                *
      -- *   Input_Functor                *  BODY
      -- *                                *
      -- **********************************
      procedure Input_Functor (Input_String : in String) is
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         Number_Functors := Number_Functors + 1;
         Lex.Push_Lex (Tok_Lrb);
         if Input_String /= "[" then  -- Add if functor is not a list.
            Input_Symbol (Input_String);
         end if;
      end Input_Functor;

      -- **********************************
      -- *                                *
      -- *   End_Functor                  *  BODY
      -- *                                *
      -- **********************************
      procedure End_Functor is
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         Number_Functors := Number_Functors - 1;
         Lex.Push_Lex (Tok_Rrb);
      end End_Functor;

      -- **********************************
      -- *                                *
      -- *   Input_Integer                *  BODY
      -- *                                *
      -- **********************************
      procedure Input_Integer (Value : in Integer) is
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         Lex.Push_Lex (Lex.Add_Integer (Table_Sizes.Integer_16 (Value)));
      exception
         when others =>
            Token_Io.Print (Token_Io.Error_Display, "Input_Integer");
            return;
      end Input_Integer;

      -- **********************************
      -- *                                *
      -- *   Input_Float                  *  BODY
      -- *                                *
      -- **********************************
      procedure Input_Float (Value : in Float) is
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         Lex.Push_Lex (Lex.Add_Float (Value));
      exception
         when others =>
            Token_Io.Print (Token_Io.Error_Display, "Input_Float");
            return;
      end Input_Float;

      -- **********************************
      -- *                                *
      -- *   Input_Symbol                 *  BODY
      -- *                                *
      -- **********************************
      procedure Input_Symbol (Input_String : in String) is
         Token  : Lex.Goal_Value;
         Symbol : Lex.Symbol_String;
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         Symbol := Lex.Add_Word (Str => Input_String, Symbol => True);
         Token  := Lex.Make_Atom (Symbol);
         Lex.Push_Lex (Token);
      exception
         when others =>
            Token_Io.Print (Token_Io.Error_Display, "Input_Symbol");
            return;
      end Input_Symbol;

      -- **********************************
      -- *                                *
      -- *   Input_Variable               *  BODY
      -- *                                *
      -- **********************************
      procedure Input_Variable (Input_String : in String) is
         Token  : Lex.Goal_Value;
         Symbol : Lex.Symbol_String;
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         Symbol := Lex.Add_Word (Str => Input_String, Symbol => False);
         Token  := Lex.Insert_Variable (Symbol);   -- Not occurred, save an
                                                   --instance
         Lex.Push_Lex (Token);
      exception
         when others =>
            Token_Io.Print (Token_Io.Error_Display, "Input_Variable");
            return;
      end Input_Variable;

      -- **********************************
      -- *                                *
      -- *   End_Fact_Input               *  BODY
      -- *                                *
      -- **********************************
      procedure End_Fact_Input is
      begin
         if Task_Querying and not Ver.Only_One then
            return;
         end if;
         for I in  1 .. Number_Functors loop
            Lex.Push_Lex (Tok_Rrb);
         end loop;
         Lex.Lex_Table (Lex.Lex_Position) := Tok_Eot;
      end End_Fact_Input;

      -- **********************************
      -- *                                *
      -- *   Load_Clause                  *  BODY
      -- *                                *
      -- **********************************
      procedure Load_Clause (Input_String : in String) is
         Len : constant Integer := Input_String'Length;
         Ch  : Character;
      begin
         for I in  Input_String'Range loop
            Ch := Input_String (I);
            if Ch = ASCII.HT or Ch = ASCII.LF or Ch = ASCII.CR then
               Ch := ' ';
            end if;
            Lex.Clause_String (1 + Load_Clause_Pos + I - Input_String'First)
               := Ch;
         end loop;
         --         Lex.Clause_String (1 + Load_Clause_Pos .. Len +
         --Load_Clause_Pos) :=
         --           Input_String;
         Lex.Clause_String (Len + Load_Clause_Pos + 1) := ASCII.NUL;
      end Load_Clause;

      -- **********************************
      -- *                                *
      -- *   Load_Clause                  *  BODY
      -- *                                *
      -- **********************************
      procedure Load_Clause
        (Position   : in Integer;
         Input_Char : in Character)
      is
      begin
         Lex.Clause_String (Position) := Input_Char;
         if Input_Char = ASCII.NUL then
            Load_Clause_Pos := 0;
         else
            Load_Clause_Pos := Position;
         end if;
      end Load_Clause;

      -- **********************************
      -- *                                *
      -- *   Interpret                    *  BODY
      -- *                                *
      -- **********************************
      function Interpret
        (Token_Input : in Boolean := False;
         Lisp_Syntax : in Boolean := True;
         Do_Tro      : in Boolean := True;
         Clauses     : in Integer := 0;
         Clause1     : in String  := "";
         Clause2     : in String  := "")
         return        Boolean
      is

         --| Notes
         --| Interpret is the main driver for the rule processor.

         Clause_Number : Integer := 1;
         Input_Query   : Boolean;
         Success       : Boolean := False;
         This_Query    : Lex.Goal_Value;
         Solution_List : Lex.Goal_Value;
         At_Frame      : Ver.Frame_Range;

         -- **********************************
         -- *                                *
         -- *   Cleanup                      *  BODY
         -- *                                *
         -- **********************************
         function Cleanup (Success : in Boolean) return Boolean is
         begin
            if Query_Invoked = 0 then
               Ll.Garbage_Collect;
            end if;
            return (Success);
         end Cleanup;

      begin

         Ver.Set_Tro (Do_Tro);

         loop  --  do until return

            Load_Clause_Pos := 0;  -- Reset Clause to beginning

            if Clauses > 0 then

               -- Copy the input strings to Clause_String

               if Clause_Number = 1 then
                  Load_Clause (Clause1);
               elsif Clause_Number = 2 then
                  Load_Clause (Clause2);
               else
                  return (Cleanup (Success));
               end if;

            end if;

            if not Token_Input or not Task_Querying or Ver.Only_One then

               Lex.Tokenize (Token_Input);
               -- Perform a Lexical analysis of current clause.
               -- May have detected syntax errors.
               -- Tokens are in array LEX.Lex_Table.

               Prefix.Prefix (Lisp_Syntax);
               --  Convert the stream of tokens LEX.Lex_Table into prefix
               --format,
               --  by parsing and placing into Prefix.Lextab.

               if Lex.Is_Nil (Prefix.Get_Tok (Lex.First_Token)) then
                  return Cleanup (True);
               else
                  Cclause := Ll.Convert;
               end if;

            end if;

            --  Convert returns the position of newly
            --  parsed clause in linked list area.  It
            --  assigns clause to NIL if parse was impossible.
            Task_Querying := False;
            Input_Query   := Ll.Is_Evaluated (Cclause);

            if Input_Query then
            --  skip this step if clause is just to be asserted into the
            --database.

               begin

                  Query_Invoked := Query_Invoked + 1;

                  Ver.All_Query
                    (Current_Clause => Cclause,
                     This_Query     => This_Query,
                     Solution       => Solution_List,
                     At_Frame       => At_Frame);

                  Query_Invoked := Query_Invoked - 1;

               exception
                  when Rule_Errors.Stop_Error =>
                     Query_Invoked := Query_Invoked - 1;
                     Token_Io.Print (Token_Io.Aux_Display, "** STOP");
                     Token_Io.New_Line (Token_Io.Aux_Display);
                     Lex.Purge_Query (Cclause);
                     return Cleanup (False);

                  when Rule_Errors.Timeout_Error =>
                     Query_Invoked := Query_Invoked - 1;
                     Token_Io.Print (Token_Io.Aux_Display, "** TIME");
                     Token_Io.New_Line (Token_Io.Aux_Display);
                     Lex.Purge_Query (Cclause);
                     return (Cleanup (Success));

                  when others =>
                     Query_Invoked := Query_Invoked - 1;
                     Token_Io.Print (Token_Io.Error_Display, "QUERY");
                     raise;
               end;

               if Lex.Is_Goal (Solution_List) then

                  Token_Io.Print (Token_Io.Aux_Display, "** YES");
                  Token_Io.New_Line (Token_Io.Aux_Display);
                  Token_Pos := Out_Tokens'First;
                  Output_Variables (This_Query, At_Frame);
                  Token_Io.Print_Variables
                    (Token_Io.Aux_Display,
                     This_Query,
                     At_Frame);
                  Success := True;

                  Task_Querying := True;

               else
                  Token_Io.Print (Token_Io.Aux_Display, "** NO");
                  Token_Io.New_Line (Token_Io.Aux_Display);
                  --  bindings are released if goal failed

                  -- Ll.Set_Collect; -- only set GC on failure?

               end if;

               Token_Io.Print_Statistics;
               Lex.Purge_Query (Cclause);

            else  -- a fact or rule
               Ll.Update_Clause_List (Cclause);
               --  update the linked lists which hold similar clauses together.

               Success := True;

            end if;

            if Clause_Number >= Clauses then
               return (Cleanup (Success));
            else
               if Query_Invoked = 0 then
                  Ll.Garbage_Collect;
               end if;
               Clause_Number := Clause_Number + 1;
            end if;

         end loop;

      exception
         when Rule_Errors.Lex_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Lex");
            Lex.Clear_Table;
            return (Cleanup (Success));
         --  if there is a syntax error in the clause, return any Success

         when Rule_Errors.Prefix_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Prefix");
            return (Cleanup (Success));

         when Rule_Errors.Output_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Output");
            return Cleanup (False);

         when Rule_Errors.Parse_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Parse");
            Ll.Purge_Clause (Cclause);
            return (Cleanup (Success));

         when Rule_Errors.Clist_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Clause list");
            Ll.Clean_Clause_List (Cclause);
            return (Cleanup (Success));

         when Rule_Errors.Lost_Track_Variable_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Lost track of variable");
            Token_Io.Print_Statistics;
            return (Cleanup (Success));

         when Rule_Errors.Builtin_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Builtin function");
            return (Cleanup (Success));

         when Rule_Errors.Unbound_Variable_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Unbound variable");
            return (Cleanup (Success));

         when Rule_Errors.Nonnumeric_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Non-numeric");
            return (Cleanup (Success));

         when Rule_Errors.Evaluate_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Evaluate");
            return (Cleanup (Success));

         when Rule_Errors.Compute_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Compute");
            return (Cleanup (Success));

         when Rule_Errors.Unbound_Relation_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Unbound relation");
            return (Cleanup (Success));

         when Rule_Errors.Relation_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Relation");
            return (Cleanup (Success));

         when Rule_Errors.Variable_Overwrite_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Variable overwrite");
            return (Cleanup (Success));

         when Rule_Errors.Garbage_Collection_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Garbage collection");
            raise;

         when Rule_Errors.Numeric_Table_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Numeric Table");
            raise;

         when Rule_Errors.Variable_Table_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Variable Table");
            raise;

         when Rule_Errors.Symbol_Table_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Symbol Table");
            raise;

         when Rule_Errors.Unifications_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Unifs");
            return (Cleanup (Success));

         when Rule_Errors.Inferences_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Inferences");
            return (Cleanup (Success));

         when Rule_Errors.Control_Stack_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Control Stack");
            return (Cleanup (Success));

         when Rule_Errors.Frame_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Frame overflow");
            return (Cleanup (Success));

         when Rule_Errors.Unify_Stack_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Unify Stack overflow");
            return (Cleanup (Success));

         when Rule_Errors.Goal_Stack_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Goal Stack overflow");
            return (Cleanup (Success));

         when Rule_Errors.Links_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Too many links");
            raise;

         when Constraint_Error =>
            Token_Io.Print
              (Token_Io.Error_Display,
               "Constraint in Interpret.");
            raise;

         when Storage_Error =>
            Token_Io.Print (Token_Io.Error_Display, "Storage in Interpret.");
            raise;

         when others =>
            Token_Io.Print (Token_Io.Error_Display, "Unknown in Interpret.");
            raise;

      end Interpret;

      -- **********************************
      -- *                                *
      -- *   Stop                         *  BODY
      -- *                                *
      -- **********************************
      procedure Stop is
      begin
         Ver.Stop;
      end Stop;

      --X1804: CSU
      -- **********************************
      -- *                                *
      -- *  Multiple                      *  BODY
      -- *                                *
      -- **********************************
      procedure Multiple is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         Ans : Boolean;
      begin
         Ans :=
            Interpret
              (Lisp_Syntax => False,
               Do_Tro      => True,
               Clauses     => 1,
               Clause1     => "multiple?");
      end Multiple;

      --X1804: CSU
      -- **********************************
      -- *                                *
      -- *  Only_One                      *  BODY
      -- *                                *
      -- **********************************
      procedure Only_One is

         --| Purpose
         --| See spec.
         --|
         --| Exceptions (none)
         --| Notes
         --|
         --| Modifications
         --| April 26, 1993    Paul Pukite    Initial Version

         Ans : Boolean;
      begin
         Ans :=
            Interpret
              (Lisp_Syntax => False,
               Do_Tro      => True,
               Clauses     => 1,
               Clause1     => "only_one?");
      end Only_One;

      procedure Set_Write (Proc : Write_Proc) is
      begin
         Text_Server.Set_Write (Proc);
      end Set_Write;

      procedure Set_Post (Proc : Write_Proc) is
      begin
         Con_Io.Post_Proc := Proc;
      end Set_Post;

      Iterator : Lex.Token_Range := Lex.Token_Range'First;

      procedure Reset_Iterator is
      begin
         Iterator := Lex.Token_Range'First;
      end Reset_Iterator;

      procedure Iterate (Output_String : out String; Last : out Integer) is
         Gv : Lex.Goal_Value;
         use type Lex.Token_Range;
      begin
         Gv       := Out_Tokens (Iterator);
         Iterator := Iterator + 1;
         if Lex.Is_Nil (Gv) then
            Last := 0;
         elsif Lex.Is_Float (Gv) then
            declare
               F : constant String := Float'Image (Lex.Get_Flt (Gv));
            begin
               Last                      := F'Last;
               Output_String (Output_String'First .. Output_String'First + Last - 1) 
                                         := F;
            end;
         elsif Lex.Is_Integer (Gv) then
            declare
               I : constant String := Integer'Image (Lex.Get_Int (Gv));
            begin
               Last                      := I'Last;
               Output_String (Output_String'First .. Output_String'First + Last - 1) 
                                         := I;
            end;
         else
            declare
               S : constant String := Lex.Get_Sym (Gv);
            begin
               Last                      := S'Last;
               Output_String (Output_String'First .. Output_String'First + Last - 1) 
                                         := S;
            end;
         end if;
      exception
         when others =>
            Reset_Iterator;
            raise;
      end Iterate;

      function Parse
        (Functor, Args : in String;
         Terminal      : in Character := '?')
         return          Boolean
      is
         Rule : constant String := F (Functor, Args) & Terminal;
      begin
         return Interpret
                  (Token_Input => False,
                   Lisp_Syntax => False,
                   Clauses     => 1,
                   Clause1     => Rule);
      exception
         when E : others =>
            Text_IO.Put_Line ("*** EXCEPTION => Parsing: " & Rule);
            raise No_Match;
      end Parse;

      function Parse
        (Query    : in String;
         Terminal : in Character := '?')
         return     Boolean
      is
         Rule : constant String := Query & Terminal;
      begin
         return Interpret
                  (Token_Input => False,
                   Lisp_Syntax => False,
                   Clauses     => 1,
                   Clause1     => Rule);
      exception
         when E : others =>
            Text_IO.Put_Line ("*** EXCEPTION => Parsing: " & Rule);
            raise No_Match;
      end Parse;

      --------------------------------------------------
      -- Retrieving a pattern-matched set
      --------------------------------------------------
      procedure Match
        (Functor  : in String;
         Vars     : in out Variables;
         Terminal : in Character := '?')
      is
         use Ada.Strings.Unbounded;
         Arg : Unbounded_String;
         Sym : Symbol;
         Len : Integer := 0;
      begin
         -- If Simple query ( e.g.  hello? )
         if Vars'Length = 0 then
            if Parse (Functor, "", Terminal) then
               return;
            else
               raise No_Match;
            end if;
         end if;
         -- If Complex query ( e.g.  hello ("greeting", Who)? )
         for I in  Vars'Range loop
            if Vars (I) = Null_Unbounded_String then
               Arg := Arg + To_Unbounded_String ("V" & S (I)); -- To Variable
            else
               Arg := Arg + Vars (I);
            end if;
         end loop;
         if Parse (Functor, To_String (Arg), Terminal) then
            Reset_Iterator;
            for I in  Vars'Range loop
               if Vars (I) = Null_Unbounded_String then
                  for Count in  1 .. Integer'Last loop
                     Iterate (Sym, Len);
                     exit when Len = 0;
                     -- Text_IO.Put_Line ("V" &  S(I) & ": " & Sym(1..Len));
                     if Count = 1 then
                        Vars (I) := To_Unbounded_String (Sym (1 .. Len));
                     else
                        Vars (I) := Vars (I) &
                                    ASCII.HT &
                                    To_Unbounded_String (Sym (1 .. Len));
                     end if;
                  end loop;
               end if;
            end loop;
         else
            raise No_Match;
         end if;
      end Match;

   end Rule_Processor;

   Max_GC_Loops : constant Integer := Integer'Value (Getenv ("grp_gc_loops", "1_000"));

   task body Agent_Type is

      Current_Results_Display : Results_Display := null;
      Current_Values_Display  : Values_Display  := null;
      Current_Post_Display    : Results_Display := null;

      procedure Rp_Results_Display (Str : in String) is
      begin
         Current_Results_Display (Str);
      end Rp_Results_Display;

      procedure Rp_Post_Display (Str : in String) is
      begin
         Current_Post_Display (Str);
      end Rp_Post_Display;

      --
      -- The RP_Values_Display will filter the basic ASCII RP output into
      -- a set of (key,val) pairs corresponding to bound variables.
      --
      Key                    : Ada.Strings.Unbounded.Unbounded_String;
      Started_Values_Display : Boolean := False;

      procedure Rp_Values_Display (Str : in String) is
         use Ada.Strings.Unbounded;
      begin
         if Str (Str'Last) = ASCII.LF then            -- Ignore linefeed
                                                      --markers
            null;
         else
            if Str = "** YES" then                    -- Hit the 'YES' ASCII
                                                      --marker
               Started_Values_Display := True;        -- Valid results are
                                                      --forthcoming
            elsif Started_Values_Display then
               if Str = " := " or Str = " " then      -- Assignment marker or
                                                      --spacer
                  null;
               elsif Str = "  " then                  -- Binding results
                                                      --forthcoming
                  Key := Null_Unbounded_String;
               elsif Key = Null_Unbounded_String then    -- First string seen
                                                         --is the key,
                  Key := To_Unbounded_String (Str);   -- once assigned, it is
                                                      --non-null.
               else
                  Current_Values_Display (To_String (Key), Str);  -- Callback
                                                                  --value
               end if;
            end if;
         end if;
      end Rp_Values_Display;

      package Grp is new Rule_Processor;

      Query_Success : Boolean;
      Number_Loops : Long_Integer := 0;
   begin
      loop
         begin
            if Number_Loops > Long_Integer (Max_GC_Loops) then
               if Grp.Parse ("gc", '?') then
                  null;
               else
                  raise No_Match;
               end if;
               Number_Loops := 0;
            end if;
            select
               accept Init (
                 Ini_File  : in String;
                  Console  : in Boolean;
                  Screen   : in Boolean;
                  Ini      : in Allocation := Default) do
                  Grp.Aes
                    (Ini_File => Ini_File,
                     Console  => Console,
                     Screen   => Screen,
                     Ini      => Ini);
               end Init;
            or
               accept Load (File : in String) do
                  if Grp.Load (File) then
                     null;
                  else
                     raise No_Match;
                  end if;
               end Load;
            or
               accept Assert (Fact : in String) do
                  Query_Success := Grp.Parse (Fact, '.');
               end Assert;
            or
               accept Query (Rule : in String; List : in out Variables) do
                  Grp.Match (Rule, List);
               end Query;
            or
               accept Query (Rule : in String; List : in Results_Display) do
                  Current_Results_Display := List;
                  Grp.Set_Write (Grp.Write_Proc'(Rp_Results_Display'Access));
                  Query_Success := Grp.Parse (Rule);
                  Grp.Set_Write (null);
               end Query;
            or
               accept Query (Rule : in String; List : in Values_Display) do
                  Started_Values_Display := False;
                  Key                    :=
                    Ada.Strings.Unbounded.Null_Unbounded_String;
                  Current_Values_Display := List;
                  Grp.Set_Write (Grp.Write_Proc'(Rp_Values_Display'Access));
                  Query_Success := Grp.Parse (Rule);
                  Grp.Set_Write (null);
               end Query;
            or
               accept Parse (Rule : in String) do
                  if Grp.Parse (Rule, '?') then
                     null;
                  else
                     raise No_Match;
                  end if;
               end Parse;
            or
               accept Set_Post (Cb : in Results_Display) do
                  Current_Post_Display := Cb;
                  Grp.Set_Post (Grp.Write_Proc'(Rp_Post_Display'Access));
               end Set_Post;
            --or
            --   terminate;
            end select;

            Number_Loops := Number_Loops + 1;

         exception
            when No_Match =>
               Number_Loops := Number_Loops + 1;
            when E: others =>
               Text_IO.Put_Line ("Continuing rule processor w/error: " & 
                                 Ada.Exceptions.Exception_Information (E));
         end;
      end loop;
   end Agent_Type;

   use Text_Io;
   Output_File : File_Type;

begin
   if Getenv ("grp_nostderr", "") = "1" then
      -- Open (Output_File, Out_File, "/dev/null"); -- not portable
      Create (Output_File); -- creates anonymous file
      Set_Error (Output_File);
   else
      Set_Error (Standard_Error);
   end if;
exception
   when E : others =>
      Text_IO.Put_Line ("GRP elab:" & Ada.Exceptions.Exception_Information(E));
end Pace.Rule_Process;
