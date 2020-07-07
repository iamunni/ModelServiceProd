import os
from flask import Flask
from flask_restful import Api

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

app.config.update(
    TESTING=True,
    SECRET_KEY=b'_5#y2L"F4Q8z\n\xec]/',
    MODEL_PATH=os.path.join(BASE_DIR, 'modelfiles'),
    MAILBOT_VERIFICATION='167BDB764D124C2C947F9BF3BD33F-$'
)


api = Api(app)

from nlp.route import *
