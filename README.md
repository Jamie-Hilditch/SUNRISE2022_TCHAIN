# SUNRISE2022 T-Chain Processing
The T-chain data is being processed with a lightly modified version of Dylan Winter's BowChain processing code https://github.com/dswinters/BowChain

## Google Drive
All the raw and processed data is available in this Google drive.

T-Chain Google drive: https://drive.google.com/drive/folders/0ANMrD9nACU92Uk9PVA

I highly recommend using rclone to move data to and from the Google drive https://rclone.org/drive/


## Filepaths
This code is intended to be used many different people. Therefore, hardcoding filepaths must be avoided. To facilitate this the code 
utilises the directory structure specified in the Google drive. However, we must still provide the base directory containing our copy 
of the Google drive. This is done by reading the environment variable `SUNRISE2022_TCHAIN_DATA`.
- Environment variables can be set at the MATLAB command line using `setenv`
- e.g. `>> setenv('SUNRISE2022_TCHAIN_DATA','pathToMyData');`

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

_processed_nc_ contains netcdfs with the processed deployment data, i.e. the output of the BowChain processing code, for analysis in one's language of choice.

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
- However, some of these values have been changed during processing

# TODO 
- [ ] Correct catenary code!!!
- [ ] Finish time offsets and chain models
- [ ] Make section files

## Issues
### Pelican
| Deployment | Sensor | Issue                                                                                 |
| :--------: | :----: | :------------------------------------------------------------------------------------ |
| 2022-06-20 | 60559  | Data ends midway through deployment                                                   |
| 2022-06-24 | 101161 | Data missing                                                                          |
| 2022-06-25 | 60558  | Data ends midway through deployment                                                   |
| 2022-06-25 | 207009 | Data ends midway through deployment                                                   |
| 2022-06-25 | 60183  | Data ends midway through deployment                                                   |
| 2022-06-25 |        | These are all pressure sensors. Can compute pressure offset but not time offset. Should we use them for fitting the chain model?                                                                      |
| 2022-06-28 | 100162 | Data ends slightly before end of the deployment                                       |
| 2022-07-05 |        | Can't find dunk. Can we improve time offsets?                                         |