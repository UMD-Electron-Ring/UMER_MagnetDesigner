%%% DesignMagnetFunction.m
% Generates coordinate data for laying PCB traces.

% Input design parameters in the "Configure" section.

% See README for more details and instructions for use.

function PCBfilename = DesignMagnetFunction(a, radius)
  %% Configure. USERS CHANGE THIS SECTION FOR GENERATING DESIGNS

  PCBfilename = strcat('./PCBData/PCBdata_',num2str(a));

  L = 46.5;  % Length of magnet
  Multipole = 6;  % Sextupole
  spirals = 13;

  % EVERYTHING BELOW USERS NEED NOT CHANGE
  %% Initialize vars
  N = spirals*2+2;
  dz = L/N;
  n = Multipole/2;  % coefficent for multipole expansion

  %% Calculate F (phi) for axial conductors
  % A current sheet that produces a pure multipole field has a cosine
  % dependence with respect to phi, {K(phi) ~ cos(n*phi)}.  If one changes
  % the current density by changing the length of the conductor in the Z
  % direction, one can derive a formula that relates the length the
  % conductor needs in Z, to the conductor's azimuthal position phi.  This
  % is the equation for F seen below, F = F(Z).

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

  % On the flat printed circut,
  % R*F (Radius*phi = arclength) corresponds to the "x" axis,
  % and Z corresponds to the "y" axis

  % Top
  TopRightSpiral = [radius*FTopSpiral(spiralIdx); ZTopSpiral(spiralIdx)];
  % Bottom
  BotRightSpiral = [radius*FBotSpiral(spiralIdx); ZBotSpiral(spiralIdx)];

  %% Make rotated/reflected models of spiral

  % TopLeft: TopRight reflected over line x=0
  TopLeftSpiral = [-1 0; 0 1] * TopRightSpiral;
  % BotRight: BotLeft reflected over line x=0
  BotLeftSpiral = [-1 0; 0 1] * BotRightSpiral;

  %               *Vias*
  % TopLeft Outside via alignment
  TopLeftSpiral(2,1) = TopLeftSpiral(2,5);

  % BotRight Outside via alignment (with TopLeft)
  BotRightSpiral(1,1) = TopLeftSpiral(1,1);

  % BotLeft Outside via alignment (don't collide with BotRight)
  BotLeftSpiral(1,1) = BotLeftSpiral(1,9);

  % Align inside vias (we have to add points here, not replace)
  BotLeftSpiral = horzcat(BotLeftSpiral, ...
                         [TopLeftSpiral(1,end); BotLeftSpiral(2,end)]);
  TopLeftSpiral = horzcat(TopLeftSpiral, ...
                         [TopLeftSpiral(1,end); BotLeftSpiral(2,end)]);

  BotRightSpiral = horzcat(BotRightSpiral, ...
                          [TopRightSpiral(1,end); BotRightSpiral(2,end)]);
  TopRightSpiral = horzcat(TopRightSpiral, ...
                          [TopRightSpiral(1,end); BotRightSpiral(2,end)]);


  %               *Terminals*
  %      This we can expt with.  I started with an extra dz down from L/2

  % BotLeft
  BotLeftSpiral = horzcat([BotLeftSpiral(1,1); -(L/2)-dz], BotLeftSpiral);

  % TopRight Outside via align with BotLeft
  % DONT MODIFY (it's the above reflected over x axis)
  TopRightSpiral = horzcat([-BotLeftSpiral(1,1); BotLeftSpiral(2,1)], ...
                             TopRightSpiral);

  %% Wrap em up

  % flip BotSpirals - they iterate in opposite direction
  % This doesn't seem to be useful for printed circuit data, but it
  % may be helpful for generating 3D cylindrical data for simulation.
  PCB = {TopRightSpiral, ...
         flip(BotRightSpiral,2), ...
         TopLeftSpiral, ...
         flip(BotLeftSpiral,2)
         };
     

  %% Export Data for PCB design

  save(PCBfilename, 'PCB');
end