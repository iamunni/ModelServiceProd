from nlp import api
from nlp.api import EntityModelView, ClassifierModelView
from nlp.api import GetView

api.add_resource(EntityModelView, '/parse/')
api.add_resource(ClassifierModelView, '/classify/')
api.add_resource(GetView, '/get/')
