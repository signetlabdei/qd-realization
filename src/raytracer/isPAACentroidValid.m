function varargout = isPAACentroidValid(roomCoordinates, centroidCoordinate)
%ISPAACENTROIDVALID returns check if the centroid in insed the defined area.
%
%   ISPAACENTROIDVALID(roomCoordinates, centroidCoordinate)
%   Generate a warning is the centroid coordinates centroidCoordinate are
%   outside the area defined in roomCoordinates
%
%   check = ISPAACENTROIDVALID(roomCoordinates, centroidCoordinate)
%   Return false if the centroid coordinates centroidCoordinate are
%   outside the area defined in roomCoordinates
%
%   Copyright 2019-2020 NIST/CLT (steve.blandino@nist.gov)

%#codegen

roomCoordinates = reshape(permute(reshape(roomCoordinates,size(roomCoordinates,1),3,[]),[1,3,2]),[],3);
minCoord = min(roomCoordinates);
maxCoord = max(roomCoordinates);


if ~all(reshape(centroidCoordinate>= minCoord & centroidCoordinate<= maxCoord, [],1))
    warning OFF BACKTRACE
    warning('PAA outside defined area')
    warning ON BACKTRACE
    varargout{1} = false;
else
    varargout{1} = true;
end

end