function [ cellArray ] = append2all(cellArray,string,loc)
%Reed Gurchiek, 2019
%   append2all concatenates string 'string' to each string element in
%   cellArray
%
%----------------------------------INPUTS----------------------------------
%
%   cellArray:
%       cellArray of strings to concatenate string too
%
%   string:
%       string to concatenate to each string element in cellArray
%
%   loc:
%       location flag, concatenate before if loc = 0, otherwise after
%
%---------------------------------OUTPUTS----------------------------------
%
%   cellArray:
%       same cellArray as input except with concatenated
%
%--------------------------------EXAMPLES----------------------------------
%
%   cellArray = {'red' 'blue' 'green'};
%   string = 'bright_';
%   cellArray = cat2all(cellArray,string,0);
%   cellArray = {'bright_red' 'bright_blue' 'bright_green'};
%
%--------------------------------------------------------------------------
%% append2all

for k = 1:length(cellArray)
    if loc == 0
        cellArray{k} = [string cellArray{k}];
    else
        cellArray{k} = [cellArray{k} string];
    end
end

end