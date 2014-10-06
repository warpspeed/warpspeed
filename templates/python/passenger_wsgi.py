def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/plain')])
    return ["Warpspeed says hello, from Python!"]

# For django, use the following (where myproject is the name of your project):
# import myproject.wsgi
# application = myproject.wsgi.application
