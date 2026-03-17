with Text_Io;
with Ada.Command_Line;

package body Tlc is
    type Colors is (Red, Yellow, Green);
    for Colors'Size use 8;

    Short : Integer := 2;
    pragma Export (C, Short, "tlc__short");
    Medium : Integer := 4;
    pragma Export (C, Medium, "tlc__medium");
    Long : Integer := 12;
    pragma Export (C, Long, "tlc__long");

    Stdio_Flag : Boolean := False;

    procedure Print_To_Stdio (Text : in String) is
    begin
	if Stdio_Flag then
	    Text_Io.Put_Line (Text);
	end if;
    end Print_To_Stdio;

    protected Traffic_Light_Controller is
	procedure Input_Clock (S, H : out Colors);
	entry Sense_Car;
    private
	entry Tick;
	Count : Integer := 0;
	Street : Colors := Red;
	Highway : Colors := Green;
	Clock : Boolean := False;
    end Traffic_Light_Controller;

    protected body Traffic_Light_Controller is
	procedure Input_Clock (S, H : out Colors) is
	begin
	    S := Street;
	    H := Highway;
	    Clock := True;
	end Input_Clock;

	entry Sense_Car when Count = 0 and Clock is
	begin
	    Highway := Yellow;
	    requeue Tick;
	end Sense_Car;

	entry Tick when Clock is
	begin
	    Clock := False;
	    if Count = Short then
		Highway := Red;
		Street := Green;
	    elsif Count = Short + Medium then
		Street := Yellow;
	    elsif Count = 2 * Short + Medium then
		Street := Red;
		Highway := Green;
	    elsif Count = Long then
		Count := 0;
		return;
	    end if;
	    Count := Count + 1;
	    requeue Tick;
	end Tick;
    end Traffic_Light_Controller;


    Street, Highway : Colors;
    pragma Export (C, Street, "tlc__street");
    pragma Export (C, Highway, "tlc__highway");

    task Timer;
    task body Timer is
    begin
	loop
	    delay 1.0;
	    Traffic_Light_Controller.Input_Clock (Street, Highway);
	    Print_To_Stdio ("Street=" & Colors'Image (Street) &
			    " | Highway=" & Colors'Image (Highway));
	end loop;
    end Timer;

    task Monitor;

    Sense_Car : Boolean := False;
    ---Sense_Car : INTEGER := 0;
    pragma Volatile (Sense_Car);
    pragma Export (C, Sense_Car, "tlc__sense_car");

    task body Monitor is
    begin
	loop
	    delay 0.1;
	    if Sense_Car then
		Sense_Car := False;
		Print_To_Stdio ("Car arrived");
		Traffic_Light_Controller.Sense_Car;
	    end if;
	end loop;
    end Monitor;


    use Ada.Command_Line;
begin
    if Argument_Count > 0 and then Argument (1) = "stdio_flag" then
	Stdio_Flag := True;
    end if;
end Tlc;


