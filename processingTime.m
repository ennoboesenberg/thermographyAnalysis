function [days_left, hours_left, minutes_left, seconds_left] = processingTime(leftpar, calculationTime)

    timeleft            =   leftpar*mean(calculationTime);                  % How much time is still required to finish the entire process

    d_mod_timeleft      =   mod(timeleft, 86400);                           % seconds left after substracting full days
    h_mod_timeleft      =   mod(d_mod_timeleft, 3600);                      % seconds left after substracting full hours
    min_mod_timeleft    =   mod(h_mod_timeleft, 60);                        % seconds left after substracting full minutes
    
    days_left           =   floor(timeleft/86400);                          % days left untill process is finished
    hours_left          =   floor(d_mod_timeleft/3600);                     % hours left untill process is finished
    minutes_left        =   floor(h_mod_timeleft/60);                       % minutes left untill process is finished
    seconds_left        =   floor(min_mod_timeleft);                        % seconds left untill process is finished
    
end


%     [countDown, timescale] = processingTime(leftpar, calculationTime)  
%     % Setting the estimated time timescale right
%     if timeleft < 60
%         timefactor  =   1;
%         timescale   =   's';
%     elseif timeleft > 86400
%         timefactor  =   86400;
%         timescale   =   'd';
%     elseif timeleft > 3600
%         timefactor  =   3600;
%         timescale   =   'h';
%     else
%         timefactor  =   60;
%         timescale   =   'min';
%     end
%     
%     countDown = 1+round(timeleft/timefactor);