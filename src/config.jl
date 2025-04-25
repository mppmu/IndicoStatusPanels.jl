# This file is a part of IndicoStatusPanels.jl, licensed under the MIT License (MIT).

function load_config()
    appdir = dirname(dirname(pathof(@__MODULE__)))
    assetdir = joinpath(appdir, "assets")
    tmpassetdir = mktempdir(prefix = "IndicoStatusPanels-cache-")

    api_token = String(@load_preference("indico_api_token"))
    indico_url = String(@load_preference("indico_base_url"))
    webapp_ip = String(@load_preference("webapp_ip"))
    webapp_port = Int(@load_preference("webapp_port"))
    webapp_userpwd = String(@load_preference("webapp_userpwd"))
    page_reload_interval = Int(@load_preference("page_reload_interval"))
    local_tz = TimeZone(@load_preference("local_timezone"))
    override_time = String(@load_preference("override_time"))
    code_reloading = Bool(@load_preference("code_reloading"))

    rm(tmpassetdir, recursive=true)
    mkpath(tmpassetdir)
    
    return (;
        assetdir, tmpassetdir,
        api_token, indico_url,
        webapp_ip, webapp_port, webapp_userpwd,
        page_reload_interval, local_tz, override_time,
        code_reloading
    )
end

const config = ScopedValue(load_config())
