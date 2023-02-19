%% config = get_config(cruise,varargin)
%
% Run the cruise's configuration file, fill with default values where necessary,
% and scan for missing configuration options

function config = get_config(cruise,vessels,deployments)

arguments (Input)
    cruise (1,:) char 
    vessels {mustBeText} = {}
    deployments {mustBeText} = {}
end

arguments (Output)
    config (:,1) DeploymentConfiguration
end

%% Setup
% Get cruise configuration
cruise_file = fullfile(['Cruise_' cruise],['config_' cruise '.m']);
if isfile(cruise_file)
    config = feval(['config_' cruise]);
else
    error('Cannot find file: %s.m',cruise_file)
end

% Limit to vessel(s), if specified
if ~isempty(vessels)
    if ~iscell(vessels)
        vessels = {vessels};
    end
    config = config(ismember({config.vessel},vessels));
end

% Limit to deployment(s), if specified
if ~isempty(deployments)
    if ~iscell(deployments)
        deployments = {deployments};
    end
    config = config(ismember({config.name},deployments));
end

% validate configuration
config.validate_config()