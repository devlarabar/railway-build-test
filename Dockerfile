# This is a multi-stage build process.

# We configure Nucleus in a separate, isolated stage so that the args will
# not be accessible in the final stage.

# In order for this to work as expected, ensure environment variables
# representing Poetry configs follow the proper format:
# https://python-poetry.org/docs/configuration/#using-environment-variables

# Stage 1: Build stage
FROM python:3.12-slim AS build

# Create a non-root user and set the working directory
ENV USER=ion8
RUN useradd -ms /bin/bash ${USER}
USER ${USER}
WORKDIR /home/${USER}

# Copy the application and Poetry files into the container
COPY --chown=${USER}:${USER} pyproject.toml poetry.lock ./
# Copy the 'app' directory into the container
COPY --chown=${USER}:${USER} app/ ./app/

RUN ls -R

# Configure the path and install Poetry
ENV PATH=/home/${USER}/.local/bin:$PATH
ENV HOME=/home/${USER}
RUN pip install --disable-pip-version-check --user poetry

# Configure Poetry
ARG POETRY_HTTP_BASIC_NUCLEUS_USERNAME
ARG POETRY_HTTP_BASIC_NUCLEUS_PASSWORD
ARG POETRY_VIRTUALENVS_IN_PROJECT=true

# Install dependencies using Poetry
RUN poetry install --no-root --no-interaction --no-ansi

# Stage 2: Final stage
FROM python:3.12-slim AS final

# Set the working directory for the final stage
# WORKDIR /app

# Copy the necessary files from the build stage
ENV USER=ion8
RUN useradd -ms /bin/bash ${USER}
WORKDIR /home/${USER}
COPY --from=build --chown=${USER}:${USER} /home/${USER}/app /home/${USER}/app
COPY --from=build --chown=${USER}:${USER} /home/${USER}/.venv /home/${USER}/.venv
USER ${USER}

# Create a non-root user, pass them ownership of /app, and switch to this user
# ENV USER appuser
# RUN useradd -m ${USER}
# RUN chown -R ${USER}:${USER} /app
# USER ${USER}

# Expose the port and set environment variables
EXPOSE 8888
ENV LOGLEVEL="DEBUG"
ENV PORT=8888
ENV HOST=0.0.0.0
ENV PATH="/home/${USER}/.venv/bin:$PATH"

# Run the app
CMD uvicorn app.main:app --host $HOST --port $PORT \
    --header servicename:railway-build-test --lifespan on
