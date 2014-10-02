app = proc do |env|
    [200, { "Content-Type" => "text/html" }, ["Warpspeed says hello, from Ruby!"]]
end
run app
