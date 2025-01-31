# This file is a part of IndicoStatusPanels.jl, licensed under the MIT License (MIT).

format_hh_mm(dt::DateTime) = Dates.format(dt, "HH:MM")

format_event_time(evtinfo::NamedTuple) = format_hh_mm(evtinfo.t_start) * " to " * format_hh_mm(evtinfo.t_end)

function evt_tbl_row(evtinfo::NamedTuple)
    @htl("""<tr><td>$(format_event_time(evtinfo))</td><td>$(evtinfo.title)</td></tr>""")
end


function roominfo_page(location::AbstractString, room::AbstractString)
    roomid = parse(Int, room)
    page_reload_interval = config[].page_reload_interval

    current_dt = local_datetime()
    data = try
        indico_roominfo(location, roomid, current_dt)
    catch err
        return HTTP.Response(500, "Error getting room information from Indico")
    end

    room_name = data.roominfo.name
    (;current_event, next_events) = data

    current_event_section = if isnothing(current_event)
        @htl("""
            <section class="no-current-event-info">
                <h2 id="no-current-event" class="current-event-title">Room is free</h2>
                <p id="how-to-reserve" class="current-event-time">Use Indico to book room.</p>
            </section>
        """)
    else
        @htl("""
            <section class="current-event-info">
                <h2 id="current-event" class="current-event-title">$(current_event.title)</h2>
                <p id="current-event-time" class="current-event-time">$(format_event_time(current_event))</p>
            </section>
        """)
    end

    upcoming_events_section = if isempty(next_events)
        @htl("""
            <section class="no-upcoming-events-info">
                <h2 id="no-upcoming-events">No upcoming events</h2>
            </section>
        """)
    else
        @htl("""
            <section class="upcoming-events-info">
                <h2 id="upcoming-events">Upcoming Events</h2>
                <table class="event-table">
                <thead id="events-table-header">
                    <tr>
                    <th>Time</th>
                    <th>Title</th>
                    </tr>
                </thead>
                <tbody id="events-table">
                $((evt_tbl_row(e) for e in next_events))
                </tbody>
                </table>
            </section>
        """)
    end

    @htl("""
        <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta http-equiv="refresh" content="$page_reload_interval">
                <title>Room Status $room_name</title>
                <link rel="stylesheet" href="/roomdisplay.css">
            </head>
            <body>
                <header class="room-name">
                    <h1>Room $room_name</h1>
                </header>
                $current_event_section
                $upcoming_events_section
            </body>
        </html>
    """)
end


request_log = []

function webapp_servefunc(req::HTTP.Request)
    # For debugging:
    # push!(request_log, req)
    
    method = req.method
    uri = HTTP.URI(req.target)
    splitpath = split_uri_path(uri)

    qpars = queryparams(uri)
    authenticated = if haskey(qpars, "auth")
        if qpars["auth"] == config[].webapp_userpwd
            true
        else
            return HTTP.Response(401, "Invalid authentication")
        end
    else
        false
    end

    @info "HTTP Request $(authenticated ? "authenticated" : "unauthenticated") $method \"$uri\""
    # @info "DEBUG" uri path string(String.(splitpath)) assetpath

    if method == "GET"
        if splitpath == [""]
            return HTTP.Response(200, "Indico event status server")
        elseif splitpath[1] == "room" && length(splitpath) == 3
            location = splitpath[2]
            room = splitpath[3]
            # return HTTP.Response(200, "Requested room status for location $location, room $room.")
            return html_response(roominfo_page(location, room))
        elseif isasset(splitpath)
            return serve_asset(splitpath)
        else
            return no_such_page(uri)
        end
    elseif method == "POST"
        return HTTP.Response(403, "Forbidden")
    else
        return HTTP.Response(405, "Method $method not allowed")
    end
end
