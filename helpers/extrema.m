function [ max,imax,min,imin ] = extrema( x )
%Reed Gurchiek,
%   extrema finds local minima and maxima of the vector x
%
%---------------------------INPUTS-----------------------------------------
%
%   x:
%       n-element array for which the local minima and maxima will be found
%
%--------------------------OUTPUTS-----------------------------------------
%
%   max,imax:
%       local maxima values (max) and their indices (imax)
%
%   min,imin:
%       local minima values (min) and their indices (imin)
%
%--------------------------------------------------------------------------
%% extrema

%initialize
max = [];
min = [];
imax = [];
imin = [];


%get differences
d = diff(x);

%get extrema if any nonzero changes
if any(d)
    
    %allocation
    imax = zeros(1,length(d));
    imin = zeros(1,length(d));
    
    %endpoints are always local extrema
    first = find(x ~= x(1));
    first(2:end) = [];
    last = find(x ~= x(end));
    last(1:end-1) = [];
    
    if x(1) < x(first)
        iminFirst = 1:first-1;
        imaxFirst = [];
    else
        iminFirst = [];
        imaxFirst = 1:first - 1;
    end
    
    if x(end) < x(last)
        iminLast = last+1:length(x);
        imaxLast = [];
    else
        imaxLast = last+1:length(x);
        iminLast = [];
    end
    
    %for each element
    maxct = 0;
    minct = 0;
    direction0 = sign(x(first)-x(first-1));
    constant = 0;
    for k = first+1:last+1
        
        %current trajectory
        direction = sign(x(k) - x(k-1));
        
        %if no change
        if direction == 0
            
            constant = constant + 1;
            
        %otherwise
        else
            
            %if local minimum
            if direction == 1 && direction0 == -1
                
                %update min/imin
                minct = minct + 1 + constant;
                imin(minct-constant:minct) = k-1-constant:k-1;
            
            %if local maximum
            elseif direction == -1 && direction0 == 1
                
                %update max/imax
                maxct = maxct + 1 + constant;
                imax(maxct-constant:maxct) = k-1-constant:k-1;
            end
            
            %current trajectory is next iteration previous
            direction0 = direction;
            
            %no consecutive constant
            constant = 0;
            
        end
    end
    
    %finish
    imax = [imaxFirst imax imaxLast];
    imax(imax==0) = [];
    max = x(imax);
    imin = [iminFirst imin iminLast];
    imin(imin==0) = [];
    min = x(imin);
end


end