function out = boundingBoxLineDataToPlottable(in)
    % If necessary, converts line data composed of bounding boxes to 
    % data that are plottable by volView. It does this if the
    % in{1}{1}{1} has size [1,4]. If it does not, the function quits
    % and does nothing. 

    if isempty(in)
        out = in;
        return
    end

    if ~isequal( size(in{1}{1}{1}), [1,4])
        out = in;
        return
    end

    fprintf('Converting bounding box line data to plottable\n')

    for ax = 1:length(in)
        for sec = 1:length(in{ax})
            for tBox = 1:length(in{ax}{sec})

                tmp = in{ax}{sec}{tBox};
                y=[tmp(1), tmp(1)+tmp(3), tmp(1)+tmp(3), tmp(1), tmp(1)];
                x=[tmp(2), tmp(2), tmp(2)+tmp(4), tmp(2)+tmp(4), tmp(2)];
                in{ax}{sec}{tBox} = [x',y'];

            end
        end
    end

    out = in;