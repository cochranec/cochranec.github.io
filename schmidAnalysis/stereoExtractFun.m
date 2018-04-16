function stereoExtractFun(inFile, bootStrap)
% function stereoExtractFun
% Calculates Schmid Factors for a hexagonal close packed structure based on
% user inputs for a stereographic projection, such as that produced by
% CaRiNe software.
% Input is the filename of the file to be interpreted.
% Output is the Schmid factors of the primary slip systems in a HCP crystal
% using the crystal structure of zirconium, and uncertainty values
% predicted using a bootstrapping approach.

% If you don't care about uncertainties, you can run function with a second
% argument (any value), which will ignore the uncertainty calculation.

if nargin < 2
    bootStrap = 1;
end

CS = crystalSymmetry('6/mmm', [3.232 3.232 5.147], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'Alpha', 'color', 'light red');

[XY, scale] = getCoords(inFile);
o = getOrient(XY, scale, CS);

%% Calculate Schmid factors for different slip systems

loadVector = getLoadVector;

% Predict relative uncertainties using a bootstrapping technique
if (bootStrap)
    spread = 7;
    tauList = zeros(spread, 3);
    prismtau = calcSchmid(Miller(1,0,-1,0,CS,'hkl'), Miller(1,1,-2,0,CS,'uvw'), loadVector, o);
    basaltau = calcSchmid(Miller(0,0,0,1,CS,'hkl'), Miller(1,1,-2,0,CS,'uvw'), loadVector, o);
    pyramtau = calcSchmid(Miller(1,0,-1,1,CS,'hkl'), Miller(1,1,-2,3,CS,'uvw'), loadVector, o);
    fprintf('Calculating uncertainties ... \n')
    for i = 1:100
        o = getOrient(XY+randn(2,2)*spread, scale, CS);
        prtau = calcSchmid(Miller(1,0,-1,0,CS,'hkl'), Miller(1,1,-2,0,CS,'uvw'), loadVector, o);
        batau = calcSchmid(Miller(0,0,0,1,CS,'hkl'), Miller(1,1,-2,0,CS,'uvw'), loadVector, o);
        pytau = calcSchmid(Miller(1,0,-1,1,CS,'hkl'), Miller(1,1,-2,3,CS,'uvw'), loadVector, o);
        %fprintf('%5.3f %5.3f %5.3f\n', max(prismtau), max(basaltau), max(pyramtau));
        tauList(i,:) = [max(prtau) max(batau) max(pytau)];
    end
    tauUnc = std(tauList);
    
    fprintf('Schmid Factors:\n');
    fprintf('   Prism       Basal       Pyram\n');
    fprintf('%5.3f±%5.3f %5.3f±%5.3f %5.3f±%5.3f\n', max(prismtau), tauUnc(1), max(basaltau), tauUnc(2), max(pyramtau), tauUnc(3));
else
    prismtau = calcSchmid(Miller(1,0,-1,0,CS,'hkl'), Miller(1,1,-2,0,CS,'uvw'), loadVector, o);
    basaltau = calcSchmid(Miller(0,0,0,1,CS,'hkl'), Miller(1,1,-2,0,CS,'uvw'), loadVector, o);
    pyramtau = calcSchmid(Miller(1,0,-1,1,CS,'hkl'), Miller(1,1,-2,3,CS,'uvw'), loadVector, o);
    fprintf('Schmid Factors:\n');
    fprintf('Prism  Basal  Pyram\n');
    fprintf('%5.3f  %5.3f  %5.3f\n', max(prismtau), max(basaltau), max(pyramtau));
end
end

function [XY, scale] = getCoords(inFile)
%%
f=figure(1); clf
[mm, mp]  = imread(inFile);
set(f,'WindowStyle','normal');
if ~isempty(mp)
    mm = ind2rgb(mm,mp);
end
imshow(mm)

%disp('Click Centre, Top, and Left.');
%R = ginput(3);
[d1 d2 d3] = size(mm);
R = [1 1; 1 0; 0 1] * d1 / 2;
r1 = R(1,:);
r2 = R(2,:);
r3 = R(3,:);
yscale = r3(1) - r1(1);
xscale = r2(2) - r1(2);

% yscale = r3(1) - r1(1);
% xscale = r2(2) - r1(2);
RR = zeros(2,2);

disp('Click any (0001) orientation.');
RR(1,:) = ginput(1);
disp('Click any (10-10) orientation.');
RR(2,:) = ginput(1);

set(f,'WindowStyle','docked')
XY = (RR - repmat(r1,length(RR), 1));
scale = mean([yscale xscale]);
end

function o = getOrient(XY, scale, CS)
X = XY(:,2) ./ scale;
Y = XY(:,1) ./ scale;
x = 2 .* X ./ (1 + X.^2 + Y.^2);
y = 2 .* Y ./ (1 + X.^2 + Y.^2);
z = -(-1 + X.^2 + Y.^2) ./ (1 + X.^2 + Y.^2);
v = vector3d(x,y,z);

[e2,e1] = v(1).polar;

% Iterate over possible rotations to find the one that results in the
% projected vector aligning best with the measured one.
m = Miller(-1,1,0,0,CS);

eRange = [-180:1:180];
o = orientation('Euler',e1+pi/2,e2,eRange.*degree,CS);
overlap = v(2).dot(o*m);
maxVal = eRange(overlap==max(overlap));

eRange = maxVal-5:.001:maxVal+5;
o = orientation('Euler',e1+pi/2,e2,eRange.*degree,CS);
overlap = v(2).dot(o*m);
maxVal = eRange(overlap==max(overlap));

o = orientation('Euler',e1+pi/2,e2,maxVal*degree,CS);

% fprintf('Euler Angles are:\ne1: %.1f\ne2: %.1f\ne3: %.1f\n',(e1+pi/2)/degree, e2/degree,maxVal);
end

function tau = calcSchmid(mPlane, mDir, loadVector, grainOrient)
slipPlaneType = symmetrise(mPlane);
slipDirecType = symmetrise(mDir);

a = slipPlaneType;
N = length(slipDirecType);
slipPlane = a( ceil( (1:N*length(a))/N ) );
slipDirection = repmat(slipDirecType,length(slipPlaneType),1);
tau = dot(normalize(grainOrient*slipPlane),loadVector) .* dot(normalize(grainOrient*slipDirection),loadVector);
tau(abs(round(dot(vector3d(slipDirection), vector3d(slipPlane)))) > 0) = [];

end

function loadVect = getLoadVector()
f = figure();
plot(zvector,'antipodal')
annotate(zvector,'label',{'Z'},'BackgroundColor','w','antipodal')
annotate(yvector,'label',{'Y'},'BackgroundColor','w','antipodal')
annotate(xvector,'label',{'X'},'BackgroundColor','w','antipodal')
answer = questdlg('Loading along which orientation?','Set Loading Orientation','X','Y','Z','Z');
% Handle response
switch answer
    case 'X'
        loadVect = xvector;
    case 'Y'
        loadVect = yvector;
    case 'Z'
        loadVect = zvector;
end
close(f)
end