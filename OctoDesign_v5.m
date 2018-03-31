%%% OctoDesign

% Revision History:
% 
% v3:  


%%  Scratch DELETE

% pcb length = 92.2

% 
%% Clear Vars

clear;
%% Configure

SpiralName = '24Sept15-Caddesign';
PCBfile = 'testPCB';

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

filename = strcat(SpiralName, '.txt');

dr = (SubstrateThickness/2) + (WireThickness/2);    % Total circuit thickness = 2dr
R = HousingRadius; % - (WireThickness + SubstrateThickness/2);  % IMPORTANT UNCOMMENT
RBot = HousingRadius;
RTop = HousingRadius;

N = spirals*2+2;
dz = L/N;
n = Multipole/2;  % coefficent for multipole expansion

%% Calculate F for axial conductors

Z = zeros(1,spirals);
F = zeros(1,spirals);
for ii=1:spirals
    Z(ii) = L/2-dz*ii;
    F(ii) = 1/n * asin(1 - (2*Z(ii)/(a * L))^2);

end


ZTopSpiral = [L/2-dz*0, Z];
FTopSpiral = [F, 1/n * asin(1 - (2*(L/2-dz*(spirals+1))/(a * L))^2)]; 

ZBotSpiral = [Z, L/2-dz*(spirals+1)];
FBotSpiral = [1/n * asin(1 - (2*(L/2-dz*0)/(a * L))^2), F]; 

% Fdeg = F.*180./pi;


%% Plot Cylindrical

% Zplot = [-Z, Z, Z, -Z];             
% Fplot = [F, F, pi/2-F, pi/2-F];
%
% [x,y,z] = pol2cart(Fplot, R*ones(1,80), Zplot);


ZTopPlot = [-ZTopSpiral, Z, Z, -Z];             
FTopPlot = [FTopSpiral, F, pi/n-F, pi/n-F]; % Fplot( BL TL TR BR )

ZBotPlot = [-ZBotSpiral, -Z, Z, Z];
FBotPlot = [FBotSpiral, pi/n-F, pi/n-F, F]; % FBotPlot( BL BR TR TL)

[xTop,yTop,zTop] = pol2cart(FTopPlot, R*ones(1,spirals*4+1), ZTopPlot);
[xBot,yBot,zBot] = pol2cart(FBotPlot, R*ones(1,spirals*4+1), ZBotPlot);

% figure
% scatter3(xTop,yTop,zTop);


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
R_cur = [RTop, RBot, RTop, RBot];

PCBs = {[],[],[],[]};

for ii=1:length(cyls)
    cyl = cyls{ii};
    flat = flats{ii};
    cart = carts{ii};
    PCB = PCBs{ii};
    
    % cyl = cyl(r,f,z)
    cyl(1,:) = R_cur(ii)*ones(1,length(flat));
    cyl(2,:) = flat(1,:)./R;
    cyl(3,:) = flat(2,:);
    
    [cart(1,:), cart(2,:)] = pol2cart(cyl(2,:), cyl(1,:));
    if mod(ii, 2)==0
        cart(1,:) = cart(1,:) - SubstrateThickness/2;
    elseif mod(ii,2)==1
        cart(1,:) = cart(1,:) + SubstrateThickness/2;
    end
    
    % PCB = PCB(x,y)
    PCB(1,:) = flat(1,:)./R.*R_cur(ii);
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

    

%% Export Data for Simulation

csvwrite(filename, FinalSpiral);

%% Export Data for PCB design

save(PCBfile, 'PCBs');

%% TODO: Modified Data for simulation:  top is translated up from bottom 
%        with same radius,  rather than top and bottom being at two 
%        different radii

docNode = com.mathworks.xml.XMLUtils.createDocument('magnet');  % XML obj

% Magnet Attributes
magnet = docNode.getDocumentElement;
magnet.setAttribute('version','A1');

% Create Spirals
startSeg = {'arc','arc','line','arc'};
TopBot =   {'top','bot','top','bot'};
for ii=1:length(cyls)
    cur_node = docNode.createElement('spiral');
    cur_node.setAttribute('startType',startSeg{ii});
    cur_node.setAttribute('TopBot',TopBot{ii});
    magnet.appendChild(cur_node);
    
    % Create Points
    for jj=1:length(cyls{ii})
        point_node = docNode.createElement('point');
        
        point_node.setAttribute('index', num2str(jj));
        % is it a terminal point?
        if (ii==1 && jj==1) 
            point_node.setAttribute('place','start');
        elseif (ii==4 && jj==length(cyls{4}))
            point_node.setAttribute('place','end');
        end
        
        cur_node.appendChild(point_node);
        
        % Create x,y,z,f,r
        names = {'x','y','z','f','r'};
        vals  = {carts{ii}(1,jj), carts{ii}(2,jj), cyls{ii}(3,jj),...
                 cyls{ii}(2,jj), cyls{ii}(1,jj) };   
        for kk=1:5
            crd_node = docNode.createElement( names{kk} );
            crd_node.appendChild(...
                docNode.createTextNode(num2str( vals{kk} )));
            
            point_node.appendChild(crd_node);
        end
        clear names vals crd_node % TODO: getting rid of crd_node maybe bad

    end
    clear point_node

end
clear topbot cur_node

xmlwrite('test2.xml',docNode);
        




