# Time Offset Methods #

These are the different methods called from *proc_time_offsets*. They must return an $N$ by 1 duration array of time offsets to be added to the raw data where $N$ is the number of sensors.

## Dunk Correlation ##

Used to compute the time offsets from a calibration dunk, i.e. an interval where all the sensors are reading the same constant temperature. We must specify the *dunk_interval* and the base or "truth" sensor (*time_base_sensor_sn*) in the configuration object. The method is:
-   Find the median of the base temperature timeseries. If the dunk is longer than half the timeseries then this picks out a temperature value during the dunk.
-   Define a new timeseries for each sensor that is the absolute value of the temperature timeseries minus this median value. This allows us to use this method in situations where, prior to the dunk, some of the sensors are measuring temperatures hotter than the dunk temperature and others colder.
-   For each sensor the new timeseries is linearly interpolated onto the base sensor's time and then correlated against the base sensor timeseries. The time offset is the lag that maximises the correlation.

## Cohere ##

Note that this method is untested since the code was updated to use datetimes rather than datenums.

## Known Drift ##

Note that this method is untested since the code was updated to use datetimes rather than datenums.