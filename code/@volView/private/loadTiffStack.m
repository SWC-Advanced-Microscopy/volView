function imStack = loadTiffStack(fname)
    % Loads a TIFF stack from a file
    %
    % Inputs
    % fname - relative or absolute path to a TIFF file
    %
    % Outputs 
    % imStack - image stack

    if ~exist(fname,'file')
        imStack=[];
        fprintf('No file found at %s\n', fname)
        return
    end


    % determine the number of frames
    warning off
    imageInfo=imfinfo(fname);
    warning on
    numFrames=length(imageInfo);

    %pre-alocate
    imSize=[imageInfo(1).Height,imageInfo(1).Width,numFrames];
    imStack=imread(fname,1);
    imStack=repmat(imStack,[1,1,numFrames]);

    % Read all frames
    for tFrame=2:numFrames
        if mod(tFrame,10)==0, fprintf('.'), end
        imStack(:,:,tFrame)=imread(fname,tFrame);
    end

    fprintf('\n')