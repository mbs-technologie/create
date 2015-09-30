import webapp2

from google.appengine.ext import db

def respond(response, text):
    response.headers['Content-Type'] = 'text/plain'
    response.write(text)

class DefaultPage(webapp2.RequestHandler):
    def get(self):
        respond(self.response, 'Ok')

DEFAULT_STORE = 'datastore'
SET_PARAM = 'set'

class Datastore(db.Model):
    state = db.TextProperty()

def putdata(datakey, newstate):
    d = Datastore(key_name = datakey, state = newstate)
    d.put()

def getdata(datakey):
    d = db.get(db.Key.from_path('Datastore', datakey))
    return d.state

class DataPage(webapp2.RequestHandler):
    def get(self):
        if self.request.params.has_key(SET_PARAM):
            newstate = self.request.params[SET_PARAM]
            putdata(DEFAULT_STORE, newstate)
            respond(self.response, 'Set to: ' + newstate)
        else:
            respond(self.response, getdata(DEFAULT_STORE))

    def put(self):
        putdata(DEFAULT_STORE, self.request.body)
        respond(self.response, 'Done')

app = webapp2.WSGIApplication([
    ('/', DefaultPage),
    ('/data', DataPage),
], debug=True)
