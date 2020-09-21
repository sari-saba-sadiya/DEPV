% usage: Run SVM with Ecoc to decode EEG data
% by: Sari Saba-Sadiya
% date: 24/12/19
% purpose:
function stats=edp_svmEcoc(varargin)

addpath(genpath('~/matlab/libsvm/matlab'))

getArgs(varargin,{'subjID=[]','filename=oriErpAlpha','nCond=6'});

% parameters to set
svmECOC.nBlocks = 8; % # of blocks for cross-validation
svmECOC.testProp = (svmECOC.nBlocks - 1)/svmECOC.nBlocks; % training proportion

% Get subjects
if ~isempty(subjID)
    subjects{1}=subjID;
else
    dataDir = '../data/';
    % ----- find subject directory ----%
    disp(['Use data directory: ',dataDir]);
    sessions=dir(dataDir);
    subjects={};
    for ii=1:numel(sessions)
        if length(sessions(ii).name) == 3
            subjects=cellcat(subjects,sessions(ii).name);
        end
    end
    
    disp('Found these session');
    for ii=1:numel(subjects)
        disp([num2str(ii),':',subjects{ii}]);
    end
end

for ii=1:numel(subjects)
    binnedEpochs=edp_preprocess('filename',filename,'subjID',subjects{ii},'nCond',nCond);
    lengths = cellfun(@(c) numel(c), binnedEpochs, 'UniformOutput', false);
    steps = cellfun(@(c) floor(length(c)/svmECOC.nBlocks), binnedEpochs, 'UniformOutput', false);
    
    % Split data for training and testing
    condTrnAvg = cell(nCond,svmECOC.nBlocks); 
    for iBlk=1:svmECOC.nBlocks % for Block
        condTrn = cell(nCond,1);    
        for icond=1:nCond
            tf = false(lengths{icond},1);
            tf(steps{icond}*(iBlk-1)+1:steps{icond}*(iBlk-1)+steps{icond}) = true;
            condTrn{icond} = binnedEpochs{icond}(tf);
            condTrnAvg{icond,iBlk} = mean(cat(3,condTrn{icond}{:}),3);
        end
    end
    
    %create empty matrix
    acc = cell(1,numel(subjects));
    
    % Get SVM accuracy
    accuracy = [];
    confMat = zeros(nCond);
    for iBlk=1:svmECOC.nBlocks % for Block
        blkIndex = false(svmECOC.nBlocks,1);
        blkIndex(iBlk) = true;
        trnD = [];
        trnl = [];
        for icond=1:nCond
            condIndex = false(nCond,1);
            condIndex(icond) = true;
            X = cellfun(@(c) reshape(c,1,[]),condTrnAvg(condIndex,~blkIndex), 'UniformOutput', false);
            trnD = [trnD; cell2mat(X')];
            trnl = [trnl; ones(svmECOC.nBlocks-1,1)*icond];
        end
        
        ix = randperm((svmECOC.nBlocks-1)*nCond);
        trnD = double(trnD(ix,:));
        trnl = trnl(ix);

        % Train the svm model
        mdl = fitcecoc(trnD,trnl,'Coding','onevsall','Learners','SVM'); %train support vector mahcine
        %mdl = svmtrain(trnl,trnD);
        
        X = cellfun(@(c) reshape(c,1,[]),condTrnAvg(:,blkIndex), 'UniformOutput', false);
        tstD = double(cell2mat(X));
        labelGold = 1:nCond;
        
        %Predict the SVM label
        LabelPredicted = predict(mdl, tstD);       % predict classes for new data
        %LabelPredicted = svmpredict(labelGold', tstD, mdl);
        accuracy = [accuracy; labelGold'==LabelPredicted];
        confMat = confMat + confusionmat(labelGold,LabelPredicted);
    end
    confMat = confMat / svmECOC.nBlocks;
    acc{ii} = accuracy;
    figure;
    imagesc(confMat);
    colorbar;
    colormap(jet(20));
    title(['Confusion matrix for ',filename,' subject ',subjects{ii}]);
end

disp(['Precision is ',num2str(sum(accuracy)/length(accuracy)),' chance is 0.16667']);

% SVM_ECOC
% mdl = fitcecoc(trnD,trnl, 'Coding','onevsall','Learners','SVM' );   %train support vector mahcine
% LabelPredicted = predict(mdl, tstD);       % predict classes for new data
% svm_predict(iter,t,i,:) = LabelPredicted;  % save predicted labels
% tst_target(iter,t,i,:) = tstl;             % save true target labels
