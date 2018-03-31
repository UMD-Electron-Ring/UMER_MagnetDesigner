29 June 2016

DESCRIPTION

This directory has all of the scripts in one place to easily generate magnet designs.


HOW TO

To generate Maxwell model

    1. OctoDesign_v5.m
    2. Run OctupoleDesign_v1r1.py as a macro inside of Ansys Maxwell
    3. User must connect conductors and configure boundaries & excitations by hand in the Maxwell modeler.
            See ../UMEROctupoleModelHowTo.docx
    
To generate Gerber files

    1. OctoDesign_v5.m
    2. PCBdesign_v1r2.m
    3. Open Cadsoft EAGLE.  Create a new board (File -> New -> Board).
    4. In the "Board" window, File -> Execute Script.  Choose testMacro.scr in the Plug_n_Play directory.
    5. To generate the NSF logo on the PCB, execute the LogoMacroPCB.scr script.
    
    Once Satisfied with the design:
    
    1. In "Board" window: File -> CAM Processor
    2. File -> Open -> Job...
    3. Open gerb274x-octupole.cam for gerber files; open excellon-octupole.cam for excellon drilling files.
    4. Click "Process Job" to generate the files.
    
To clean the directory

    Run (double-click) cleandir.cmd
    
    
    
QUESTIONS

David Matthew Jr.
matt0089@umd.edu
