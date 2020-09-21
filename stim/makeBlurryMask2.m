% makeBlurryMask.m
%
%      usage: makeBlurryMask2(width,height)
%         by: taosheng liu & m.y. Gong
%       date: 11/16/07
%    purpose: make a circular mask with blurry edges with cosine profile,
%             this makes a mask with more visibility than a Gaussian; this
%             version add an inner blurry edge

function m = makeBlurryMask2(width,height,innerR,outerEdge,innerEdge,xDeg2pix,yDeg2pix)

%It works if width<>height, but we're too humble to allow it to. Only use
%it if you know what you're doing (comment out the next 3 lines).
if width~=height
    error('the blurry mask can only be circlur for now')
end

% defaults for xDeg2pix
if ieNotDefined('xDeg2pix')
  if isempty(mglGetParam('xDeviceToPixels'))
    disp(sprintf('(mglMakeGrating) mgl is not initialized'));
    return
  end
  xDeg2pix = mglGetParam('xDeviceToPixels');
end

% defaults for yDeg2pix
if ieNotDefined('yDeg2pix')
  if isempty(mglGetParam('yDeviceToPixels'))
    disp(sprintf('(mglMakeGrating) mgl is not initialized'));
    return
  end
  yDeg2pix = mglGetParam('yDeviceToPixels');
end

% get size in pixels

widthPixels = round(width*xDeg2pix);
heightPixels = round(height*yDeg2pix);
widthPixels = widthPixels + mod(widthPixels+1,2);   %this make it an odd number
heightPixels = heightPixels + mod(heightPixels+1,2);

% get a grid of x and y coordinates that has 
% the correct number of pixels
x = -width/2:width/(widthPixels-1):width/2;
y = -height/2:height/(heightPixels-1):height/2;
[xMesh,yMesh] = meshgrid(x,y);
m=ones(size(xMesh));

dis=sqrt(xMesh.^2+yMesh.^2);
%make a blurry outer edge
m(dis>=width/2)=0;
edgeOut_idx= dis>=width/2-outerEdge&dis<width/2; %index to points lie between outer radius and outer radius-edge
dis_to_edge = dis(edgeOut_idx)-(width/2-outerEdge); %calculate the actual distance 
dis_to_edge(dis_to_edge < 0) = 0;
m(edgeOut_idx) = (cos(dis_to_edge/outerEdge*pi)+1)/2;

%make a blurry inner edge
m(dis<=innerR)=0;
edgeIn_idx= dis<=innerR/2+innerEdge&dis>innerR/2; %index to points lie between outer radius and outer radius-edge
dis_to_edge = dis(edgeIn_idx)-(innerR/2-innerEdge); %calculate the actual distance 
dis_to_edge(dis_to_edge < 0) = 0;
m(edgeIn_idx) = (cos(dis_to_edge/innerEdge*pi)+1)/2;


return;

%some test code
xDeg2pix=40;
yDeg2pix=40;

m=mglMakeGrating(5,5,1,90,0,xDeg2pix,yDeg2pix);
m=(m+1)/2;
mask=makeBlurryMask2(5,5,1,1,0.5,xDeg2pix,yDeg2pix);
figure;
subplot(1,3,1);
imshow(m);
title('Original image');

subplot(1,3,2);
imshow(mask);
title('Mask only');

masked=m.*mask;
subplot(1,3,3);
imshow(masked);
title('Masked image');
