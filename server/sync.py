import webapp2

def respond(response, text):
    response.headers['Content-Type'] = 'text/plain'
    response.write(text)

class DefaultPage(webapp2.RequestHandler):
    def get(self):
        respond(self.response, 'Ok')

class DataPage(webapp2.RequestHandler):
    def get(self):
        respond(self.response, 'Data')

app = webapp2.WSGIApplication([
    ('/', DefaultPage),
    ('/data', DataPage),
], debug=True)
