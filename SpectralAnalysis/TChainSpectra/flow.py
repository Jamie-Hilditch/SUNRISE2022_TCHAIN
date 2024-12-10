"""Classes and functions for computing the flow past each sensor"""

import os
from typing import Protocol

import numpy as np
import xarray as xr
from numpy.typing import NDArray
from scipy.interpolate import RegularGridInterpolator


class FlowPastSensor(Protocol):
    def flow_past_sensor(self, dt: NDArray[np.datetime64], z: NDArray[np.float64]) -> NDArray[np.float64]:
        """Get the flow past a sensor at times dt and depths z
        
        Arguments:
            dt: array of times of shape (Ntimes,)
            z: array of z of shape (Ntimes,Nsensors)

        Outputs:
            U: array of flow speed past each sensor of shape (Ntimes,Nsensors)
        """

class UHDAS_netcdf:

    def __init__(self,filepath: os.PathLike | str, depths_time_index: int = 0) -> None:
        """Get flow past the sensors from UHDAS ADCP
        
        Arguments:
            filepath: path to ADCP netcdf file
            depths_time_index: time index to get depths which we assume to be constant
        """
        self.filepath = filepath 
        dataset = xr.open_dataset(filepath)

        # make sure time is monotonic
        dataset = dataset.drop_duplicates(dim='time')

        # assume depths do not change
        depths = dataset.depth.isel(time=depths_time_index)
        dataset = dataset.where(dataset.depth==depths)
        if np.mean(np.isnan(dataset.depth)) > 0.1:
            raise ValueError(r'More than 10% of depths are nan')

        # compute the flow past the sensor
        dataset['U'] = dataset.u - dataset.uship
        dataset['V'] = dataset.v - dataset.vship
        
        # fill in nans
        dataset['U'] = dataset.U.interpolate_na(dim='time', use_coordinate=True)
        dataset['V'] = dataset.V.interpolate_na(dim='time', use_coordinate=True)

        # create a regular grid interpolator
        self.time_offset = dataset.time.isel(time=0).values
        seconds = (dataset.time.values - self.time_offset)/np.timedelta64(1,'s')
        depths = depths.values
        self.U = RegularGridInterpolator((seconds,depths),dataset.U.values,
                                         method='linear',bounds_error=False, fill_value=None)
        self.V = RegularGridInterpolator((seconds,depths),dataset.V.values,
                                         method='linear',bounds_error=False, fill_value=None)
   
    def flow_past_sensor(self, dt: NDArray[np.datetime64], z: NDArray[np.float64]) -> NDArray[np.float64]:
        """Get the flow past a sensor at times dt and depths z
        
        Arguments:
            dt: array of times of shape (Ntimes,)
            z: array of z of shape (Ntimes,Nsensors)

        Outputs:
            U: array of flow speed past each sensor of shape (Ntimes,Nsensors)
        """

        # get shape 
        shape = z.shape

        # convert to seconds and depths for interpolator
        depths = -z 
        seconds = (dt - self.time_offset)/np.timedelta64(1,'s')
        seconds = np.broadcast_to(seconds,shape)
        xi = np.column_stack((np.ravel(seconds),np.ravel(depths)))

        # get flow past sensor
        U = self.U(xi)
        V = self.V(xi)
        flow = np.sqrt(U**2 + V**2)
        return np.reshape(flow,shape)


class OneFlow:
    def flow_past_sensor(self, dt: NDArray[np.datetime64], z: NDArray[np.float64]) -> NDArray[np.float64]:
        """Get the flow past a sensor at times dt and depths z
        
        Arguments:
            dt: array of times of shape (Ntimes,)
            z: array of z of shape (Ntimes,Nsensors)

        Outputs:
            U: array of flow speed past each sensor of shape (Ntimes,Nsensors)
        """

        return np.ones_like(z)
