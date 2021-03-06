function oriRun(myscreen)

% global fixStimulus
% fixStimulus.fixWidth = 0.4;
% fixStimulus.responseTime = 2;
% fixStimulus.interColor = myscreen.background;
% fixStimulus.responseColor = [0.4 0.4 0];
% fixStimulus.correctColor = [0 0.3 0];
% fixStimulus.incorrectColor =[0.4 0 0];
% [task{1} myscreen] = fixStairInitTask(myscreen);

global stimulus
myscreen=initStimulus('stimulus', myscreen);
stimulus=teststimulus(stimulus,myscreen,2);

task{1}{1}.waitForBacktick=0; 
task{1}{1}.seglen=repmat(0.75,1,4);     
task{1}{1}.getResponse=0;
task{1}{1}.numTrials=1;

% ---- experimental parameters ----- %
task{1}{2}.numTrials=216; %about 1/6 is for blinks so that gives 216*5/6=180 trials, 30 trials/orientation
task{1}{2}.segmin = [stimulus.tarDur 1];
task{1}{2}.segmax = [stimulus.tarDur 1.5];
task{1}{2}.segquant = [0 0.1];
task{1}{2}.getResponse = [0 1];
task{1}{2}.parameter.oriIdx=1:6; 
task{1}{2}.randVars.uniform.phaseIdx=[1 2]; 
task{1}{2}.random=1;

for phaseNum = 1:length(task{1})
    [task{1}{phaseNum} myscreen]=initTask(task{1}{phaseNum},myscreen,@startSegmentCallback,@screenUpdateCallback,@trialResponseCallback,@startTrialCallback);
end

stimulus.blinkTrialIdx=computerBlinks(task{1}{2}.numTrials, 4, 1);

pNum = 1;
while (pNum <= length(task{1})) && ~myscreen.userHitEsc
    [task{1} myscreen pNum] = updateTask(task{1},myscreen,pNum);
%     [task{1} myscreen] = updateTask(task{1},myscreen,1);
    myscreen = tickScreen(myscreen,task);
end
myscreen = endTask(myscreen,task);


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
            mglPoints2(myscreen.topLeft(1),myscreen.topLeft(2),myscreen.pixSize,[40,248,0]) % S242
        elseif task.thistrial.thisseg==1 && ~ismember(task.trialnum, stimulus.blinkTrialIdx)    
            thisGrating=stimulus.gratings(task.thistrial.oriIdx,task.thistrial.phaseIdx);
            if task.thistrial.phaseIdx == 1
                mglPoints2(myscreen.topLeft(1),myscreen.topLeft(2),myscreen.pixSize,[8+16*task.thistrial.oriIdx,8,0]) %S1 to S6
            else
                mglPoints2(myscreen.topLeft(1),myscreen.topLeft(2),myscreen.pixSize,[72+16*task.thistrial.oriIdx,24,0]) %S21 to S26
            end
            mglBltTexture(thisGrating,[0 0]);
            %mglTextDraw(['ori ',num2str(task.thistrial.oriIdx),' phase ',num2str(task.thistrial.phaseIdx)],[0 -10]);
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



