import falcon
 
class Demo:
    def on_get(self, req, resp):
        resp.body = 'Hello, world!'
 
app = falcon.API()
app.add_route('/', Demo())
