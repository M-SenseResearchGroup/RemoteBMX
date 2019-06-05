function [ indices ] = staticndx( data, nsamples)
%Reed Gurchiek, 2017
%   staticndx finds the start and end indices of the interval of length
%   nsamples with the smallest variance for the data in data.
%
%------------------------------INPUTS--------------------------------------
%
%   data:
%       m x n matrix.  staticndx assumes the largest dimension (m or n)
%       represents indices of observations for different variables, the
%       number of which is equal to the lesser dimension (m or n).  The
%       larger must be greater than nsamples
%
%   nsamples:
%       the number of samples in the static interval desired
%
%------------------------------OUTPUTS-------------------------------------
%
%   indices:
%       1 x 2.  indices(1) = start index.  indices(2) = end index.
%
%--------------------------------------------------------------------------

%% staticndx

%get dims
[r,c] = size(data);
if r == c
    error('data matrix must not be square')
end

%determine dimension of observation indices and number of observations
[N,o] = max([r c]);

%verify correct input
if nsamples >= N
    error('nsamples must be larger than largest dimension size of data')
end

%if observation indices are columns
if o == 2
    
    %force time/observation series to be column arrays
    d = data';
    
    %get number of variables
    nv = r;
    
%if observation indices are rows    
elseif o == 1
 
    %then time/observation series are already column arrays
    d = data;
    
    %get number of variables
    nv = c;
    
end

%determine number of intervals of length nsamples
nint = N - nsamples + 1;

%for each interval of length nsamples
variance = zeros(nint,nv);
for k = 1:nint
    
    %get variance of each variable for each interval of length nsamples
    variance(k,:) = var(d(k:k+nsamples-1,:));
    
end

%get total variance for each interval
tv = sum(variance,2);
    
%get starting index for the most static interval
[~,indices(1)] = min(tv);
    
%get ending index for most static interval
indices(2) = indices(1) + nsamples - 1;     
    




end

