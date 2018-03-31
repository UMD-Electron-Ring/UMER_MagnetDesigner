29 June 2016

DESCRIPTION

Easily generate octupole printed circuit magnet designs for particle accelerator nonlinear optics.


HOW TO
    
To generate Gerber files

    1. Run OctoDesign_v5.m
    2. Run PCBdesign_v1r2.m
    3. Open Cadsoft EAGLE.  Create a new board (File -> New -> Board).
    4. In the "Board" window, File -> Execute Script.  Choose testMacro.scr in this directory.
    5. To generate the NSF logo on the PCB, execute the LogoMacroPCB.scr script (File -> Execute Script).
    
    Once Satisfied with the design:
    
    1. Save the board file (File -> Save)
    2. In "Board" window: File -> CAM Processor
    3. File -> Open -> Job...
    4. Open gerb274x-octupole.cam for gerber files; open excellon-octupole.cam for excellon drilling files.
    5. Click "Process Job" to generate the files.
    
To clean the directory

    Run (double-click) cleandir.cmd
    
    
    
QUESTIONS

David Matthew Jr.
matt0089@umd.edu
