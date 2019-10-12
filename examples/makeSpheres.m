function imStack = makeSpheres
    % Make a bunch of spheres in space

    % Make an empty matrix
    width=180;
    imStack = zeros([width,width,width]);


    % Fill it with a few single pixels in random positions
    r = randperm(width^3);
    nSpheres = 40;
    imStack(r(1:nSpheres))=1;


    % Enlarge these into spheres spheres
    S=strel('sphere',8);
    sph = single(S.Neighborhood);
    sph=imresize3(sph,[size(sph,1), size(sph,2),size(sph,3)*2]);
    imStack = convn(imStack,sph,'same');

    % Binarise
    imStack(imStack>0.5)=1;
    imStack(imStack<0.5)=0;


