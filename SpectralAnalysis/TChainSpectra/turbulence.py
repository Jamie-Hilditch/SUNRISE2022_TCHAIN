"""Estimate turbulence quantities from inertial-convective subrange fits"""

import numpy as np
import xarray as xr
from numpy.polynomial.polynomial import Polynomial

# define some constants
CT = 0.4  # Obukhov-Corrsin constant
Γ = 0.2  # Mixing efficiency

def Tz_fit(z,T):
    series = Polynomial.fit(z,T,1)
    return series.convert().coef[-1]  

def average_spectra(spectra_subset: xr.Dataset,*, β: float = 4/3, wave_contamination: bool = True) -> xr.Dataset:
    """Average together some spectra assuming U^(4/3) dependence
    
    Arguments:
        spectra_subset: a subset of the computed spectra to be average together
        β: assumed dependence on U
        wave_contamination: subtract off the part of the spectrum coherent with the surface waves
    """

    # compute the average
    subset_average = spectra_subset.mean(dim="time")
    
    # get environment spectra
    if wave_contamination:
        # subtract off the part of the spectrum coherent with the surface gravity waves
        subset_average['gamma'] = np.abs(subset_average.Phi_Txw)**2/(subset_average.Phi_w*subset_average.Phi_Tx)
        Phi_Tx = spectra_subset.Phi_Tx*(1 - subset_average.gamma)
    else:
        Phi_Tx = spectra_subset.Phi_Tx

    # multiply through by (U/2pi)^β
    spectra_subset['Phi_f'] = Phi_Tx*(spectra_subset.U/(2*np.pi))**β

    # get the average spectra
    subset_average['Phi_f'] = spectra_subset.Phi_f.mean(dim='time')

    return subset_average

def fit_inertial_subrange(average_spectrum: xr.Dataset, fmin: float,fmax: float) -> xr.Dataset:
    """Log fit to the inertial-convective subrange assuming f^1/3 slope
    
    Arguments:
        average_spectum: computed tchain spectra
        fmin: lower bound of fitting range
        fmax: upper bound of fitting range
    """

    # get bandwidth to fit to
    spectrum = average_spectrum.sel(frequency=slice(fmin,fmax))

    # assume log-normal error
    error = np.log(spectrum.Phi_f/spectrum.frequency**(1/3))

    # linear regression reduces to mean over frequency
    average_spectrum['m'] = error.mean(dim='frequency')
    average_spectrum['std'] = error.std(dim='frequency')
    average_spectrum['M'] = np.exp(average_spectrum.m)

    return average_spectrum
