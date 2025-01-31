# This file is a part of IndicoStatusPanels.jl, licensed under the MIT License (MIT).

function run_panel_server_currentconfig()
    webapp_ip = config[].webapp_ip
    real_ip = webapp_ip == "0.0.0.0" ? getipaddr() : webapp_ip
    webapp_port = config[].webapp_port
    userpwd = config[].webapp_userpwd
    @info "Point web browser to http://$(real_ip):$(webapp_port)/room/<LOCATION>/<ROOM_ID>?auth=$(userpwd)"
    HTTP.serve(webapp_servefunc, config[].webapp_ip, config[].webapp_port)
end

function run_panel_server_impl()
    ScopedValues.with(
        run_panel_server_currentconfig,
        config => IndicoStatusPanels.load_config()
    )
end


const panel_server_task = Ref{Task}()

"""
    start_panel_server()

Spawn panel server in a Julia task.
"""
function start_panel_server()
    task = Base.Threads.@spawn run_panel_server_impl()
    panel_server_task[] = task
    return task
end
export start_panel_server


"""
    stop_panel_server()

Stop spawned panel server.
"""
function stop_panel_server()
    if isassigned(panel_server_task)
        task = panel_server_task[]
        if !istaskdone(task)
            @info "Stopping panel server."
            schedule(task, :stop, error=true)
            try
                wait(task) 
            catch err
                err isa TaskFailedException || throw(err)
            end
            @info "Panel server stopped."
            return true
        else
            return false
        end
    else
        return false
    end
end
export stop_panel_server


"""
    restart_panel_server(start_if_not_running::Bool = true)

(Re-)spawn panel server in a Julia task.
"""
function restart_panel_server(start_if_not_running::Bool = true)
    if stop_panel_server() || start_if_not_running
        start_panel_server()
    end
end
export restart_panel_server


"""
    run_panel_server()

Run panel server in a blocking fashion.

If

in a Julia task, then block and use Revise.jl to hot-reload
changed code.

Terminate with Ctrl-C.
"""
function run_panel_server()
    if load_config().code_reloading
        @eval begin
            import Revise
        end
        Revise.entr(
            restart_panel_server, [], [],
            postpone = false, all = true, pause = 0.25
        )
        stop_panel_server()
    else
        run_panel_server_impl()
    end
end
export run_panel_server
