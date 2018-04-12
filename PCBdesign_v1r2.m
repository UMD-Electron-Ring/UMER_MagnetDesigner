%% Configure. USERS CHANGE THIS SECTION FOR GENERATING DESIGNS
% NOTE: To change the silk screen custom text, look at 
MacroFilename = 'BoardMacro.scr';

organization = 'UMER Nonlinear Optics';   % For display on silkscreen
designNumber = 'Octo_2015a';              % For display on silkscreen

PCBlength = 79.45-20.55; % mm
PCBwidth  = 146.1-53.9;
wireWidth = '.8';

viaAp  = '.6';             % via aperture      (drill size)          mm
termAp = '1.1';            % terminal aperture (drill size)          mm

viaD  = '1';               % via diameter      (aperture + plating)  mm
termD = '2.8';             % terminal diameter (aperture + plating)  mm

% EVERYTHING BELOW USERS NEED NOT CHANGE
%% Load Data

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
% DEPRECATED.  New versions of Eagle use 'line'
% fprintf(fid, 'wire .2');
fprintf(fid, 'line .2');
fprintf(fid, ' (%f %f)', dimsAry);
fprintf(fid, ';\n');

%% top and bottom wire layers

Lefts = {[],[],[],[]};
Rights = {[],[],[],[]};

for ii=1:4
    LeftSpiral = RawData{ii};
    RightSpiral = RawData{ii};
    
    LeftSpiral(1,:) = LeftSpiral(1,:) - PCBwidth/4;
    RightSpiral(1,:) = RightSpiral(1,:) + PCBwidth/4;
    
    Lefts{ii} = LeftSpiral;
    Rights{ii} = RightSpiral;
end

all = {Lefts, Rights};

for jj=1:2
    iter = all{jj};
    
    fprintf(fid,'layer Top\n');
    for ii=[1,3]
        spiral = iter{ii};
        % DEPRECATED.  New versions of Eagle use 'line'
        % fprintf(fid, ['wire ', wireWidth]);
        fprintf(fid, ['line ', wireWidth]);
        fprintf(fid, ' (%f %f)', spiral);
        fprintf(fid, ';\n');
    end

    fprintf(fid,'layer Bottom\n');
    for ii=[2,4]
        spiral = iter{ii};
        % DEPRECATED.  New versions of Eagle use 'line'
        % fprintf(fid, ['wire ', wireWidth]);
        fprintf(fid, ['line ', wireWidth]);
        fprintf(fid, ' (%f %f)', spiral);
        fprintf(fid, ';\n');
    end
    
end

%%  Make vias and terminals

% via locations (last indices of first 3 spirals)
viaLs = [];
for ii=1:3
    viaLs = [viaLs Lefts{ii}(:,end)];
    viaLs = [viaLs Rights{ii}(:,end)];
end

% terminal locations (first idx of first spiral, last idx of last spiral)
termLs = [Lefts{1}(:,1) Lefts{4}(:,end) Rights{1}(:,1) Rights{4}(:,end)];


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