function B = generateBorders(im,doPlot)
    % Demo showing how to get borders from demo image in order to overlay them volView
    % 
    % function B = generateBorders(im,doPlot)
    %
    % Purpose
    % This example function demonstrates how to trace borders around an object in an image stack
    % in order to allow overlay of these borders in volView.  A plot of the overlaid borders
    % optionally appears and the borders are returned as a cell array of cell arrays.
    %x
    %
    % Inputs
    % im - The image stack containing the object around which borders are to be drawn.
    % doPlot - False by default. If true, a new figure window appears displaying the
    %          three orthogonal views with the borders drawn around the object 
    % threshLevel - The value at which to threshold the image to pick out the object.
    %               By default this is suitable for the demo mouse brain image stack.
    %
    % Outputs
    % B - A cell array of borders suitable for plotting in volView
    %
    %
    % Example usage:
    % V=volView; % To get the demo image of a mouse brain
    % im = V.imStackOrig;
    % B = generateBorders(im);
    % delete(V)
    % V=volView(im,[],B)
    %
    %
    %
    % Rob Campbell - Sainsbury Wellcome Centre, 2019


    % Parse input arguments
    if nargin==0
        help(mfilname)
    end

    if nargin<2 || isempty(doPlot)
        doPlot=false;
    end

    if nargin<3 || isempty(threshLevel)
        threshLevel=10;
    end


    % Calculate borders in each direction using the same axis permutations as volView.switchView
    B{1}=getBordersAlongDim(im,[1,2,3],threshLevel);
    B{2}=getBordersAlongDim(im,[3,1,2],threshLevel);
    B{3}=getBordersAlongDim(im,[3,2,1],threshLevel);


    % Bale out if the user didn't ask for the debug plot to be shown
    if ~doPlot
        return
    end



    % Overlay borders onto object
    figure

    subplot(1,3,1)
    tPlane = round(size(im,3)/2); % Middle plane of stack along this axis
    imagesc(im(:,:,tPlane))
    hold on
    t=B{1}{tPlane}{1};
    plot(t(:,2),t(:,1),'-r')
    axis equal tight

    subplot(1,3,2)
    tPlane = round(size(im,2)/2);
    imagesc(squeeze(im(:,tPlane,:)))
    hold on
    t=B{2}{tPlane}{1};
    plot(t(:,1),t(:,2),'-r')
    axis equal tight

    subplot(1,3,3)
    tPlane = round(size(im,1)/2);
    imagesc(rot90(squeeze(im(tPlane,:,:)),-1)) %This rot90 is a bit of a hack, but fine
    hold on
    t=B{3}{tPlane}{1};
    plot(t(:,2),t(:,1),'-r')
    axis equal tight

    colormap gray



    function [B,bw] = getBordersAlongDim(im,permBy,threshLevel)
        % Workhorse function that calculates the borders for each
        % slice along a given dimension
        im = permute(im, permBy);
        bw=zeros(size(im));
        SE = strel('disk',5);
        B={};

        for ii=1:size(im,3)
            bw(:,:,ii) = im(:,:,ii)>threshLevel;
            bw(:,:,ii)=imdilate(bw(:,:,ii),SE); 
            bw(:,:,ii)=imerode(bw(:,:,ii),SE);

            %Sort boundaries by length so largest boundary is always first
            tmp=bwboundaries(bw(:,:,ii),'noholes');
            [~,ind]=sort(cellfun(@length,tmp),'descend');
            B{ii} = tmp(ind);
        end


