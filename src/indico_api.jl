# This file is a part of IndicoStatusPanels.jl, licensed under the MIT License (MIT).

# Indico API documentation:
# https://docs.getindico.io/en/latest/http-api/access/
# https://docs.getindico.io/en/latest/http-api/exporters/

# Relevant Indico API endpoints:
#
# /export/event/<event_id>.json?occ=yes&pretty=yes
# /export/reservation/<location>.json?detail=reservation&from=yesterday&to=tomorrow&pretty=yes
# /export/room/<location>/<room_id>.json?detail=reservations&from=yesterday&to=tomorrow&pretty=yes
#
# Note: Use `from=yesterday` and `to=tomorrow` instead of using `today`. Server/system time zone
# settings may be incorrect, so depending on the current time of day, Indico may not return all
# events if querying only events for `today`.


function local_datetime()
    local_tz = config[].local_tz
    override_time = config[].override_time
    if isempty(override_time)
        return DateTime(astimezone(ZonedDateTime(unix2datetime(time()), tz"UTC"), local_tz))
    else
        return DateTime(override_time)
    end
end

function indico_room_uri(location::AbstractString, room::AbstractString)
    indico_url = config[].indico_url
    return "$indico_url/rooms/rooms?modal=room-details%3A$room"
end


function indico_get(relative_url::AbstractString)
    indico_url = config[].indico_url
    api_token = config[].api_token
    response = HTTP.get("$indico_url/$relative_url", ["Authorization" => "Bearer $api_token"])
    return JSON.parse(String(response.body))
end

function indicodt2localdt(dt::AbstractDict)
    local_tz = config[].local_tz
    date = String(dt["date"])
    time = String(dt["time"])
    tz = String(dt["tz"])
    zdt = ZonedDateTime(DateTime("$(date)T$(time)"), TimeZone(tz))
    ldt = DateTime(astimezone(zdt, local_tz))
    # udt = astimezone(zdt, tz"UTC")
    # uxt = datetime2unix(DateTime(udt))
    return ldt
end


"""
    indico_roominfo(location::AbstractString, room_id::Integer, current_dt::DateTime)

Get room information and current and upcoming events for `room` (numerical
Indico room id) at `location` (Indico location name) at the time `current_dt`.

All times are given and returned in the local time zone.
"""
function indico_roominfo(location::AbstractString, room_id::Integer, current_dt::DateTime)
    response = indico_get("export/room/$location/$room_id.json?detail=reservations&from=yesterday&to=tomorrow&pretty=yes")

    if length(response["results"]) != 1
        throw(ErrorException("Can't access Indico room information for location \"$location\" and room ID $room_id"))
    end
    result = only(response["results"])

    roomname = String(result["fullName"])::String
    r_room_id = Int(result["id"])::Int
    r_location = String(result["location"])::String

    @assert r_room_id == room_id
    @assert r_location == location

    roominfo = (
        name = roomname,
        id = r_room_id,
        location = r_location,
    )

    reservations = result["reservations"]

    t_starts = DateTime[]
    t_ends = DateTime[]
    titles = String[]

    for r in reservations
        start_dt = indicodt2localdt(r["startDT"])
        end_dt = indicodt2localdt(r["endDT"])
        title = String(r["reason"])
        repeat = String(r["repeat_frequency"])

        time_today(datetime::DateTime) = DateTime(Date(current_dt), Time(datetime))
        time_today(time::Time) = DateTime(Date(current_dt), time)

        if repeat == "NEVER"
            happening_today = Date(start_dt) <= Date(current_dt) <= Date(end_dt)
            t_start = Date(start_dt) < Date(current_dt) ? time_today(Time(0)) : time_today(start_dt)
            t_end = Date(end_dt) > Date(current_dt) ? time_today(Time(23, 59, 59)) : time_today(end_dt)
        elseif repeat == "DAY"
            happening_today = Date(start_dt) <= Date(current_dt) <= Date(end_dt)
            t_start = time_today(start_dt)
            t_end = time_today(end_dt)
        elseif repeat == "WEEK"
            happening_today = (Date(current_dt) - Date(start_dt)) % Day(7) == Day(0)
            t_start = time_today(start_dt)
            t_end = time_today(end_dt)
        else
            @error "Unsupported event repeat interval specification \"$repeat\""
            happening_today = false
            t_start = time_today(Time(0))
            t_end = time_today(Time(0))
        end
        if happening_today && current_dt <= t_end
            push!(t_starts, t_start)
            push!(t_ends, t_end)
            push!(titles, title)
        end
        # @debug "indico_roominfo reservation" start_dt end_dt title repeat happening_today
    end

    events_today = StructArray((t_start = t_starts, t_end = t_ends, title = titles))
    reservations = sort(events_today, by=(r -> r.t_start))

    current_event, next_events = if isempty(reservations)
        (nothing, reservations)
    else
        first_res = reservations[begin]
        if first_res.t_start <= current_dt <= first_res.t_end
            (first_res, reservations[2:end])
        else
            (nothing, reservations)
        end
    end

    return (
        roominfo = roominfo,
        current_event = current_event,
        next_events = next_events,
    )
end

export indico_roominfo
