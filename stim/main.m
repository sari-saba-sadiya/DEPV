% main.m
%
%      usage: main(subj,session,orderIdx)
%         by: M. Gong
%       date: 06/12/19
%     session: 0 - practice session
%              1 - scanning session
%     orderIdx:1 - contrast first
%              2 - orientation first

function main(subj,session)

%------------------------------------
% Set up screen
%------------------------------------
myscreen.session = session; 
myscreen.autoCloseScreen = 0;
myscreen.saveData = -2;   % any negative value will return to save both stim and eye data

% EEG trigger
myscreen.topLeft=[-25.5,14.3]; 
myscreen.pixSize= 10; % point size

myscreen.datadir = ['../data/', subj,'/'];
if ~exist(myscreen.datadir)
    disp(['making directory: ',myscreen.datadir]);
    mkdir(myscreen.datadir);
end
eqlColors=showEqlColors(subj, 'useMGL=0');

myscreen.background = [.35 .35 .35];

% myscreen.TR = 2.2;
% myscreen.framesPerSecond = 60;
% 
% myscreen.datadir = [myscreen.curDir,'/../data/',myscreen.subj,'/scanRun/'];
% myscreen.monitorGamma=1.4;

if myscreen.session == 0 % practice
    myscreen.numBlocks = 6; %10;
    myscreen.keyboard.nums = [126 127];
    myscreen.displayname = 'UltraWide';

elseif myscreen.session == 1 % EEG Run
    myscreen.numBlocks = 6;
    myscreen.keyboard.nums = [126 127]; %[27 29];
    myscreen.displayname='ViewPixxEEG';

    %myscreen.framesPerSecond = 120;
    myscreen.displayWidth = 52.1;
    myscreen.displayHeight = 29.4;
    myscreen.distance = 57;
end
% 
% if ~exist(myscreen.datadir)
%     mkdir(myscreen.datadir);
% end

%------------------------------------
% Initialize the screen %
%------------------------------------
myscreen = initScreen(myscreen);

for runi = 1:myscreen.numBlocks
    %------------------------------------
    %          instruction
    %------------------------------------
    mglClearScreen();mglFlush;
    mglTextSet('Geneva',18,[1 1 1]);
    
    if isodd(runi)
        mglTextDraw('Orientation run', [0 1]);
    else
        mglTextDraw('Color run', [0 1]);
    end
    mglTextDraw('Press any key to start next block', [0 -0.5]);
    mglFlush;
    while ~mglGetKeys([myscreen.keyboard.nums]); end
    mglClearScreen();mglFlush;
    mglClearScreen();mglFlush;
    
    if isodd(runi)
        myscreen.type='Ori';
        oriRun(myscreen);
    else
        myscreen.type='Clr';
        colorRun(myscreen,eqlColors);
    end
            
%                 mglTextDraw('Contrast run', [0 1]);
%                 mglTextDraw('Press any key to start the experiment', [0 -0.5]);
%                 mglFlush;
%                 while ~mglGetKeys([myscreen.keyboard.nums]); end
%                 mglClearScreen();
%                 mglFlush;
%                 
%                 contRun(myscreen);
%             
    mglFlush;mglWaitSecs(1.0);
    mglClearScreen();mglFlush;
end


mglClearScreen();
mglFlush;
mglTextDraw('Thank you for the participation', [0 0]);
mglFlush;
mglWaitSecs(2.0);
mglClearScreen();
mglFlush;
            
mglClose

