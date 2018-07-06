%%% MakePCB.m
% Generates a user script for Autodesk EAGLE PCB CAD software.

% Input design parameters in the "Configure" section.

% See README for more details and instructions for use.
%% Clear Vars

clear;
%% Configure. USERS CHANGE THIS SECTION FOR GENERATING DESIGNS
MacroFilename = 'BoardMacro.scr';

organization = 'UMER Nonlinear Optics';   % For display on silkscreen
designNumber = 'Sextu_2018a';              % For display on silkscreen

PCBlength = 79.45-20.55; % mm
PCBwidth  = 146.1-53.9;
wireWidth = '.8';
poles = 6;

viaAp  = '.6';             % via aperture      (drill size)          mm
termAp = '1.1';            % terminal aperture (drill size)          mm

viaD  = '1';               % via diameter      (aperture + plating)  mm
termD = '2.8';             % terminal diameter (aperture + plating)  mm

% EVERYTHING BELOW USERS NEED NOT CHANGE
%% Load Data

n = poles/2;
RawData = load('PCBdata');
RawData = RawData.PCB;
% Open macro file to write
fid = fopen(MacroFilename,'w');

%% Initial Settings
fprintf(fid, 'grid mm finest;\n');

%% Define Board dims

dimsAry = [-PCBwidth/2, -PCBlength/2; 
           -PCBwidth/2, PCBlength/2; 
           PCBwidth/2, PCBlength/2;
           PCBwidth/2, -PCBlength/2;
           -PCBwidth/2, -PCBlength/2;]';

fprintf(fid, 'layer Dimension;\n');
fprintf(fid, 'line .2');
fprintf(fid, ' (%f %f)', dimsAry);
fprintf(fid, ';\n');

%% top and bottom wire layers

Full = cell(4);
Half = cell(2);

for ii=1:4
    Spiral = RawData{ii};
    
    Spiral(1,:) = Spiral(1,:) + PCBwidth/6;
    
    Full{ii} = Spiral;
end

for ii=1:2
  Spiral = RawData{ii};
  Spiral(1,:) = Spiral(1,:) - PCBwidth/2;
  Half{ii} = Spiral;
end

fprintf(fid,'layer Top\n');
for ii=[1,3]
    spiral = Full{ii};
    fprintf(fid, ['line ', wireWidth]);
    fprintf(fid, ' (%f %f)', spiral);
    fprintf(fid, ';\n');
end

topSpiral = Half{1};
fprintf(fid, ['line ', wireWidth]);
fprintf(fid, ' (%f %f)', topSpiral);
fprintf(fid, ';\n');

fprintf(fid,'layer Bottom\n');
for ii=[2,4]
    spiral = Full{ii};
    fprintf(fid, ['line ', wireWidth]);
    fprintf(fid, ' (%f %f)', spiral);
    fprintf(fid, ';\n');
end    

botSpiral = Half{2};
fprintf(fid, ['line ', wireWidth]);
fprintf(fid, ' (%f %f)', botSpiral);
fprintf(fid, ';\n');

%%  Make vias and terminals

% via locations (last indices of first 3 spirals)
viaLs = [];
for ii=1:3
    viaLs = [viaLs Full{ii}(:,end)];
end

viaLs = [viaLs Half{1}(:,end)];

% terminal locations (first idx of first spiral, last idx of last spiral)
termLs = [Full{1}(:,1) Full{4}(:,end) Half{1}(:,1)];
%Half{1}(:,1)

fprintf(fid, ['change drill ' viaAp ';\n']);
fprintf(fid, ['via ' viaD ' round']);
fprintf(fid, ' (%f %f)', viaLs);
fprintf(fid, ';\n');

fprintf(fid, ['change drill ' termAp ';\n']);
fprintf(fid, ['via ' termD ' round']);
fprintf(fid, ' (%f %f)', termLs);
fprintf(fid, ';\n');


%% Drill Holes

smD   = '1.6';     % small hole drill size
BigD  = '3.2';     % big hole drill size

BigHy = 50-23.7;
BigHx = 130.6-100;

SmHy  = BigHy+.5;

BigHL = [BigHx BigHx -BigHx -BigHx; BigHy -BigHy BigHy -BigHy];
SmHL  = [0 0; SmHy -SmHy];

fprintf(fid, ['hole ' BigD]);
fprintf(fid, ' (%f %f)', BigHL);
fprintf(fid, ';\n');

fprintf(fid, ['hole ' smD]);
fprintf(fid, ' (%f %f)', SmHL);
fprintf(fid, ';\n');

%% Silk screen

fprintf(fid, 'change font vector;\n change size 1.9;\n');

fprintf(fid, 'layer bPlace;\n');
fprintf(fid, 'text Inside (12 -28);\n');

fprintf(fid, ['text ' organization ' (16.8 23);\n']);

fprintf(fid, 'layer tPlace;\n');
fprintf(fid, 'text Outside (-12 -28);\n');

fprintf(fid, ['text ' designNumber ' (7 24.5);\n']);

fprintf(fid, 'change size 1.3;\n');
fprintf(fid, 'text Blk (18 -26.1);\n');
fprintf(fid, 'text Red (25 -26.1);\n');
fprintf(fid, 'text Blk (-28 -26.1);\n');
fprintf(fid, 'text Red (-21 -26.1);\n');

%% Close the macro file

fclose(fid);