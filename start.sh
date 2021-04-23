#!/usr/bin/env bash

. ./vars.env

# CREATING DJANGO PROJECT
python3 -m venv .venv/
source .venv/bin/activate
pip install Django==2.2.4 gunicorn==19.9.0 psycopg2-binary
django-admin startproject ${PROJECT_NAME} --force-color


# CREATING THE DOCKERFILE
touch Dockerfile
cat > Dockerfile << EOF3
FROM python:3.7-slim-buster

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
# DB vars
ENV DB_USER_NAME ${DB_USER_NAME}
ENV DB_NAME ${DB_NAME}
ENV DB_HOST ${DB_HOST}
ENV DB_PORT ${DB_PORT}
ENV DB_PASSWORD ${DB_PASSWORD}

ENV DJANGO_SECRET_KEY ${DJANGO_SECRET_KEY}

RUN ["adduser", "${USER_NAME}", "--disabled-password", "--ingroup", "www-data", "--quiet"]

USER ${USER_NAME}

ADD ${PROJECT_NAME}/ /home/${USER_NAME}/${PROJECT_NAME}
WORKDIR /home/${USER_NAME}/${PROJECT_NAME}

ENV PATH="/home/${USER_NAME}/.local/bin:\${PATH}:/usr/local/python3/bin"

RUN pip install --user -r requirements.txt
#RUN pip install -r requirements.txt

CMD python manage.py runserver 0.0.0.0:9000
#CMD gunicorn ${PROJECT_NAME}.wsgi:application --bind 0.0.0.0:8000
EXPOSE 8000
EOF3


touch ${PROJECT_NAME}/${requirements.txt}
pip freeze | grep -v "pkg-resources" > ${PROJECT_NAME}/requirements.txt

#build and run the container
docker build --no-cache -t ${CONTAINER_NAME} .
#docker run -t -v `pwd`/${PROJECT_NAME}:/app/${PROJECT_NAME} --env-file docker_setup/vars.env --net=host -p "80:8080" ${CONTAINER_NAME}
docker run --restart=always -t -v `pwd`/${PROJECT_NAME}:/home/${USER_NAME}/${PROJECT_NAME} --env-file docker_setup/vars.env --net=host -p "8000:8000" ${CONTAINER_NAME}
