app = proc do |env|
    [200, { "Content-Type" => "text/html" }, ["WarpSpeed says hello, from Ruby!"]]
end
run app
