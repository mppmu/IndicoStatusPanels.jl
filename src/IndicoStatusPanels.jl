# This file is a part of IndicoStatusPanels.jl, licensed under the MIT License (MIT).

"""
    IndicoStatusPanels

[Indico](https://getindico.io/) event information webapp server in Julia.

Shows room status, current and upcoming events for conference/seminar rooms
and similar, based on information retrieved from an Indico event management
system (via the Indico REST API). Intended to be displayed on small screens
next to room doors.
"""
module IndicoStatusPanels

using Base.ScopedValues

using Dates
using Sockets: getipaddr

using Preferences: @load_preference
import HTTP
import JSON
using StructArrays: StructArray
using URIs: URI, queryparams
using MIMEs: mime_from_extension
using TimeZones: TimeZones, ZonedDateTime, astimezone, @tz_str
using HypertextLiteral: HypertextLiteral, @htl

include("config.jl")
include("indico_api.jl")
include("webtools.jl")
include("panel_contents.jl")
include("panel_server.jl")

end # module IndicoStatusPanels
