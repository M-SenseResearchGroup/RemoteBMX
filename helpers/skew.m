function [ Vx ] = skew( V )
%Reed Gurchiek, 2017
%   skew takes a 3xn matrix of column vectors and returns a 3x3xn skew
%   symmetric matrix for each column vector in V such that Vx(3,3,i)*p =
%   cross(V(:,i),p).
%
%---------------------------------INPUTS-----------------------------------
%
%   V:
%       3xn matrix of column vectors.
%
%--------------------------------OUTPUTS-----------------------------------
%
%   Vx:
%       3x3xn skew symmetric matrices.
%
%--------------------------------------------------------------------------

%% skew

%verify proper inputs
[Vr,Vc] = size(V);
if Vc == 3 && Vr ~= 3
    V = V';
elseif Vr ~= 3 && Vc ~= 3
    error('V must have 3 rows or 3 columns')
end

%for each vector
[~,n] = size(V);
Vx = zeros(3,3,n);
for k = 1:n
    
    %get skew
    Vx(:,:,k) = [   0    -V(3,k)  V(2,k);...
                  V(3,k)    0    -V(1,k);...
                 -V(2,k) V(1,k)     0   ];
             
end



end

