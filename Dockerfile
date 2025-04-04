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
COPY --chown=${USER}:${USER} app/ ./app/

# Configure the path and install Poetry
ENV PATH="/home/${USER}/.local/bin:$PATH"
ENV HOME="/home/${USER}"
RUN pip install --disable-pip-version-check --user poetry

# Configure Poetry
ARG POETRY_HTTP_BASIC_DUMMY_USERNAME
ARG POETRY_HTTP_BASIC_DUMMY_PASSWORD
ARG POETRY_VIRTUALENVS_IN_PROJECT=true

# Install dependencies using Poetry
RUN poetry install --no-root --no-interaction --no-ansi

# Stage 2: Final stage
FROM python:3.12-slim AS final

# Create a non-root user again (user from build stage is now inaccessible)
# Copy the necessary files from the build stage, giving the new user ownership
ENV USER=ion8
RUN useradd -ms /bin/bash ${USER}
WORKDIR /home/${USER}
COPY --from=build --chown=${USER}:${USER} /home/${USER}/app /home/${USER}/app
COPY --from=build --chown=${USER}:${USER} /home/${USER}/.venv /home/${USER}/.venv
USER ${USER}

# Set environment variables and expose the port
ENV LOGLEVEL="DEBUG"
ENV HOST=0.0.0.0
ENV PATH="/home/${USER}/.venv/bin:$PATH"
ENV PORT=8888
EXPOSE ${PORT}

# Run the app
CMD uvicorn app.main:app --host $HOST --port $PORT \
    --header servicename:railway-build-test --lifespan on
