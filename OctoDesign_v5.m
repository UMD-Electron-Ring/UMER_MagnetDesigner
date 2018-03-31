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


SeqRect = zeros(1,20);
for i=0:19
    SeqRect(4*i+1) = i + 1;      % BL
    SeqRect(4*i+2) = i + 21;     % TL
    SeqRect(4*i+3) = i + 41;     % TR
    SeqRect(4*i+4) = i + 61;     % BR
end

SeqSpiral = zeros(1,spirals*4+1);
for i=0:spirals-1
    SeqSpiral(4*i+1) = i + 1;      % BL  Fplot(1:21)
    SeqSpiral(4*i+2) = i + 1*spirals + 2;     % TL  Fplot(22:41)
    SeqSpiral(4*i+3) = i + 2*spirals + 2;     % TR
    SeqSpiral(4*i+4) = i + 3*spirals + 2;     % BR
end
SeqSpiral(spirals*4+1) = spirals + 1;


figure;
plot3(xTop(SeqSpiral),yTop(SeqSpiral),zTop(SeqSpiral));
figure;
plot3(xBot(SeqSpiral),yBot(SeqSpiral),zBot(SeqSpiral));

%% Make 'em flat

% Function [x, y] = MakeItFlat(Fplot, Zplot, R)

YTopflat = Yo + ZTopPlot;
XTopflat = Xo + R*FTopPlot;

TopRightSpiral_flat = [XTopflat(SeqSpiral); YTopflat(SeqSpiral)];

figure
plot(TopRightSpiral_flat(1,:),TopRightSpiral_flat(2,:));

% Bottom

YBotflat = Yo + ZBotPlot;
XBotflat = Xo + R*FBotPlot;

BotRightSpiral_flat = [XBotflat(SeqSpiral); YBotflat(SeqSpiral)];

figure
plot(BotRightSpiral_flat(1,:),BotRightSpiral_flat(2,:));

%% Make rotated/reflected models of spiral

% TopLeft: TopRight reflected over x=0
TopLeftSpiral_flat = [-1 0; 0 1] * TopRightSpiral_flat;

% BotRight: BotLeft reflected over x=0
BotLeftSpiral_flat = [-1 0; 0 1] * BotRightSpiral_flat;

figure;
hold on;
plot(TopRightSpiral_flat(1,:),TopRightSpiral_flat(2,:));
plot(TopLeftSpiral_flat(1,:),TopLeftSpiral_flat(2,:));
hold off

figure;
hold on;
plot(BotRightSpiral_flat(1,:),BotRightSpiral_flat(2,:));
plot(BotLeftSpiral_flat(1,:),BotLeftSpiral_flat(2,:));
hold off;

%% Make modifications on flat model
% --- IMPORTANT: BotRight and TopLeft vias aren't aligned as on printed circuit.
% ---            Really TopLeft and TopRight outside vias should be aligned
% ---            (so BotRight and TopLeft are misaligned in y by dz). The wire
% ---            width makes up for this in real life.

%               *Alignment*
% TopLeft Outside via alignment
TopLeftSpiral_flat(2,1) = TopLeftSpiral_flat(2,5);

% BotRight Outside via alignment (with TopLeft)
BotRightSpiral_flat(1,1) = TopLeftSpiral_flat(1,1);

% TENTATIVE: BotLeft Outside via alignment (don't collide with BotRight)
BotLeftSpiral_flat(1,1) = BotLeftSpiral_flat(1,9);

% Align inside vias (we have to add points here, not replace)
BotLeftSpiral_flat = horzcat(BotLeftSpiral_flat, [TopLeftSpiral_flat(1,end); BotLeftSpiral_flat(2,end)]);
TopLeftSpiral_flat = horzcat(TopLeftSpiral_flat, [TopLeftSpiral_flat(1,end); BotLeftSpiral_flat(2,end)]);

BotRightSpiral_flat = horzcat(BotRightSpiral_flat, [TopRightSpiral_flat(1,end); BotRightSpiral_flat(2,end)]);
TopRightSpiral_flat = horzcat(TopRightSpiral_flat, [TopRightSpiral_flat(1,end); BotRightSpiral_flat(2,end)]);


%               *Terminals*
%      This we can expt with.  I started with an extra dz down from L/2

% BotLeft
BotLeftSpiral_flat = horzcat([BotLeftSpiral_flat(1,1); -(L/2)], BotLeftSpiral_flat);

% TopRight Outside via align with BotLeft -- DONT MODIFY (it's the above reflected over x axis)
TopRightSpiral_flat = horzcat([-BotLeftSpiral_flat(1,1); BotLeftSpiral_flat(2,1)], TopRightSpiral_flat);


%               *Diagnostic graphs*

% z coords are arbitrary width
z_arb = 3;

figure;
hold on;
plot3(TopRightSpiral_flat(1,:),TopRightSpiral_flat(2,:),z_arb*ones(length(TopRightSpiral_flat)));
plot3(TopLeftSpiral_flat(1,:),TopLeftSpiral_flat(2,:),z_arb*ones(length(TopLeftSpiral_flat)));

plot3(BotRightSpiral_flat(1,:),BotRightSpiral_flat(2,:),-z_arb*ones(length(BotRightSpiral_flat)));
plot3(BotLeftSpiral_flat(1,:),BotLeftSpiral_flat(2,:),-z_arb*ones(length(BotLeftSpiral_flat)));
hold off;


%% Wrap em up

TopRightSpiral_cyl = zeros(3,size(TopRightSpiral_flat,2));
BotRightSpiral_cyl = zeros(3,size(BotRightSpiral_flat,2));
TopLeftSpiral_cyl  = zeros(3,size(TopLeftSpiral_flat,2));
BotLeftSpiral_cyl  = zeros(3,size(BotLeftSpiral_flat,2));

cyls ={TopRightSpiral_cyl, BotRightSpiral_cyl, TopLeftSpiral_cyl, BotLeftSpiral_cyl};
% flip BotSpirals - they iterate in opposite direction
flats = {TopRightSpiral_flat, flip(BotRightSpiral_flat,2), TopLeftSpiral_flat, flip(BotLeftSpiral_flat,2)};
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
        




