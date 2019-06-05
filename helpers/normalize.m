function [ v ] = normalize( v, dim)
%Reed Gurchiek, 2017
%   normalize normalizes vectors in V and also returns the magnitude.
%
%----------------------------------INPUTS----------------------------------
%
%   v:
%       mxn matrix of column (dim = 1) or row (dim =2) vectors
%
%   dim:
%       determines how vectors arranged in V.  If column vectors then dim
%       should be 1 (default).  If row vectors then dim should be 2.
%
%---------------------------------OUTPUTS----------------------------------
%
%   v:
%       matrix of vectors (input V) of unit length
%
%--------------------------------------------------------------------------

%% normalize

% dim?
if nargin == 1
    dim = 1;
end

% get size
[Vr,Vc] = size(v);
rc = [Vr Vc];
nrep = [1 1];
nrep(dim) = rc(dim);

% normalize
v = v./repmat(vecnorm(v,2,dim),nrep);
    
end

