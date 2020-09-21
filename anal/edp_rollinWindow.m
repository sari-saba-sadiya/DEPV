% usage: Run SVM with sliding window
% by: Sari Saba-Sadiya
% date: 3/1/2020
% purpose:
function stats=edp_rollinWindow(varargin)

%addpath(genpath('~/matlab/libsvm/matlab'))

getArgs(varargin,{'subjID=[]','filename=oriErpAlpha','nCond=6','T0=200','windSleeve=4'});

condColorLegend = { 'yellow', 'red', 'green', 'blue', 'pink', 'orange' };
condColor = { [255,239,0], [255, 0, 0], [60, 190, 60], [60 60 190], [255 60 255], [255, 190, 0] };
condColor = cellfun(@(c) c/255, condColor, 'UniformOutput', false);

% parameters to set
nBlocks = 8; % # of blocks for cross-validation
testProp = (nBlocks - 1)/nBlocks; % training proportion

% Get subjects
if ~isempty(subjID)
    subjects{1}=subjID;
else
    dataDir = '../data/';
    % ----- find subject directory ----%
    disp(['Use data directory: ',dataDir]);
    sessions=dir(dataDir);
    subjects={};
    for iSubj=1:numel(sessions)
        if length(sessions(iSubj).name) == 3
            subjects=cellcat(subjects,sessions(iSubj).name);
        end
    end
    
    disp('Found these session');
    for iSubj=1:numel(subjects)
        disp([num2str(iSubj),':',subjects{iSubj}]);
    end
end

%create empty accuracy matrix
acc = cell(numel(subjects),nBlocks);

for iSubj=1:numel(subjects)
    disp(['(edp_rollinWindow): rollin rollin rollin...']);
    
    binnedEpochs=edp_preprocess('filename',filename,'subjID',subjects{iSubj},'nCond',nCond);
    numTrials = cellfun(@(c) numel(c), binnedEpochs, 'UniformOutput', false);
    % Calculate step sizes and then take minimum and make all step sizes the same
    stepSize = cellfun(@(c) floor(length(c)/nBlocks), binnedEpochs, 'UniformOutput', false);
    stepSize = min(cell2mat(stepSize));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Average the trials for each blk
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    condBlkAvg = cell(nCond,nBlocks); 
    for iBlk=1:nBlocks
        condBlkData = cell(nCond,1);    
        for icond=1:nCond
            % tf is a logical index vector with true only for the trials
            % in the current blk
            tf = false(numTrials{icond},1);
            tf(stepSize*(iBlk-1)+1:stepSize*iBlk) = true;
            % Extract the blk trials for every condition, and average them
            condBlkData{icond} = binnedEpochs{icond}(tf);
            condBlkAvg{icond,iBlk} = mean(cat(3,condBlkData{icond}{:}),3);
            % Remove last two channels (HEOG and VEOG)
            condBlkAvg{icond,iBlk} = condBlkAvg{icond,iBlk}(1:end-2,:);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Rollin Window
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    segmentLen = length(condBlkAvg{1,1});
    tp = [];
    for iBlk=1:nBlocks    
        for t=T0+windSleeve+1:2*windSleeve:segmentLen-windSleeve
            if iBlk ==1
                tp = [tp t-T0];
            end
            % Get training Data and label
            blkIndex = false(nBlocks,1);
            blkIndex(iBlk) = true;
            trnD = reshape(condBlkAvg(:,~blkIndex),[],1);
            trnD = cellfun(@(c) c(:,t-windSleeve:t+windSleeve), trnD, 'UniformOutput', false);
            trnl = repmat(1:nCond,nBlocks-1,1);
            trnl = reshape(trnl,[],1);
            
            % Get testing Data and label
            tstD = reshape(condBlkAvg(:,blkIndex),[],1);
            tstD = cellfun(@(c) c(:,t-windSleeve:t+windSleeve), tstD, 'UniformOutput', false);
            tstl = [1:nCond]';
            
            % Everyday Im Shuffelin 
            ix = randperm((nBlocks-1)*nCond);
            trnD = trnD(ix,:);
            trnl = trnl(ix);

            % Finaly convert each data point
            % from numChannelsXwindowSize to 1x(numChannels*windowSize)
            trnD = cell2mat(cellfun(@(c) reshape(c,1,[]),trnD, 'UniformOutput', false));
            tstD = cell2mat(cellfun(@(c) reshape(c,1,[]),tstD, 'UniformOutput', false));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Train and Predict with SVM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            % with ecoc
            mdl = fitcecoc(trnD,trnl,'Coding','onevsall','Learners','SVM');
            % with libsvm
            %mdl = svmtrain(trnl,trnD);

            % Predict the SVM label
            % with ecoc
            LabelPredicted = predict(mdl, tstD);
            % with libsvm
            %LabelPredicted = svmpredict(labelGold', tstD, mdl);
            acc{iSubj,iBlk} = [acc{iSubj,iBlk}; [tstl==LabelPredicted]'];
        end
    end
end

accMat = cellfun(@(c) mean(c,2),acc, 'UniformOutput', false);
accMat = [accMat{:}]';

Ntp = size(accMat,2);

err = std(accMat)/sqrt(nBlocks);
res = mean(accMat);

% perform temporal smoothing
smoothed = nan(1,Ntp);
for tAvg = 1:Ntp
 if tAvg ==1
   smoothed(tAvg) = mean(res((tAvg):(tAvg+2)));
 elseif tAvg ==2
   smoothed(tAvg) = mean(res((tAvg-1):(tAvg+2)));
 elseif tAvg == (Ntp-1)
   smoothed(tAvg) = mean(res((tAvg-2):(tAvg+1)));
 elseif tAvg == Ntp
   smoothed(tAvg) = mean(res((tAvg-2):(tAvg)));
 else
   smoothed(tAvg) = mean(res((tAvg-2):(tAvg+2)));  
 end
end


% draw mean and SE of average decoding accuracy
figure;
hold on
cl=colormap(parula(50));
mEI = boundedline(1:length(res),smoothed,err, 'cmap',cl(42,:),'alpha','transparency',0.35);
xlabel('Time (ms)');ylabel('Decoding Accuracy')
ax = gca;
ax.XTick = [1 floor(Ntp/4) floor(Ntp/2) floor(Ntp*3/4) floor(Ntp)];
ax.XTickLabel = {'0',tp(floor(Ntp/4)), tp(floor(Ntp/2)), tp(floor(3*Ntp/4)), tp(floor(Ntp))};
h = line(1:length(res),0.16667* ones(1,Ntp));
h.LineStyle = '--';
h.Color = [0.1,0.1,0.1];
title([filename]);
hold off

figure;
hold on
smoothedAll = [];
errAll = [];
for iCond=1:nCond
    accMatCond = cellfun(@(c) c(:,iCond), acc, 'UniformOutput', false);
    accMatCond = [accMatCond{:}]';
    errCond = std(accMatCond)/sqrt(nBlocks);
    resCond = mean(accMatCond);
    % perform temporal smoothing
    smoothedCond = nan(1,Ntp);
    for tAvg = 1:Ntp
     if tAvg ==1
       smoothedCond(tAvg) = mean(resCond((tAvg):(tAvg+2)));
     elseif tAvg ==2
       smoothedCond(tAvg) = mean(resCond((tAvg-1):(tAvg+2)));
     elseif tAvg == (Ntp-1)
       smoothedCond(tAvg) = mean(resCond((tAvg-2):(tAvg+1)));
     elseif tAvg == Ntp
       smoothedCond(tAvg) = mean(resCond((tAvg-2):(tAvg)));
     else
       smoothedCond(tAvg) = mean(resCond((tAvg-2):(tAvg+2)));  
     end
    end
    smoothedAll = [smoothedAll; smoothedCond];
    errAll = [errAll; errCond];
    %mEI = boundedline(1:length(smoothedCond),smoothedCond,errCond, 'cmap',condColor{iCond},'alpha','transparency',0.1);
    plot(1:length(smoothedCond),smoothedCond,'Color',condColor{iCond},'LineWidth',0.8)
end
xlabel('Time (ms)');ylabel('Decoding Accuracy')
ax = gca;
ax.XTick = [1 floor(Ntp/4) floor(Ntp/2) floor(Ntp*3/4) floor(Ntp)];
ax.XTickLabel = {'0',tp(floor(Ntp/4)), tp(floor(Ntp/2)), tp(floor(3*Ntp/4)), tp(floor(Ntp))};
h = line(1:length(res),0.16667* ones(1,Ntp));
h.LineStyle = '--';
h.Color = [0.1,0.1,0.1];
title([filename,' per condition']);
hold off

%disp(['Precision is ',num2str(sum(accuracy)/length(accuracy)),' chance is 0.16667']);

% SVM_ECOC
% mdl = fitcecoc(trnD,trnl, 'Coding','onevsall','Learners','SVM' );   %train support vector mahcine
% LabelPredicted = predict(mdl, tstD);       % predict classes for new data
% svm_predict(iter,t,i,:) = LabelPredicted;  % save predicted labels
% tst_target(iter,t,i,:) = tstl;             % save true target labels
