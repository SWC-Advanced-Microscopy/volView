function getAndCacheDemoImage(obj)
    % Get a demo image from the web and cache locally
    obj.cachedDemoDataLocation = fullfile(tempdir,'volViewDemoStack.tiff');

    if ~exist(obj.cachedDemoDataLocation,'file')
        fprintf('Downloading demo image stack and caching to disk for future use.\n')
        websave(obj.cachedDemoDataLocation,'http://mouse.vision/lasagna/template.tif');
    end
end