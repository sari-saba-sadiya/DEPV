% Program to set equiluminance colors. This code set six colors (as in
% colorLabels) to be equal to a fixed gray (fixedColor) via heterochromatic
% flicker method.           
% Usage: eql6('subjInitial');
% 12/16/2019, written by TSL based on old code

function eql6(subj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
myscreen.autoCloseScreen = 0;
myscreen.datadir = ['../data/', subj,'/eqlColor/'];
if ~exist(myscreen.datadir)
    disp(['making directory: ',myscreen.datadir]);
    mkdir(myscreen.datadir);
end
myscreen.background = 0.01;
% myscreen.keyboard.nums = [19 20 21 22 24]; %[84 85 86 87 88];

myscreen.keyboard.nums = [126 127 50]; %[84 85 86 87 88];
myscreen.saveData= 0;
myscreen = initScreen(myscreen);

fixedColor=[0.35 0.35 0.35];
startingColors=[ 0.7 0.7 0; 1 0 0; 0 0.5 0; 0 0.7 1; 0.7 0 0.7; 0.4 0.1 0];
colorLabels={'Yellow','Red','Green','Blue','Pink','Orange'};

t=0:.1:150;
mglTextSet('color',28);
for i=1:length(startingColors)
    sound(0.7*sin(2*pi*t));
    mglTextDraw(colorLabels{i}, [0 1.5]);
    mglTextDraw('Press spacebar for next trial.',[0,-0.5]);
    mglTextDraw('Up arrow: increase; Down arrow: decrease; Space bar: set.',[0,-2]);
    mglFlush;
    mglWaitSecs(0.2);
    while ~mglGetKeys(myscreen.keyboard.nums(3)); mglWaitSecs(0.1); end
    mglFlush;
    mglWaitSecs(1);
    eql(myscreen,fixedColor,startingColors(i,:),colorLabels{i});
end

for i=1:2
    sound(sin(1.5*pi*t));
end
mglClearScreen; mglFlush;
mglTextDraw('Please get the experimenter.',[0 0]);
mglFlush;
pause(6);
mglClose;

%isoluminance program to set two colors to psychophyiscally isoluminant
%via flicker minization
%The task is to control the brightness of the test color to minimize
%flicker, while the reference color is held fixed. The procedure uses
%the method of adjustment, with the following responses:
%1:decrease 1 step; 2:increase 1 step; 3:half step size; 4: double step size
%5:end this trial (total 4 trials: 2 in LVF, 2 in RVF)
function eql(myscreen,fixedColor,startingColor,colorLabel)
global stimulus

% stimulus.check.colorStarter=[1 0 0;0 1 0;0 0 1;1 0.85 0;1 0 1;0.4 0.1 0;0 1 1];
stimulus.check.colorV0=startingColor; %stimulus.check.colorStarter(colorIdx,:);

stimulus.check.colorF=fixedColor; %gray level of the fixed stimulus
stimulus.check.colorV=stimulus.check.colorV0;  %varialbe color subjects control
% stimulus.check.colorInc0=.05*(stimulus.check.colorV0>0);
% stimulus.check.colorInc=stimulus.check.colorInc0;
stimulus.check.colorInc = (stimulus.check.colorV0>0)/128; %max(stimulus.check.colorInc0)/9; % only using minimum step size for simplicity
stimulus.check.colorSetting=[];
stimulus.stencilPos = 0; %8;
stimulus.stencilSize = 12;
stimulus.check.width=1.8; %2;
stimulus.check.height=1.8; %2;
stimulus.check.colorS=[];
stimulus.check.inner=1.5;
stimulus.numSeg=10000;
stimulus.fixationColor=[1 1 1];
myscreen = initStimulus('stimulus',myscreen);

task{1}.numTrials = 2; %4
task{1}.seglen = [.7 .06*ones(1,stimulus.numSeg)];
task{1}.getResponse = [0 ones(1,stimulus.numSeg)];
task{1}.waitForBacktick = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialze tasks and stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stimulus = myInitStimulus(stimulus,task,myscreen);

% initialze tasks
for phaseNum = 1:length(task)
    [task{phaseNum},myscreen] = initTask(task{phaseNum},myscreen,@startSegmentCallback,@trialStimulusCallback,@responseCallback);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set which phase is active
phaseNum = 1;
while (phaseNum <= length(task)) && ~myscreen.userHitEsc
    % updatethe task
    [task myscreen phaseNum] = updateTask(task,myscreen,1);
    % flip screen
    myscreen = tickScreen(myscreen,task);
end
% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

disp(['Reference color: [',num2str(stimulus.check.colorF),']']);
disp(['Equiluminant ',colorLabel,':']);
disp(num2str(stimulus.check.colorSetting));

refColor=stimulus.check.colorF;
colorSetting=stimulus.check.colorSetting;
save([myscreen.datadir,'/','eql',colorLabel], 'refColor', 'colorSetting');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task,myscreen)

global stimulus;
chkX=stimulus.check.X;
chkY=stimulus.check.Y;
myscreen.flushMode = 1;
mglClearScreen;

mglStencilSelect(1);
if isodd(task.thistrial.thisseg)
    mglQuad(chkX, chkY, stimulus.check.colorS, 1);
else
    mglQuad(chkX, chkY, stimulus.check.colorSalt, 1);
end
mglStencilSelect(0);
mglFillOval(stimulus.stencilPos,0,[stimulus.check.inner,stimulus.check.inner],myscreen.background);
mglFixationCross(.5,2,stimulus.fixationColor);
if any(stimulus.fixationColor~=[1 1 1])
    stimulus.fixationColor=[1 1 1];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to display stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = trialStimulusCallback(task,myscreen)
global stimulus;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init the stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [stimulus task myscreen] = myInitStimulus(stimulus,task,myscreen)
% create stencil
mglStencilCreateBegin(1);
% get position of first cutout
xpos = stimulus.stencilPos;
ypos = 0;
% and size of the oval
stencilSize(1) = stimulus.stencilSize;
stencilSize(2) = stimulus.stencilSize;
% and draw that oval
mglFillOval(xpos,ypos,stencilSize);
% now shift over the oval to the otherside and draw it there too
xpos = -stimulus.stencilPos;
mglFillOval(xpos,ypos,stencilSize);
mglStencilCreateEnd;
mglClearScreen;

%draw checker board
stimulus.check.X=[]; stimulus.check.Y=[];
xcpos=-stimulus.stencilSize/2:stimulus.check.width:stimulus.stencilSize/2;
%chkx=stimulus.stencilPos+xcpos;
ycpos=-stimulus.stencilSize/2:stimulus.check.height:stimulus.stencilSize/2;
%chky=ycpos;
[xc, yc]=meshgrid(xcpos,ycpos);
pol=1;
for i=1:size(xc,1)
    if i>1
        pol = -1* pols(i-1, 1);
    end
    for j=1:size(xc,2)
        stimulus.check.X=[stimulus.check.X [xc(i,j) xc(i,j)+stimulus.check.width xc(i,j)+stimulus.check.width xc(i,j)]'];
        stimulus.check.Y=[stimulus.check.Y [yc(i,j) yc(i,j) yc(i,j)+stimulus.check.height yc(i,j)+stimulus.check.height]'];
        pols(i, j) = pol;
        pol= -1*pol;
        if pol==1
            stimulus.check.colorS=[stimulus.check.colorS stimulus.check.colorF'];
        elseif pol==-1
            stimulus.check.colorS=[stimulus.check.colorS stimulus.check.colorV'];
        end
    end
end
stimulus.check.colorSalt=[stimulus.check.colorS(:,2:end), stimulus.check.colorS(:,1)];


function [task, myscreen]=responseCallback(task,myscreen)
global stimulus;

colorVIdx=find(ismember(stimulus.check.colorS',stimulus.check.colorV,'rows'));
colorVIdxAlt=find(ismember(stimulus.check.colorSalt',stimulus.check.colorV,'rows'));
switch task.thistrial.whichButton
    case 1,
        if max(stimulus.check.colorV-stimulus.check.colorInc)<=0
            stimulus.fixationColor=[1 0 0];
        else
            stimulus.check.colorV=stimulus.check.colorV-stimulus.check.colorInc;
            stimulus.check.colorS(:,colorVIdx)=repmat(stimulus.check.colorV',1,length(colorVIdx));
            stimulus.check.colorSalt(:,colorVIdxAlt)=repmat(stimulus.check.colorV',1,length(colorVIdxAlt));
        end
    case 2,
        if max(stimulus.check.colorV+stimulus.check.colorInc)>=1
            stimulus.fixationColor=[0 1 0];
        else
            stimulus.check.colorV=stimulus.check.colorV+stimulus.check.colorInc;
            stimulus.check.colorS(:,colorVIdx)=repmat(stimulus.check.colorV',1,length(colorVIdx));
            stimulus.check.colorSalt(:,colorVIdxAlt)=repmat(stimulus.check.colorV',1,length(colorVIdxAlt));
        end
    case 3,
        stimulus.check.colorSetting(task.trialnum,:)=stimulus.check.colorV;
        stimulus.check.colorV=stimulus.check.colorV0;
        stimulus.check.colorS(:,colorVIdx)=repmat(stimulus.check.colorV',1,length(colorVIdx));
        stimulus.check.colorSalt(:,colorVIdxAlt)=repmat(stimulus.check.colorV',1,length(colorVIdxAlt));
        task=jumpSegment(task,inf);
end

