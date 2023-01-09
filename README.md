# SUNRISE2022_TCHAIN

# TODO 
- [ ] Organise sensor metadata (serial numbers, depths, etc.) into a consistent and usable format

# SUNRISE2022 T-Chain Processing
The T-chain data is being processed with Dylan Winter's BowChain processing code https://github.com/dswinters/BowChain

All the raw and processed data will be available from a google drive

## Filepaths
This code is intended to be used many different people. Therefore, hardcoding filepaths must be avoided. To facilitate this the code 
utilises the directory structure specified in the google drive. However, we must still provide the base directory containing our copy 
of the google drive. This is done by reading the environment variable `SUNRISE2022_TCHAIN_DATA`.
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
                 └── deployment_info.csv
         └── processed_nc
         └── sections
     └── Pelican
         └── raw
         └── processed_nc
         └── sections
     ...
```
_raw_mat_ contains the raw sensor data as parsed by the rbr toolbox. The code refers to these directories as _dir_proc_.

_processed_nc_ contains netcdfs with the processed deployment data, i.e. the output of the BowChain processing code, for analysis in one's language of choice.

_sections_ contains the processed data divided into sections.

## Google Drive
- [ ] Add link to google drive
- [ ] Rclone stuff
