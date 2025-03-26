# Stage 1: Build stage
FROM python:3.12-slim AS build-stage

# Set up non-root user and drop root permissions for build stage
ENV USER=builduser
RUN useradd -ms /bin/bash "${USER}"
USER ${USER}
WORKDIR /home/${USER}

# Set the working directory
# WORKDIR /app

# Copy local code to the container image
COPY --chown=${USER}:${USER} app ./app
COPY --chown=${USER}:${USER} pyproject.toml ./
COPY --chown=${USER}:${USER} poetry.lock ./

# Configure Poetry
ARG POETRY_HTTP_BASIC_NUCLEUS_USERNAME
ARG POETRY_HTTP_BASIC_NUCLEUS_PASSWORD
ARG VIRTUAL_ENVIRONMENT_PATH="/home/${USER}/app/.venv"
ARG POETRY_VIRTUALENVS_IN_PROJECT=true

# Debugging
ARG POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME
RUN echo $POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME

# Install dependencies
RUN pip install --disable-pip-version-check poetry && \
    poetry install --no-root --no-interaction --no-ansi


# Stage 2: Final stage
FROM python:3.12-slim AS final-stage

# Set up non-root user for the final stage
ENV USER=finalbuilduser
RUN useradd -ms /bin/bash "${USER}"

# Copy the necessary files from the build stage (without sensitive build data)
COPY --from=build-stage /home/builduser/app /home/${USER}/app
RUN chown -R ${USER}:${USER} /home/${USER}/app

# Switch to non-root user
USER ${USER}
WORKDIR /home/${USER}

RUN ls -la /home/${USER}/app

# Set the working directory for the final stage
# WORKDIR /app

# Make sure final stage has correct paths for Poetry and .venv
ENV VIRTUAL_ENV="/home/${USER}/app/.venv"
ENV PATH="/home/${USER}/app/.venv/bin:$PATH"

# Expose the port and set environment variables
EXPOSE 8888
ENV LOGLEVEL="DEBUG"
ENV PORT=8888
ENV HOST=0.0.0.0

RUN echo $POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME

# Run the app
# CMD poetry run uvicorn app.main:app --host $HOST --port $PORT --header servicename:railway-build-test --lifespan on
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8888"]

