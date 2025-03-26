# This is a multi-stage build process.

# We configure Nucleus in a separate, isolated stage so that the args will
# not be accessible in the final stage.

# In order for this to work as expected, ensure environment variables
# representing Poetry configs follow the proper format:
# https://python-poetry.org/docs/configuration/#using-environment-variables

# Stage 1: Build stage
FROM python:3.12-slim AS build

# Set the working directory
WORKDIR /app

# Install Poetry
RUN pip install poetry

# Configure Poetry
ARG POETRY_HTTP_BASIC_NUCLEUS_USERNAME
ARG POETRY_HTTP_BASIC_NUCLEUS_PASSWORD
ARG POETRY_VIRTUALENVS_IN_PROJECT=true

# Copy app files into the working directory
COPY . /app/

# Install dependencies using Poetry
RUN poetry install --no-root --no-interaction --no-ansi

# Stage 2: Final stage
FROM python:3.12-slim AS final

# Set the working directory for the final stage
WORKDIR /app

# Copy the necessary files from the build stage
COPY --from=build /app /app

# Create a non-root user, pass them ownership of /app, and switch to this user
ENV USER appuser
RUN useradd -m ${USER}
RUN chown -R appuser:${USER} /app
USER ${USER}

# Expose the port and set environment variables
EXPOSE 8888
ENV LOGLEVEL="DEBUG"
ENV PORT=8888
ENV HOST=0.0.0.0

# Copy Poetry's installed dependencies (whole directory)
COPY --from=build /root/.local /home/${USER}/.local

# Ensure Poetry is in the path
ENV PATH="/home/${USER}/.local/bin:$PATH"

# Debug Poetry installation
RUN which poetry && ls -al $(which poetry) && poetry --version

# Run the app
CMD poetry run uvicorn app.main:app --host $HOST --port $PORT \
    --header servicename:railway-build-test --lifespan on
