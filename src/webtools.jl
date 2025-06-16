# This file is a part of IndicoStatusPanels.jl, licensed under the MIT License (MIT).


split_uri_path(uri::URI) = split(strip(uri.path, '/'), '/')

no_such_page(uri::HTTP.URI) = HTTP.Response(404, "No such page: $uri")


function assetpath(splitpath::Vector{<:AbstractString})
    assetdir = config[].assetdir
    filename = normpath(joinpath(assetdir, splitpath...))
    if startswith(filename, joinpath(assetdir, "")) && isfile(filename)
        return filename
    else
        return nothing
    end
end

isasset(splitpath::Vector{<:AbstractString}) = !isnothing(assetpath(splitpath))

function serve_asset(splitpath::Vector{<:AbstractString})
    filename = assetpath(splitpath)
    if isnothing(filename)
        return HTTP.Response(403, "Forbidden")
    else
        mime = mime_from_extension(splitext(filename)[2])
        contents = read(filename)
        return HTTP.Response(200, ["Content-Type" => mime], contents)
    end
end


function html_response(content::HypertextLiteral.Result)
    full_content = "<!DOCTYPE html>\n" * string(content)
    HTTP.Response(200, ["Content-Type" => MIME("text/html"), "charset" => "utf-8"], full_content)
end
