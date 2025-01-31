# IndicoStatusPanels.jl

[Indico](https://getindico.io/) event information webapp server in Julia.

## Setup

Run

```shell
git clone https://github.com/mppmu/IndicoStatusPanels.jl.git
```

to clone this repository to your system (to the current directory).

Copy `LocalPreferences.toml-template` to `LocalPreferences.toml` and set
`indico_api_token` and `indico_base_url` (and adjust other settings as
needed).

## Running

Then run

```shell
julia path/to/IndicoStatusPanels/run_panel_server.jl
```

or (on Posix systems) simply

```shell
path/to/IndicoStatusPanels/run_panel_server.jl
```

This will set this directory as the active Julia project and instantiate it,
downloading necessary dependencies to the current Julia package depot as
required. On the first run, this may take a few minutes. As a result, a
`Manifest.toml` file will be created in the `IndicoStatusPanels` directory.
Delete this file to force re-instantiation with the latest versions of all
dependencies.

Set the environment variable `$JULIA_DEPOT_PATH` to make Julia install
dependencies in a location of your choice (default is `$HOME/.julia`).

If `code_reloading=true` is set in `LocalPreferences.toml`, the server will
monitor the `src` directory and hot-reload code changes (but not changes to
preferences) via Revise.jl.

Note for Julia developers: IndicoStatusPanels is a full (unregistered) Julia
package and can also be used in other Julia project environments,
`run_panel_server.jl` is just a convenience script.
