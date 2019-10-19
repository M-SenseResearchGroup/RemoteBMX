function [ events ] = getGaitEvents_ccThighAccelerometer(a,sf,time,minimumStrideTime,maximumStrideTime,nMinimumStridesPerBout)
%Reed Gurchiek, 2019
%   identifies instants of stride start (foot contact) and swing start
%   (foot off) given accelerometer signal aligned with long axis of thigh
%   during 8 seconds of walking data
%
%----------------------------------INPUTS----------------------------------
%
%   a:
%       1xn, 8 seconds of accelerometer data, aligned with long axis of
%       thigh
%
%   sf:
%       sampling frequency (Hz)
%
%   time:
%       1xn, time array
%
%   minimumStrideTime,maximumStrideTime:
%       minimum and maximum allowable stride times. Any strides out of
%       these bounds will be removed.
%
%   nMinimumStridesPerBout:
%       minimum number of strides that must be extracted. If the number of
%       identified strides is less than nMinimumStridesPerBout, then the
%       deleteBout flag will be set to 1
%
%---------------------------------OUTPUTS----------------------------------
%
%   events:
%       struct, fields:
%           (1) deleteBout: if 1 then bout should be deleted
%           (2) strideStart: time associated with best estimate of stride
%           start instant (foot contact)
%           (3) swingStart: time associated with best estimate of swing
%           start instant (foot off)
%
%--------------------------------------------------------------------------
%% get_gaitEvents_ccThighAccelerometer

% deleteBout logical
deleteBout = 0;

% time step and initialize vars
dt = 1/sf;
strideStart = [];
swingStart = [];

% low pass at 5
a5 = bwfilt(a,5,sf,'low',4);

% get power spectral density
% expecting a peak at step frequency (most dominant for lower
% frequencies) and a peak below this for stride freq
[fpow,freq] = pwelch(a- mean(a),rectwin(round(sf*2)),[],4096,sf); % window @ 2 seconds

% remove frequencies < 0.5 Hz and > 4 Hz
fpow(freq < 0.5 | freq > 4) = [];
freq(freq < 0.5 | freq > 4) = [];

% get peaks and remove endpoints
[~,ipow] = extrema(fpow);
ipow(ipow == 1) = []; ipow(ipow == length(fpow)) = [];

% get peak frequencies and power
freq = freq(ipow);
fpow = fpow(ipow);

% get max frequency (approximate step frequency)
[~,imax] = max(fpow);
stpf = freq(imax);

% remove this frequency and all above it
fpow(freq >= stpf) = [];
freq(freq >= stpf) = [];

% assume stride frequency is the maximum remaining
[~,imax] = max(fpow);
strf = freq(imax);

% if empty then delete
if isempty(strf) || isempty(stpf)

    deleteBout = 1;

else

    % low pass at stepf and strf
    astp = bwfilt(a,stpf,sf,'low',4);
    astr = bwfilt(a,strf,sf,'low',4);

    % get minima/maxima of stride/step filtered signals
    clear imax
    [~,imax.str,~,imin.str] = extrema(astr);
    [~,imax.stp,~,imin.stp] = extrema(astp);
    [~,imax.a5] = extrema(a5);

    % remove endpoints
    imin.str(imin.str == 1) = []; 
    imax.str(imax.str == 1) = []; 
    imax.stp(imax.stp == 1) = [];
    imin.stp(imin.stp == 1) = [];
    imin.str(imin.str == length(astr)) = []; 
    imax.str(imax.str == length(astr)) = [];
    imax.stp(imax.stp == length(astr)) = [];
    imin.stp(imin.stp == length(astr)) = [];
    imax.a5(imax.a5 == 1) = [];
    imax.a5(imax.a5 == length(astr)) = [];

    % get instants where z low passed at 5 crosses 1 g
    icrossg = crossing0(a5-1,{'n2p'});

    % sometimes false minima identified within stride
    % require minima be within min and max stride times
    i = 1;
    while i <= length(imin.str) - 1
        if imin.str(i+1)-imin.str(i) < floor(minimumStrideTime*sf)
            imin.str(i+1) = [];
        elseif imin.str(i+1)-imin.str(i) > ceil(maximumStrideTime*sf)
            imin.str(i) = [];
        else
            i = i + 1;
        end
    end

    % need at least 2 more minima than nMinimumStridesPerBout
    if length(imin.str) < nMinimumStridesPerBout + 2
        
        deleteBout = 1;

    else

        % gait phase detection algorithm:
        % get last step peak between stride minima = swing start
        % get following valley for each stride peak ~ FC
        % next 1g crossing is best estimate of FC

        % for each minima
        swingStart = zeros(1,length(imin.str) - 1);
        strideStart = zeros(1,length(imin.str)-1);
        i = 1;
        while i <= length(imin.str)-1

            deleteStride = 0;

            % get zstp peaks between current and next str minima
            swingStart0 = imax.stp(imax.stp > imin.str(i) & imax.stp < imin.str(i+1));

            % if empty then delete
            if isempty(swingStart0)
                deleteStride = 1;
            % otherwise
            else

                % if 1 peak then this is our estimate
                % if 2 peaks then take the latest
                if length(swingStart0) == 2
                    swingStart0 = max(swingStart0);
                % if more than 2 peaks then take the one corresponding
                % to the largest peak
                elseif length(swingStart0) > 2
                    [~,swingStart00] = max(astp(swingStart0));
                    swingStart0 = swingStart0(swingStart00);
                end

                % get swing start
                swingStart(i) = time(swingStart0);

                % get next valley
                strideStart0 = imin.stp(swingStart0 < imin.stp);

                % if is empty then delete
                if isempty(strideStart0)
                    deleteStride = 1;

                % also require this valley be less than 1g
                elseif astp(strideStart0(1)) >= 1
                    deleteStride = 1;

                else

                    % get next instant where a5 crossed 1g
                    crossg = icrossg(icrossg > strideStart0(1));

                    % if none then delete
                    if isempty(crossg)
                        deleteStride = 1;

                    else

                        % 1g crossing instant is best estimate of FC. 
                        crossg = crossg(1);

                        % require crossg be within 320 ms of strideStart0
                        if (crossg - strideStart0(1))/sf > 0.320
                            deleteStride = 1;
                        else
                            % interpolate between current crossg 
                            % (immediately after) and previous to estimate
                            strideStart(i) = (dt - a5(crossg-1)*time(crossg) + a5(crossg)*time(crossg-1))/(a5(crossg) - a5(crossg-1));
                        end

                    end

                end

            end

            if deleteStride
                swingStart(i) = [];
                strideStart(i) = [];
                imin.str(i) = [];
            else
                i = i + 1;
            end

        end
        
    end
    
end

% save
events.deleteBout = deleteBout;
events.strideStart = strideStart;
events.swingStart = swingStart;

end