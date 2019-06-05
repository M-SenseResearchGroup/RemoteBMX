function [ r ] = getrot( v1, v2, type)
%Reed Gurchiek, 2017
%   getrot finds the rotation operator of type 'type' which takes v 
%   measured in frame 1 (v1) and expresses it in frame 2 (v2) if v2 is a 
%   3-dimensional vector.  Otherwise, it constructs an angle-axis
%   rotator where v1 is the axis and v2 is the angle if v2 is
%   1-dimensional.  In this case, consider the axis (in frame 1) and angle
%   that one would use to rotate frame 1 to align with frame 2
%
%-----------------------------INPUTS---------------------------------------
%
%   v1, v2:
%       vectors 1 and 2. 3xn matrix of column vectors. v1 is v measured in
%       frame 1 and v2 is v measured in frame 2.
%       OR
%       rotation axis (v1: 3xn matrix of column vectors with unit norm) and
%       rotation angle (v2: 1xn array of rotation angles)
%
%   type:
%       string specifying type of rotation operator.  Either 'dcm' for
%       direction cosine matrix or 'q' for quaternion.
%
%----------------------------OUTPUTS---------------------------------------
%
%   r:
%       rotation operator which takes v1 to v2 of type 'type' or described
%       by the axis-angle combo v1 & v2.
%
%--------------------------------------------------------------------------

%% getrot

%verify proper inputs
[v1r,v1c] = size(v1);
[v2r,v2c] = size(v2);
if v1r ~= 3
    error('v1 must be 3xn matrix of column vectors')
elseif v1c ~= v2c
    error('v1 and v2 must have same number of columns')
elseif v2r ~= 1 && v2r ~= 3
    error('v2 must either be 3xn (if a vector) or 1xn (if an angle)')
end

%if v2 is a vector
if v2r == 3
    
    %get axis of rotation
    axis = cross(v1,v2)./vecnorm(cross(v1,v2));
    
    %get angle
    angle = acos(dot(v2,v1)./(vecnorm(v2).*vecnorm(v1)));

%if v2 is 1D array of angles
elseif v2r == 1
    
    %axis and angle given
    axis = v1;
    angle = v2;
    
end

%if quaternion
if strcmpi(type,'q')
    
    %construct quaternion
    r = [repmat(sin(angle/2), [3 1]).*axis; cos(angle/2)];
    
%if dcm
elseif strcmpi(type,'dcm')
    
    %construct dcm (Rodrigues formula: R(n,a) = I + s(a)*[nx] + (1-c(a))*[nx]^2)
    % note: often will see ... - s(a)*[nx], but that notation is for vector rotations
    % here we are interested in frame rotations, i.e. negation of n
    r = zeros(3,3,v1c);
    I3 = eye(3);
    for k = 1:v1c
        r(:,:,k) = I3 + sin(angle(k))*skew(axis(:,k)) + (1-cos(angle(k)))*skew(axis(:,k))*skew(axis(:,k));
    end
end

end