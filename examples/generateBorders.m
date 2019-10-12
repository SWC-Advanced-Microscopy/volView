function B = generateBorders(im,doPlot)
    % Demo showing how to get borders from demo image in order to overlay them volView
    % 
    % How to use
    % V=volView; % To get the demo image of a mouse brain
    % im=V.imStackOrig; % Get the image stack out of the object
    % B = generateBorders(im);
    %
    % A plot of the overlaid borders appears and the borders are returned 
    % in a cell array. B{1} is produced whilst looping over dim 3 of the
    % image, B{2} whilst looping over dim 2, and B{3} whilst looping over 
    % dim 1. 
    %
    % Rob Campbell - Sainsbury Wellcome Centre, 2019



    if nargin==0
        help(mfilname)
    end

    if nargin<2
        doPlot=true;
    end

    
    for ii=1:3
        B{ii}=getBordersAlongDim(im,ii-1);
    end

    if ~doPlot
        return
    end



    % Following code demonstrates how to overlay the borders
    figure
    ii=200;
    
    subplot(1,3,1)
    imagesc(im(:,:,ii))
    hold on
    t=B{1}{ii}{1};
    plot(t(:,2),t(:,1),'-r')
    axis equal tight

    subplot(1,3,2)
    imagesc(squeeze(im(:,ii,:)))
    hold on
    t=B{2}{ii}{1};
    plot(t(:,1),t(:,2),'-r')
    axis equal tight

    subplot(1,3,3)
    imagesc(squeeze(im(ii,:,:)))
    hold on
    t=B{3}{ii}{1};
    plot(t(:,2),t(:,1),'-r')
    axis equal tight

    colormap gray



    function [B,bw] = getBordersAlongDim(im,permBy)
        im = permute(im, circshift([1,2,3],permBy));
        bw=zeros(size(im));
        SE = strel('disk',5);
        B={};

        for ii=1:size(im,3)
            bw(:,:,ii) = im(:,:,ii)>10;
            bw(:,:,ii)=imdilate(bw(:,:,ii),SE); 
            bw(:,:,ii)=imerode(bw(:,:,ii),SE);
            tmp=bwboundaries(bw(:,:,ii),'noholes');
            [~,ind]=sort(cellfun(@length,tmp),'descend');
            B{ii} = tmp(ind);
        end


