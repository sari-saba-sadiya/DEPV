function colorRun(myscreen,eqlColors)

global stimulus
myscreen=initStimulus('stimulus', myscreen);

stimulus.dots.dotsize=0.1;
stimulus.dots.n=240;
stimulus.dots.R=6;
stimulus.dots.r=1.5;
stimulus.dots.color=eqlColors;

task{1}{1}.waitForBacktick=0; 
task{1}{1}.seglen=repmat(0.75,1,4);     
task{1}{1}.getResponse=0;
task{1}{1}.numTrials=1;

% ---- experimental parameters ----- %
task{1}{2}.numTrials=216; %216; %about 1/6 is for blinks so that gives 216*5/6=180 trials, 30 trials/orientation
task{1}{2}.segmin = [stimulus.tarDur 1];
task{1}{2}.segmax = [stimulus.tarDur 1.5];
task{1}{2}.segquant = [0 0.1];
task{1}{2}.getResponse = [0 1];
task{1}{2}.parameter.colorIdx=1:6; 
task{1}{2}.randVars.uniform.phaseIdx=[1 2]; 
task{1}{2}.random=1;

for phaseNum = 1:length(task{1})
    [task{1}{phaseNum} myscreen]=initTask(task{1}{phaseNum},myscreen,@startSegmentCallback,@screenUpdateCallback,@trialResponseCallback,@startTrialCallback);
end

% blink trials
stimulus.blinkTrialIdx=[];
stimulus.blinkTrialIdx=computerBlinks(task{1}{2}.numTrials, 4, 1);

pNum = 1;
while (pNum <= length(task{1})) && ~myscreen.userHitEsc
    [task{1} myscreen pNum] = updateTask(task{1},myscreen,pNum);
%     [task{1} myscreen] = updateTask(task{1},myscreen,1);
    myscreen = tickScreen(myscreen,task);
end
myscreen = endTask(myscreen,task);

% function to random locate dots in an annulus (note special alogrithm to
% maintain density in Cartesian coord
function stimulus = initdots(stimulus)
randLoc=rand(1,stimulus.dots.n);
stimulus.dots.radii=stimulus.dots.r+sqrt(randLoc)*(stimulus.dots.R-stimulus.dots.r);
stimulus.dots.thetas=rand(1,stimulus.dots.n)*2*pi;
[stimulus.dots.x stimulus.dots.y]=pol2cart(stimulus.dots.thetas,stimulus.dots.radii);
%----------------------------
% CALLBACKS
%----------------------------
function [task, myscreen] = startTrialCallback(task,myscreen)
global stimulus;


function [task myscreen] = startSegmentCallback(task,myscreen)
global stimulus;
myscreen.flushMode = 1; %must set it in the segment callback, a bit odd

mglClearScreen; 
switch task.thistrial.thisphase
    case 1 
        if task.thistrial.thisseg<4
            mglTextDraw('Starting in',[0 1.5]);
            mglPoints2(myscreen.topLeft(1),myscreen.topLeft(2),myscreen.pixSize,[216,8,0]) % S13 for block begining
            mglTextDraw(num2str(4-task.thistrial.thisseg),[0 -1.5]);
        end
    case 2  
        if task.thistrial.thisseg==1 && ismember(task.trialnum, stimulus.blinkTrialIdx)
            mglTextDraw('BLINK', [0 1.5]);
            mglTextDraw('BLINK', [0 -1.5]);
            mglPoints2(myscreen.topLeft(1),myscreen.topLeft(2),myscreen.pixSize,[168,8,0]) %S10
        elseif task.thistrial.thisseg==1 && ~ismember(task.trialnum, stimulus.blinkTrialIdx)    
            % draw the dots
            stimulus = initdots(stimulus);
            mglPoints2(myscreen.topLeft(1),myscreen.topLeft(2),myscreen.pixSize,[136+16*task.thistrial.colorIdx,40,0]); %S41 to S46
            mglStencilSelect(1);
            mglGluDisk(stimulus.dots.x,stimulus.dots.y,stimulus.dots.dotsize,stimulus.dots.color(task.thistrial.colorIdx,:));
            mglStencilSelect(0);
        end
end

mglFixationCross(0.6,2,0.7,[0 0]);

function [task myscreen] = screenUpdateCallback(task,myscreen)
global stimulus;


function [task, myscreen] = trialResponseCallback(task, myscreen)
global stimulus;

% figure out blink trials index
function blinkTrialIdx=computerBlinks(numTrials, avgInt, halfWindow)
possibleLength=[avgInt-halfWindow, avgInt, avgInt+halfWindow];
numBlinks=round(1.25*numTrials/avgInt);
allIntervals=randsample(possibleLength, numBlinks, true);
blinkTrialIdx=cumsum(allIntervals);



