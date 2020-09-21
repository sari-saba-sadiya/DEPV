function stimulus = teststimulus(stimulus,myscreen,taskIdx)

%------------------------------------
% set segment time
%------------------------------------
stimulus.fixDur=0.5;
stimulus.tarDur=1;

%------------------------------------
% set grating parametrs
%------------------------------------
stimulus.grating.size = 12;
stimulus.grating.sf = 1; % cycle/degree
stimulus.grating.angle = 15:30:175; %six orientations, 30 deg apart
stimulus.grating.contrast = logspace(log10(5),log10(88),4)/100; % logarithmatically equal
stimulus.grating.phase = [0 180]; %round(rand(1,stimulus.tarDur*10)*360); %repmat([0 180],1,round(stimulus.tarDur*5));
stimulus.grating.outerEdge = 2;
stimulus.grating.innerR = 2;
stimulus.grating.innerEdge = 1;
stimulus.xDeg2pix = mglGetParam('xDeviceToPixels');
stimulus.yDeg2pix = mglGetParam('yDeviceToPixels');

if taskIdx==1 % contrast
    for i=1:length(stimulus.grating.contrast)
        m1 = mglMakeGrating(stimulus.grating.size,stimulus.grating.size,stimulus.grating.sf,45,0);
        m2 = mglMakeGrating(stimulus.grating.size,stimulus.grating.size,stimulus.grating.sf,135,0);
        mask = makeBlurryMask2(stimulus.grating.size,stimulus.grating.size,stimulus.grating.innerR,stimulus.grating.outerEdge,stimulus.grating.innerEdge,stimulus.xDeg2pix,stimulus.yDeg2pix);
        % checkerboard
        gabor1 = sign(m1/2+m2/2);
        gabor2 = sign(-m1/2-m2/2);
        
        gabor1=myscreen.background(1)*255*(gabor1.*mask*stimulus.grating.contrast(i)+1);
        gabor2=myscreen.background(1)*255*(gabor2.*mask*stimulus.grating.contrast(i)+1);
        %         gabor1 = (sign(m1/2+m2/2).*mask+1)/2;
        %         gabor2 = (sign(-m1/2-m2/2).*mask+1)/2;
        %         gabor1(gabor1==0) = contIdx(1);gabor2(gabor2==0) = contIdx(1);
        %         gabor1(gabor1==1) = contIdx(2);gabor2(gabor2==1) = contIdx(2);
        
        stimulus.check1(i) = mglCreateTexture(gabor1);
        stimulus.check2(i) = mglCreateTexture(gabor2);
    end
elseif taskIdx==2 % orientation
    for i=1:length(stimulus.grating.angle)
        for j=1:length(stimulus.grating.phase)
            
            % -----1: grating -------%
%             m = mglMakeGrating(stimulus.grating.size,stimulus.grating.size,stimulus.grating.sf,stimulus.grating.angle(i),stimulus.grating.phase(j));
%             m = 255*(m+1)/2;
%             stimulus.gratings(i,j) = mglCreateTexture(m);
            % ------2: gabor patch ------
%             m = mglMakeGrating(stimulus.grating.size,stimulus.grating.size,stimulus.grating.sf,stimulus.grating.angle(i),stimulus.grating.phase(j));
%             win = mglMakeGaussian(stimulus.grating.size,stimulus.grating.size,stimulus.grating.size/6,stimulus.grating.size/6);
%             m = 255*(m+1)/2;
%             %             m = 255*(sign(m).*win+1)/2; % squared
%             m4(:,:,1) = m;
%             m4(:,:,2) = m;
%             m4(:,:,3) = m;
%             m4(:,:,4) = 255*win;

            % ------3: gabor with blurry mask ------
             m = mglMakeGrating(stimulus.grating.size,stimulus.grating.size,stimulus.grating.sf,stimulus.grating.angle(i),stimulus.grating.phase(j));
             mask = makeBlurryMask2(stimulus.grating.size,stimulus.grating.size,stimulus.grating.innerR,stimulus.grating.outerEdge,stimulus.grating.innerEdge,stimulus.xDeg2pix,stimulus.yDeg2pix);
%              m = 255*(m+1)/2;
%              m4(:,:,1) = m;
%              m4(:,:,2) = m;
%              m4(:,:,3) = m;
%              m4(:,:,4) = 255*mask;
             m4=myscreen.background(1)*255*(m.*mask*stimulus.grating.contrast(4)+1);
             stimulus.gratings(i,j) = mglCreateTexture(m4);
        end
    end
end

%------------------------------------
% set fixation parameters
%------------------------------------

stimulus.fixation.innerCirc = [3 3];
% stimulus.fixation.thiscolor = [.5 .5 .5];
% stimulus.fixation.size = 0.4;
% stimulus.fixation.thick = 3;
    
%------------------------------------    
% create stencil
%------------------------------------
mglStencilCreateBegin(1);
stencilSize(1) = stimulus.grating.size;
stencilSize(2) = stimulus.grating.size;
mglFillOval(0,0,stencilSize);
mglStencilCreateEnd;