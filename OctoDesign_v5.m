%%% OctoDesign

% Revision History:
% 
% v5: Version for producing octupole magnets, design octo_2015a 

%% Clear Vars

clear;
%% Configure

PCBfile = 'PCBdata';

L = 46.5;  % Length of magnet
HousingRadius = 29.35;              % 29.35 I calculated this as 29.329 mm (from pcb width)
SubstrateThickness = .2667;
WireThickness = .0889;
Multipole = 8;      

spirals = 10;
a = .953;

% Origin of flat sketch

Xo = 0;
Yo = 0;

%% Initialize vars

R = HousingRadius;
N = spirals*2+2;
dz = L/N;
n = Multipole/2;  % coefficent for multipole expansion

%% Calculate F (phi) for axial conductors

Z = zeros(1,spirals);
F = zeros(1,spirals);
for ii=1:spirals
    Z(ii) = L/2-dz*ii;
    F(ii) = 1/n * asin(1 - (2*Z(ii)/(a * L))^2);

end

% Shift Z(:) and F(:) by dz and df (a function of dz) to prepare spirals
% (Without a shift, nested rectangles would be produced).
% The top and bottom spirals (which will be on the top and bottom layer
% of the 2-layer printed circuit) are shifted differently to accomodate
% a continuous conduction path for current through all 4 spirals.
ZTopShift = [L/2-dz*0, Z];
FTopShift = [F, 1/n * asin(1 - (2*(L/2-dz*(spirals+1))/(a * L))^2)]; 

ZBotShift = [Z, L/2-dz*(spirals+1)];
FBotShift = [1/n * asin(1 - (2*(L/2-dz*0)/(a * L))^2), F]; 



%% Prepare coordinate data for each spiral 
%  (Right now there are only two spirals.  The last two will be created
%  by reflecting these over a plane.


ZTopSpiral = [-ZTopShift, Z, Z, -Z];             
FTopSpiral = [FTopShift, F, pi/n-F, pi/n-F]; % Coord order: BL TL TR BR

ZBotSpiral = [-ZBotShift, -Z, Z, Z];
FBotSpiral = [FBotShift, pi/n-F, pi/n-F, F]; % Coord order: BL BR TR TL


%% Connect spirals in right sequence


spiralIdx = zeros(1,spirals*4+1);
for i=0:spirals-1
    spiralIdx(4*i+1) = i + 1;      % BL  Fplot(1:21)
    spiralIdx(4*i+2) = i + 1*spirals + 2;     % TL  Fplot(22:41)
    spiralIdx(4*i+3) = i + 2*spirals + 2;     % TR
    spiralIdx(4*i+4) = i + 3*spirals + 2;     % BR
end
spiralIdx(spirals*4+1) = spirals + 1;


%% Convert (r,phi,z) coordinates to (x,y)

% On the flat printed circut, F (phi) corresponds to the "x" axis,
% and Z corresponds to the "y" axis

% Top
TopRightSpiral = [FTopSpiral(spiralIdx); ZTopSpiral(spiralIdx)];
% Bottom
BotRightSpiral = [FBotSpiral(spiralIdx); ZBotSpiral(spiralIdx)];

%               *Diagnostic Graphs*
% figure
% plot(TopRightSpiral(1,:),TopRightSpiral(2,:));
% figure
% plot(BotRightSpiral(1,:),BotRightSpiral(2,:));

%% Make rotated/reflected models of spiral

% TopLeft: TopRight reflected over line x=0
TopLeftSpiral = [-1 0; 0 1] * TopRightSpiral;
% BotRight: BotLeft reflected over line x=0
BotLeftSpiral = [-1 0; 0 1] * BotRightSpiral;

%               *Diagnostic Graphs*
% figure;
% hold on;
% plot(TopRightSpiral(1,:),TopRightSpiral(2,:));
% plot(TopLeftSpiral(1,:),TopLeftSpiral(2,:));
% hold off
% 
% figure;
% hold on;
% plot(BotRightSpiral(1,:),BotRightSpiral(2,:));
% plot(BotLeftSpiral(1,:),BotLeftSpiral(2,:));
% hold off;

%% Make manual modifications on flat model
% To understand what each line does, it may be most helpful to comment
% out the line, and plot the change using the diagnostic graphs.
% Note the diagnostic graphs are 3D, so you can use the plot rotate tool.


%               *Vias*
% TopLeft Outside via alignment
TopLeftSpiral(2,1) = TopLeftSpiral(2,5);

% BotRight Outside via alignment (with TopLeft)
BotRightSpiral(1,1) = TopLeftSpiral(1,1);

% BotLeft Outside via alignment (don't collide with BotRight)
BotLeftSpiral(1,1) = BotLeftSpiral(1,9);

% Align inside vias (we have to add points here, not replace)
BotLeftSpiral = horzcat(BotLeftSpiral, [TopLeftSpiral(1,end); BotLeftSpiral(2,end)]);
TopLeftSpiral = horzcat(TopLeftSpiral, [TopLeftSpiral(1,end); BotLeftSpiral(2,end)]);

BotRightSpiral = horzcat(BotRightSpiral, [TopRightSpiral(1,end); BotRightSpiral(2,end)]);
TopRightSpiral = horzcat(TopRightSpiral, [TopRightSpiral(1,end); BotRightSpiral(2,end)]);


%               *Terminals*
%      This we can expt with.  I started with an extra dz down from L/2

% BotLeft
BotLeftSpiral = horzcat([BotLeftSpiral(1,1); -(L/2)], BotLeftSpiral);

% TopRight Outside via align with BotLeft -- DONT MODIFY (it's the above reflected over x axis)
TopRightSpiral = horzcat([-BotLeftSpiral(1,1); BotLeftSpiral(2,1)], TopRightSpiral);


%               *Diagnostic graphs*
% % Used to plot the spirals on top of eachother.
% spacing = 3;
% 
% figure;
% hold on;
% plot3(TopRightSpiral(1,:),TopRightSpiral(2,:),spacing*ones(length(TopRightSpiral)));
% plot3(TopLeftSpiral(1,:),TopLeftSpiral(2,:),spacing*ones(length(TopLeftSpiral)));
% 
% plot3(BotRightSpiral(1,:),BotRightSpiral(2,:),-spacing*ones(length(BotRightSpiral)));
% plot3(BotLeftSpiral(1,:),BotLeftSpiral(2,:),-spacing*ones(length(BotLeftSpiral)));
% hold off;


%% Wrap em up

TopRightSpiral_cyl = zeros(3,size(TopRightSpiral,2));
BotRightSpiral_cyl = zeros(3,size(BotRightSpiral,2));
TopLeftSpiral_cyl  = zeros(3,size(TopLeftSpiral,2));
BotLeftSpiral_cyl  = zeros(3,size(BotLeftSpiral,2));

cyls ={TopRightSpiral_cyl, BotRightSpiral_cyl, TopLeftSpiral_cyl, BotLeftSpiral_cyl};
% flip BotSpirals - they iterate in opposite direction
flats = {TopRightSpiral, flip(BotRightSpiral,2), TopLeftSpiral, flip(BotLeftSpiral,2)};
carts = cell(1,4);

PCBs = {[],[],[],[]};

for ii=1:length(cyls)
    cyl = cyls{ii};
    flat = flats{ii};
    cart = carts{ii};
    PCB = PCBs{ii};
    
    % cyl = cyl(r,f,z)
    cyl(1,:) = R(ii)*ones(1,length(flat));
    cyl(2,:) = flat(1,:)./R;
    cyl(3,:) = flat(2,:);
    
    [cart(1,:), cart(2,:)] = pol2cart(cyl(2,:), cyl(1,:));
    if mod(ii, 2)==0
        cart(1,:) = cart(1,:) - SubstrateThickness/2;
    elseif mod(ii,2)==1
        cart(1,:) = cart(1,:) + SubstrateThickness/2;
    end
    
    % PCB = PCB(x,y)
    PCB(1,:) = flat(1,:);
    PCB(2,:) = flat(2,:);
    
    cyls{ii} = cyl;
    PCBs{ii} = PCB;
    carts{ii} = cart;
end

% put em together

FinalSpiral = [cyls{1}, cyls{2}, cyls{3}, cyls{4}];     % FS(R, F, Z)

[FinalSpiral_cart(1,:), FinalSpiral_cart(2,:), FinalSpiral_cart(3,:)] = pol2cart(FinalSpiral(2,:), FinalSpiral(1,:), FinalSpiral(3,:)); % FS_c(x,y,z)

figure;
plot3(FinalSpiral_cart(1,:), FinalSpiral_cart(2,:), FinalSpiral_cart(3,:));

    

%% Export Data for PCB design

save(PCBfile, 'PCBs');
        




