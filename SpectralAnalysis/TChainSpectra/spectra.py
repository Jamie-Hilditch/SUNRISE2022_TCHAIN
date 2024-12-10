"""Compute the T-Chain spectra"""

import numpy as np
import scipy.fft as sfft
import scipy.signal
import xarray as xr
from numpy.typing import NDArray

from .flow import FlowPastSensor

# define constant
FC = 0.255  # Transfer function constant

def fourier_transform(timeseries: NDArray[np.float64],*,detrend: bool = True, window: bool = True) -> NDArray[np.complex128]:
    """Compute the Fourier transform of a real timeseries

    Arguments:
        timeseries: array containing timeseries as last axis
        detrend: remove the linear part before computing fft
        window: pre-whiten with a normalised Hann window
    
    Outputs:
        Fourier transform 
    """

    if detrend:
        # detrend to remove linear part
        scipy.signal.detrend(timeseries,overwrite_data=True)

    if window:
        # pre-whiten with Hann window
        # get the normalised Hann window
        hann = scipy.signal.get_window('hann',timeseries.shape[-1],fftbins=False)
        hann /= np.sqrt(np.mean(hann**2))

        # broadcast the window to match the shape of timeseries
        hann = np.broadcast_to(hann,timeseries.shape)
        timeseries *= hann

    # Fourier transform
    return sfft.rfft(timeseries,overwrite_x=True)


    
def compute_tchain_spectra(section: xr.Dataset, flow: FlowPastSensor, nfft: int, overlap: int,*,
                            wave_contamination: bool = False, roll_off: bool = False) -> xr.Dataset:
    """Compute the T-chain frequency spectra
    
    Arguments: 
        section: an xarray dataset with a section of gridded T-chain data
        flow: an implementation of FlowPastSensor
        nfft: number of points to use to compute spectra
        overlap: number of points to overlap spectra by 
        wave_contamination: also compute w spectra and Tx,w cross-spectra 
        roll_off: correct for roll off using transfer function from Byung Ho (reference?)
    """

    # get the number of spectra we will be computing
    npoints = section.time.size
    nsensors = section.sensor_number.size
    step = nfft - overlap 
    if step <= 0: raise ValueError("nfft must be greater than overlap")
    nspectra = (npoints - nfft + 1)//step

    # get the frequencies
    freq_base = section.attrs['freq_base']
    f =  sfft.rfftfreq(nfft,1/freq_base)

    # preallocate arrays
    Tx_spectra = np.empty((nspectra,nsensors,nfft//2),dtype=np.float64)
    time = np.empty((nspectra),dtype='datetime64[ns]')
    z = np.empty((nspectra,nsensors),dtype=np.float64)
    lat = np.empty((nspectra,nsensors),dtype=np.float64)
    lon = np.empty((nspectra,nsensors),dtype=np.float64)
    U = np.empty((nspectra,nsensors),dtype=np.float64)
    if wave_contamination:
        wU_spectra = np.empty((nspectra,nsensors,nfft//2),dtype=np.float64)
        Txw_cross_spectra = np.empty((nspectra,nsensors,nfft//2),dtype=np.complex128)

    # compute the flow past the sensor and then temperature gradient
    section['U'] = xr.DataArray(flow.flow_past_sensor(section.time.values[:,None],section.z.values), dims=['time','sensor_number'])
    section['Tx'] = section.t.differentiate(coord='time',datetime_unit='s')/section.U
    
    # compute the vertical velocity of each sensor
    if wave_contamination:
        section['wU'] = section.z.differentiate(coord='time',datetime_unit='s')/section.U

    # iterate through spectra
    tidx = 0
    for ii in range(nspectra):  

        # get subset of section
        subset = section.isel(time=slice(tidx,tidx+nfft))

        # get array of data with time as last axis
        Tx = np.swapaxes(subset.Tx.values,subset.Tx.get_axis_num('time'),-1)

        # compute spectrum
        Tx_hat = fourier_transform(Tx,detrend=True,window=True)
        Tx_spectra[ii,:,:] = 2*np.abs(Tx_hat[:,1:])**2/nfft/freq_base

        if wave_contamination:
            wU = np.swapaxes(subset.wU.values,subset.wU.get_axis_num('time'),-1)

            # compute spectrum
            wU_hat = fourier_transform(wU,detrend=True,window=True)          
            wU_spectra[ii,:,:] = 2*np.abs(wU_hat[:,1:])**2/nfft/freq_base

            # compute the cross spectrum 
            Txw_cross_spectra[ii,:,:] = 2*Tx_hat[:,1:]*np.conj(wU_hat[:,1:])/nfft/freq_base

        # compute mean quantities over time range 
        z[ii,:] = subset.z.mean(dim='time')
        lat[ii,:] = subset.lat.mean(dim='time')
        lon[ii,:] = subset.lon.mean(dim='time')
        U[ii,:] = subset.U.mean(dim='time')
        time[ii] = subset.time.mean().values
        
        # increment time index
        tidx += step

    # end ii loop

    # transfer function for high wavenumber attenuation
    if roll_off:
        tf = (1 + (f[1:]/FC)**2)

        Tx_spectra *= tf
        if wave_contamination:
            w_spectra *= tf 
            Txw_cross_spectra *= tf

    # output results as an xarray dataset
    coords = {
        "time": time,
        "frequency": f[1:],
    }

    data = {
        "z": (["time","sensor_number"],z),
        "lat": (["time","sensor_number"],lat),
        "lon": (["time","sensor_number"],lon),
        "U": (["time","sensor_number"],U),
        "Phi_Tx": (["time","sensor_number","frequency"],Tx_spectra)
    } 
    
    if wave_contamination:
        data['Phi_w'] = (["time","sensor_number","frequency"],wU_spectra)
        data['Phi_Txw'] = (["time","sensor_number","frequency"],Txw_cross_spectra)
    
    return xr.Dataset(data,coords)