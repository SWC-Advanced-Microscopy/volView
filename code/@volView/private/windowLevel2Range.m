function [Rmn Rmx] = windowLevel2Range(windWidth,windLevel)
    Rmn = windLevel - (windWidth/2);
    Rmx = windLevel + (windWidth/2);
    if (Rmn >= Rmx)
        Rmx = Rmn + 1;
    end
end

