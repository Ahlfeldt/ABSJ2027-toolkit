function stop = STOP_CITY_TARGET_SEARCH(~,values,~)
%STOP_CITY_TARGET_SEARCH Stop once log moment errors imply better than 0.2% fit.
stop = values.fval < log(1.002)^2; % Each absolute log error is bounded by the square root of their squared sum.
end
