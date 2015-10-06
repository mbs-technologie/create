import webapp2

from google.appengine.ext import db

def respond(response, text):
    response.headers['Content-Type'] = 'text/plain'
    response.write(text)

class DefaultPage(webapp2.RequestHandler):
    def get(self):
        respond(self.response, 'Ok')

SET_PARAM = 'set'
ID_PARAM = 'id'
DEFAULT_STORE = 'default'

class Datastore(db.Model):
    state = db.TextProperty()

def getstore(request):
    if request.params.has_key(ID_PARAM):
        return request.params[ID_PARAM]
    else:
        return DEFAULT_STORE

def putdata(datakey, newstate):
    d = Datastore(key_name = datakey, state = newstate)
    d.put()

def getdata(datakey):
    d = db.get(db.Key.from_path('Datastore', datakey))
    if d is None:
        return 'none'
    else:
        return d.state

class DataPage(webapp2.RequestHandler):
    def get(self):
        if self.request.params.has_key(SET_PARAM):
            newstate = self.request.params[SET_PARAM]
            putdata(getstore(self.request), newstate)
            respond(self.response, 'Set to: ' + newstate)
        else:
            respond(self.response, getdata(getstore(self.request)))

    def put(self):
        putdata(getstore(self.request), self.request.body)
        respond(self.response, 'Done')

app = webapp2.WSGIApplication([
    ('/', DefaultPage),
    ('/data', DataPage),
], debug=True)
