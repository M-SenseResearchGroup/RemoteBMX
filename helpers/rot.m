function [ v2 ] = rot( r, rtype, v1, inverse)
%Reed Gurchiek, 2018
%
%   rot rotates the vector v in frame 1 (v1) using the rotator 'r' 
%   (quaternion, direction cosine matrix, or euler angles) to be expressed
%   in frame 2 (v2).  The rotator r should describe how one would rotate
%   frame 1 to align with frame 2.
%
%----------------------------INPUTS----------------------------------------
%
%   r:
%       the rotator.  
%           (a) QUATERNION: 4xn where n is the number of quaternions
%                   Row 1-3: qx,qy,qz; vector part of quaternion
%                   Row 4: scalar part of quaternion
%                       -NOTE: think about how the axis and angle you would
%                       use to rotate frame 2 onto frame 1. Then the 
%                       quaternion is [axis*sin(angle/2) cos(angle/2)].
%                       rot() uses q*(v1)*qconj
%
%           (b) EULER ANGLES: 3xn where n is the number of euler angle
%               vectors (must be IN RADIANS)
%                   Row 1: rotation angle about first axis (z if 'zyx')
%                   Row 2: rotation angle about second axis (y if 'zyx')
%                   Row 3: rotation angle about third axis (x if 'zyx')
%
%           (c) DCM: 3x3xn where n is the number of matrices
%   rtype:
%       string specifying rotator type.
%           (a) QUATERNION: 'q'
%           (b) EULER ANGLES: rotation sequence (e.g. 'zyx','zyz', etc.)
%           (c) DCM: 'dcm'
%
%   v1:
%       3xn vector measured in frame 1 to be rotated to be expressed in
%       frame 2 where n is the number of vectors
%
%   inverse (optional):
%       string specifying whether to use the inverse of the input operator
%       or not. 'transpose' 'inverse' 'y' 'yes'.  If left blank, then no
%       inverse.
%
%-----------------------------OUTPUTS--------------------------------------
%
%   v2:
%       3xn image of v in frame 2
%
%--------------------------------------------------------------------------

%%  rot

%get n vectors
[~,n] = size(v1);

%allocate space for v2
v2 = zeros(3,n);

%if inverse specified
invf = 1;
if nargin == 4
    
    %and use inverse
    if strcmpi(inverse,'y')||...
       strcmpi(inverse,'yes')||...
       strcmpi(inverse,'inverse')||...
       strcmpi(inverse,'inv')||...
       strcmpi(inverse,'transpose')||...
       strcmpi(inverse,'conjugate')
        
        %then flag
        invf = -1;
        
    end
end

%if quaternion
if strcmpi(rtype,'q')
    
    %for each vector
    for k = 1:n
        
        %parametrize matrix and rotate
        v2(:,k) = [r(1,k)^2 - r(2,k)^2 - r(3,k)^2 + r(4,k)^2          2*(r(1,k)*r(2,k) - invf*r(4,k)*r(3,k))            2*(r(1,k)*r(3,k) + invf*r(4,k)*r(2,k)) ;...
                      2*(r(1,k)*r(2,k) + invf*r(4,k)*r(3,k))      -r(1,k)^2 + r(2,k)^2 - r(3,k)^2 + r(4,k)^2            2*(r(2,k)*r(3,k) - invf*r(4,k)*r(1,k)) ;...
                      2*(r(1,k)*r(3,k) - invf*r(4,k)*r(2,k))          2*(r(2,k)*r(3,k) + invf*r(4,k)*r(1,k))        -r(1,k)^2 - r(2,k)^2 + r(3,k)^2 + r(4,k)^2]*v1(:,k);
        
    end
    
%if dcm
elseif strcmpi(rtype,'dcm')
    
    %for each vector
    for k = 1:n
        
        %if invert
        if invf == -1
        
            %invert (transpose) and rotate
            v2(1:3,k) = r(1:3,1:3,k)'*v1(:,k);
        
        %otherwise
        else
        
            %leave as is and rotate
            v2(1:3,k) = r(1:3,1:3,k)*v1(:,k);
            
        end
        
    end
    
%otherwise must be euler angle vector
else
    
    %if inverse then reverse sequence
    seq = [1 2 3];
    if invf == -1
        seq = [3 2 1];
    end
    
    %get rotation axes and submatrices used in euler formula: R(n,a) = I - s(a)*[nx] + (1-c(a))*[nx]^2
    a = zeros(3,3);
    skew1 = zeros(3,3,3);
    skew2 = zeros(3,3,3);
    for k = 1:3
        
        %column k of a is axis of rotation for the kth rotation
        a(regexp('xyz',rtype(seq(k))),k) = 1;
        
        %get skew symmetric matrix [nx]
        skew1(:,:,k) = [   0    -a(3,k)  a(2,k);...
                         a(3,k)    0    -a(1,k);...
                        -a(2,k)  a(1,k)    0   ];
        
        %get skew symmetric matrix squared [nx]^2
        skew2(:,:,k) = skew1(:,:,k)*skew1(:,:,k);
        
    end
    
    %for each vector
    for k = 1:n
        
        %rotate v1 one rotation at a time
        v2(:,k) = (eye(3) - sin(invf*r(seq(3),k))*skew1(:,:,3) + (1 - cos(invf*r(seq(3),k)))*skew2(:,:,3))*...
                  (eye(3) - sin(invf*r(seq(2),k))*skew1(:,:,2) + (1 - cos(invf*r(seq(2),k)))*skew2(:,:,2))*...
                  (eye(3) - sin(invf*r(seq(1),k))*skew1(:,:,1) + (1 - cos(invf*r(seq(1),k)))*skew2(:,:,1))*v1(:,k);
              
    end
    
end

end

