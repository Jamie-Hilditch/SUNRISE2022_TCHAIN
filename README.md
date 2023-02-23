# SUNRISE2022 T-Chain Processing
The T-chain data is being processed with an updated version of Dylan Winter's BowChain processing code https://github.com/dswinters/BowChain

## Google Drive
All the raw and processed data is available in this Google drive.

T-Chain Google drive: https://drive.google.com/drive/folders/0ANMrD9nACU92Uk9PVA

I highly recommend using rclone to move data to and from the Google drive https://rclone.org/drive/


## Filepaths
This code is intended to be used many different people. Therefore, hardcoding filepaths must be avoided. To facilitate this, the code 
utilises the directory structure specified in the Google drive. However, we must still provide the base directory containing our copy 
of the Google drive. This is done by reading the environment variable `SUNRISE2022_TCHAIN_DATA`.
- Environment variables can be set at the MATLAB command line using `setenv`
- e.g. `>> setenv('SUNRISE2022_TCHAIN_DATA',pathToMyData);`

The directory structure defined inside the google drive is
```
SUNRISE2022_TCHAIN_DATA
    └── Aries
        └── raw
            └── deploy_YYYYMMDD
                 └── raw_rsk
                 └── raw_mat
                 └── metadata.json
                 └── sensors.csv
         └── processed_nc
         └── sections
         └── processing_figures
     └── Pelican
         └── raw
         └── processed_nc
         └── sections
         └── processing_figures
     ...
```
_raw_mat_ contains the raw sensor data as parsed by the rbr toolbox. The code refers to these directories as _dir_proc_.

_processed_nc_ contains netcdfs with the processed deployment data, i.e. the gridded but not binned output of the BowChain processing code, for analysis in one's language of choice.

_sections_ contains the processed data divided into sections.

_processing_figures_ contains figures created while processing the data 

## Metadata and sensor data
- _metadata.json_ contains the deployment duration and the zero pressure interval which are both required by the BowChain config.
- _sensors.csv_ contains the depths, serial numbers and instrument types of the sensors on the chain during each deployment.

JSON (JavaScript Object Notation) is a lightweight human-readable data format. Here is an example of _metadata.json_ 
```json
{
    "deployment_name": "deploy_20220624",
    "deployment_duration": ["2022-06-25 00:28", "2022-06-25 13:19"],
    "zero_pressure_interval": ["2022-06-25 01:00", "2022-06-25 01:10"],
    "dunk_interval": ["2022-06-25 01:14:26", "2022-06-25 01:17:22"],
    "time_base_sensor_sn": "60281"
}
```
Metadata is stored as key-value pairs. Time intervals are written as an array of date strings formatted as `YYYY-MM-DD HH:MM` or `YYYY-MM-DD HH:MM:SS` so that MATLAB can parse them as datetimes.

- Most of this data was copied manually from the records kept on the ship (this data is all over the place in the main NIW_GoM Google drive but is collated in files called something like Deployment_Info.csv. 
- A copy of the source file for the data in _metadata.json_ and _sensors.csv_ can be found in the vessel's _raw_ directory) so first check any suspicious values against the ship records. 
- Some of these values have been changed during processing

# TODO 
- [ ] Time offsets and clock drifts on Aries deployments (except 2022-07-03)
- [ ] Rest of the processing of Aries deployments (except 2022-07-03)
- [ ] Add "in water" times to the metadata. It's useful for the deployment duration to include the dunk and zero pressure intervals but we want to exclude this data from the section files.
- [ ] Then recreate section files 
- [ ] Write documentation for changes

## Issues

### Aries
| Deployment | Sensor | Issue                                                                                 | Action                                                                     |
| :--------: | :----: | :------------------------------------------------------------------------------------ | :------------------------------------------------------------------------- |
| 2022-06-19 | 60704  | Clock drifts by around 90 minutes during deployment                                   |                                                                            |
| 2022-06-19 |        | No dunk to compute time offsets however clocks appear to be synchronised              |                                                                            |
| 2022-06-21 | 60704  | Clock starts early and continues to drift during deployment                           |                                                                            |
| 2022-06-21 |        | Again no dunk - clocked appear synchronised but not as well as before                 |                                                                            |
| 2022-06-22 | 203187 | Data ends early in deployment                                                         |                                                                            |
| 2022-06-22 | 203188 | Data ends early in deployment                                                         |                                                                            |
| 2022-06-22 | 60704  | Clock is ~2 hours out of sync                                                         |                                                                            |
| 2022-06-22 |        | 2/4 duets and the concerto with issues - not good for fitting depths                  |                                                                            |
| 2022-06-25 | 203187 | No pressure data                                                                      |                                                                            |
| 2022-06-25 | 60701  | Clock starts out of sync and drifts severally                                         |                                                                            |
| 2022-06-25 |        | No dunk - clocks appear to be out of sync by a few seconds                            |                                                                            |
| 2022-06-28 |        | No dunk - clocks appear to be out of sync by a few seconds                            |                                                                            |
| 2022-07-03 | 203188 | Spikey pressure signal towards the end of the deployment                              | Applied a despiking algorithm in post_load_hook                            |

### Pelican
| Deployment | Sensor | Issue                                                                                 | Action                                                                     |
| :--------: | :----: | :------------------------------------------------------------------------------------ | :------------------------------------------------------------------------- |
| 2022-06-20 | 60559  | Data ends midway through deployment                                                   | Clock appears synchronised so no time offset applied                       |
| 2022-06-24 | 101161 | No raw files                                                                          |                                                                            |
| 2022-06-24 | 100698 | No raw files                                                                          |                                                                            |
| 2022-06-25 | 60558  | Data ends midway through deployment                                                   |                                                                            |
| 2022-06-25 | 60558  | Zero pressure interval does not match rest of the pressure sensors                    | Set pressure offset in post_offsets_hook using an alternative interval     |
| 2022-06-25 | 207009 | Data ends midway through deployment                                                   |                                                                            |
| 2022-06-25 | 60183  | Data ends midway through deployment                                                   |                                                                            |
| 2022-06-25 |        | These are all pressure sensors. Need time offsets to to fit depths.                   | TODO: manually fix time offsets in post_offsets_hook                       |
| 2022-06-28 | 100162 | Data ends slightly before end of the deployment                                       |                                                                            |
| 2022-07-05 |        | Can't find dunk.                                                                      | Can we improve time offsets?                                               |

### Point Sur
Only 3 pressure sensors so catenary fit (which requires 3 points) is sensitive to noise. However, the bottom weight is so heavy that we could use a linear fit. Alternatively, just smooth the resulting z data.

| Deployment | Sensor | Issue                                                                                 | Action                                                                     |
| :--------: | :----: | :------------------------------------------------------------------------------------ | :------------------------------------------------------------------------- |
| 2022-06-21 | 207031 | No raw files                                                                          |                                                                            |

### Polly
| Deployment | Sensor | Issue                                                                                 | Action                                                                     |
| :--------: | :----: | :------------------------------------------------------------------------------------ | :------------------------------------------------------------------------- |
| 2022-06-20 | 60703  | Data starts very late in deployment                                                   |                                                                            |
| 2022-06-20 | 101195 | Data is timestamped July 2021                                                         |                                                                            |
| 2022-06-20 | 100024 | Data is timestamped July 2021                                                         |                                                                            |
| 2022-06-26 | 60703  | No raw files (perhaps removed from chain after previous issue)                        |                                                                            |
| 2022-06-26 | 77565  | Temperature values are way off after 2022-07-01 19:14:58                              | Replaced this data with NaNs in post_load_hook, manually set time offset   |
| 2022-07-02 | 60703  | No raw files                                                                          |                                                                            |
| 2022-07-02 | 207055 | Data ends before deployment                                                           |                                                                            |
