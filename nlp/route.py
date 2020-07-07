from nlp import api
from nlp.api import EntityModelView, ClassifierModelView

api.add_resource(EntityModelView, '/parse/')
api.add_resource(ClassifierModelView, '/classify/')
