% usage: preprocess EEG data
% by: Sari Saba-Sadiya
% date: 24/12/19
% purpose:
function binnedEpochs=edp_preprocess(varargin)

getArgs(varargin,{'subjID=[]','filename=oriErpAlpha','nCond=6'});

% Get subjects
curDir = pwd;
dataDir=[curDir,'/../data/'];cd(dataDir);
if ~isempty(subjID)
    subjects{1}=subjID;
else
    % ----- find subject directory ----%
    disp(['Use data directory: ',dataDir]);
    sessions=dir('.');
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

% Get data per condition
binnedEpochs = cell(nCond,1);
for ii=1:numel(subjects)
    content = load([dataDir,subjects{ii},'/',filename,'.mat']);
    epochs = content.(filename).epoch;
    for jj=1:numel(epochs)
        binIdx = epochs(jj).eventbini{1};
        binnedEpochs{binIdx}{end+1} = content.(filename).data(:,:,jj);
    end
end

lengths = strjoin(cellfun(@(c) num2str(numel(c)), binnedEpochs, 'UniformOutput', false));
disp(['Binned epochs have ',lengths,' trials'])

cd(curDir);

end