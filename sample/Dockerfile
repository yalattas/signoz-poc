FROM python:3.13-alpine

ARG GROUP=sudoers
ARG USER=application
ARG DIRECTORY=/app
ARG REQUIREMENTS=requirements.txt

WORKDIR $DIRECTORY

RUN apk add --no-cache \
curl \
groff \
less

RUN pip install "awscli>=1.38,<2"

RUN addgroup -S $GROUP && adduser -S $USER -G $GROUP
RUN chown -R $USER:$GROUP $DIRECTORY

COPY ./requirements.txt $DIRECTORY/requirements.txt

RUN pip install --upgrade pip
RUN pip install --no-cache-dir --upgrade -r $DIRECTORY/$REQUIREMENTS

COPY --chown=$USER:$GROUP . $DIRECTORY

USER $USER

ENTRYPOINT ["sh", "bootup.sh"]