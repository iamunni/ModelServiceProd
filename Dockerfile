FROM python:3.6-slim as build

COPY . /flask_app
WORKDIR /flask_app

RUN apt-get clean \
    && apt-get -y update

RUN apt-get -y install nginx \
    && apt-get -y install python3-dev \
    && apt-get -y install build-essential

RUN pip install -r requirements.txt --src /usr/local/src

RUN python3 -m spacy download en_core_web_sm &&\
	python3 -m spacy download en_core_web_md

FROM python:3.6-slim
COPY --from=build /flask_app /flask_app
WORKDIR /flask_app
COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod +x ./start.sh
CMD ["./start.sh"]
