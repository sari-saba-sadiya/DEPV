% This program show the equiluminance colors obtained by eql6.m
% It shows both the RGB values in a Matlab figure and the actual color
% patches using MGL.
% Usage: showEqlColors('TL');
function allColors=showEqlColors(subj, varargin)
getArgs(varargin,{'useMGL=1'});

datadir = ['../data/', subj,'/eqlColor/'];
colorLabels={'Yellow','Red','Green','Blue','Pink','Orange'};
numColors=length(colorLabels);

h=figure; clf;
set(h,'Name',[subj,':RGB values for eql colors']);
for i=1:numColors
    datFile=[datadir, 'eql', colorLabels{i}, '.mat'];
    a=load(datFile);
    if i==1
        refColor1=a.refColor;
    else
        nextRefColor=a.refColor;
        if ~all(refColor1==nextRefColor)
            error('Not all colors have the same reference gray. PROBLEM');
        end
    end
    thisColor=mean(a.colorSetting);
    thisColorStd=std(a.colorSetting);
    allColors(i,:)=thisColor;
    disp(['Found ', num2str(size(a.colorSetting, 1)), ' trials for ', colorLabels{i}]);

    subplot(2,3,i);
    bar(1:3, thisColor); hold on
    errorbar(1:3, thisColor, thisColorStd, '.', 'linewidth', 2);
    set(gca,'xticklabel',{'R','G', 'B'});
    ylim([0 1]);
    title(colorLabels{i});
end
drawnow;

if useMGL
    %show the six colors on the screen via MGL
    ecc=10;
    sz=[4 4];
    thetas=linspace(0,2*pi,numColors+1);

    myscreen.autoCloseScreen = 0;
    myscreen.background = 0.01;
    myscreen.keyboard.nums = [50]; 
    myscreen.saveData= 0;
    myscreen = initScreen(myscreen);
    mglTextSet([],16,[0.6 0.6 0.6]);
    mglTextDraw('Showing all colors,', [0 0.7]);
    mglTextDraw('Press space bar to end.', [0 -0.7]);

    for i=1:numColors
        [x y]=pol2cart(thetas(i), ecc);
        mglFillOval(x, y, sz,  allColors(i,:));
    end
    mglFlush;
    %     mglWaitSecs(0.2);
    while ~mglGetKeys(myscreen.keyboard.nums(1)); mglWaitSecs(0.1); end
    mglClose;
end