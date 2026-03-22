with Gkb;
with Pace;
package Vkb is new Gkb (Task_Stack_Size => 100_000,
                        Prolog_File => Pace.Getenv ("VKB_FILE", "/kbase/ntc_vkb.pro"),
                        Allocation_Data => (Clause => 10000,
                                            Hash => 507,
                                            In_Toks => 3000,
                                            Out_Toks => 1500,
                                            Frames => 14000,
                                            Goals => 16000,
                                            Subgoals => 1300,
                                            Trail => 15000,
                                            Control => 1700));

