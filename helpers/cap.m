function [ str ] = cap(str)
%Reed Gurchiek, 2018
%   capitalizes first letter in str
%
%---------------------------INPUTS-----------------------------------------
%
%   str:
%       str to capitalize
%
%--------------------------OUTPUTS-----------------------------------------
%
%   out:
%       capitalized string
%
%--------------------------------------------------------------------------
%% cap

str(1) = upper(str(1));


end