# syntax=docker/dockerfile:1

# Stage 1: Build the frontend
FROM node:alpine as build

ARG OLLAMA_API_BASE_URL='/ollama/api'
RUN echo $OLLAMA_API_BASE_URL

ENV PUBLIC_API_BASE_URL $OLLAMA_API_BASE_URL
RUN echo $PUBLIC_API_BASE_URL

WORKDIR /app

COPY package.json package-lock.json ./ 
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: Setup the backend
FROM python:3.11-slim-buster as base

# Pre-reqs
RUN apt-get update && apt-get install --no-install-recommends -y \
    git vim build-essential python3-dev python3-venv python3-pip

# Instantiate venv and pre-activate
RUN pip3 install virtualenv
RUN virtualenv /venv

# Credit, Itamar Turner-Trauring: https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip3 install --upgrade pip setuptools && \
    pip3 install torch torchvision torchaudio

# Copy and enable all scripts
COPY ./scripts /scripts
RUN chmod +x /scripts/*

# Clone oobabooga/text-generation-webui
RUN git clone https://github.com/oobabooga/text-generation-webui /src

# Use script to check out specific version
ARG VERSION_TAG
ENV VERSION_TAG=${VERSION_TAG}
RUN . /scripts/checkout_src_version.sh

# Copy frontend build to app
COPY --from=build /app/build /app/build

# Copy source to app
RUN cp -ar /src /app

# Install oobabooga/text-generation-webui
RUN pip3 install -r /app/requirements.txt

# Install flash attention for exllamav2
RUN pip install flash-attn --no-build-isolation

# Finalise app setup
WORKDIR /app
EXPOSE 7860
EXPOSE 5000
EXPOSE 5005

# Required for Python print statements to appear in logs
ENV PYTHONUNBUFFERED=1

# Run
ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["python3", "/app/server.py"]

# The default variant should now be the only one required
FROM base AS default
RUN echo "DEFAULT" >> /variant.txt
ENV EXTRA_LAUNCH_ARGS=""
CMD ["python3", "/app/server.py"]

