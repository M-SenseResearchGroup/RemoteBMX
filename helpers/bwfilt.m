function [ out ] = bwfilt(in,cf,sf,type,order)
%Reed Gurchiek, 2018
%   bwfilt uses MATLABs butter function to determine the transfer
%   function coefficients to filter signal(s) in sampled at frequency sf by
%   a specified order according to the specified filter type
%   'low','high','bandpass','bandstop'.  The transfer function is
%   implemented in filtfilt to remove phase shift (i.e. filter is zero lag)
%
%---------------------------INPUTS-----------------------------------------
%
%   in:
%       m x n signal to be filtered.  the longest dimension is considered
%       the time dimension.
%
%   cf:
%       cutoff frequency.  If vector then type should be bandpass.
%
%   sf:
%       scalar, sampling frequency in samples/second.
%
%   type (optional):
%       'low','high','bandpass','bandstop', default = 'low'
%
%   order (optional):
%       filter order, should be even, default = 4;
%
%--------------------------OUTPUTS-----------------------------------------
%
%   out:
%       filtered signal
%
%--------------------------------------------------------------------------
%% bwfilt

% filter type
if nargin > 3
    if contains(type,'l','IgnoreCase',1)
        type = 'low';
    elseif contains(type,'h','IgnoreCase',1)
        type = 'high';
    elseif contains(type,'stop','IgnoreCase',1)
        type = 'stop';
    elseif contains(type,'b','IgnoreCase',1)
        type = 'bandpass';
    else
        type = 'low';
    end
else
    type = 'low';
end

% filter order
if nargin > 4
    % if odd, make even
    if mod(order,2)
        order = order + 1;
        warning('User requested filter order (%d) is not even.  Using order = %d instead.',order-1,order)
    end
    % divide by 2 to compensate for filtfilt
    order = order/2;
else
    order = 2;
end
    
% get transfer fxn coefs
[b,a] = butter(order,2*cf/sf,type);

% transpose to adjust for filtfilt
[r,c] = size(in);
if c > r; in = in'; end

% filter
out = filtfilt(b,a,in);
if c > r; out = out'; end


end