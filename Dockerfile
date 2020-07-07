FROM python:3.6-slim

COPY . /srv/flask_app
WORKDIR /srv/flask_app

RUN apt-get clean \
    && apt-get -y update

RUN apt-get -y install nginx \
    && apt-get -y install python3-dev \
    && apt-get -y install build-essential

RUN pip install -r requirements.txt --src /usr/local/src

RUN python3 -m spacy download en_core_web_sm &&\
	python3 -m spacy download en_core_web_md

COPY nginx.conf /etc/nginx
RUN chmod +x ./start.sh
CMD ["./start.sh"]
