function B=overlayARAborders
  % function B=overlayARAborders
  %
  % Calculate Allen Reference Atlas borders for overlay onto
  % demo mouse template image.
  % This requires
  % https://github.com/SainsburyWellcomeCentre/ara_tools
  % and associated dependencies.
  %
  % Feed output of this function as third arg to volView.
  % Only coronal borders are returned



  A=aratools.atlascacher.getCachedAtlas;
  
  B{1}={};
  for ii=1:size(A.atlasVolume,3)
    fprintf('.')
    OUT=aratools.projectAtlas.cutAtlas(A.atlasVolume,3,ii);

    n=1;
    for ind =1:height(OUT.structureList)
      tmp = OUT.structureList.areaBoundaries{ind};
      for k = 1:length(tmp)
        B{1}{ii}{n} = tmp{k};
        n=n+1;
      end    
    end

    
  end

  fprintf('\n')
  
  
