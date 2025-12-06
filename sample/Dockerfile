FROM python:3.13-slim-bookworm

ARG GROUP=sudoers
ARG USER=application
ARG DIRECTORY=/app
ARG REQUIREMENTS=requirements.txt

WORKDIR $DIRECTORY

# Install system dependencies including build tools for uwsgi
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  gcc \
  build-essential \
  python3-dev \
  && rm -rf /var/lib/apt/lists/*

RUN pip install "awscli>=1.38,<2"

RUN groupadd --system $GROUP && useradd --system --gid $GROUP $USER
RUN chown -R $USER:$GROUP $DIRECTORY

COPY ./requirements.txt $DIRECTORY/requirements.txt

RUN pip install --upgrade pip
RUN pip install --no-cache-dir --upgrade -r $DIRECTORY/$REQUIREMENTS

COPY --chown=$USER:$GROUP . $DIRECTORY

USER $USER

ENTRYPOINT ["sh", "bootup.sh"]