#FROM python:3.11
#FROM --platform=amd64 nvcr.io/nvidia/cuda:12.1.0-devel-ubuntu22.04
FROM runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8
ENV PYTHONPATH=/workspace/src/
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

ENV VIRTUAL_ENV=/workspace/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /workspace

# installing python 3.11
RUN apt update &&  apt-get install software-properties-common -y
RUN apt install -y curl
RUN apt install -y liblzma-dev
RUN apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev -y
RUN curl -O https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
RUN tar -xvf Python-3.11.4.tgz
WORKDIR Python-3.11.4
RUN ./configure --enable-optimizations
RUN make
RUN make altinstall
RUN apt install python3.11 -y
RUN apt install -y python-is-python3
RUN apt install -y python3-pip

WORKDIR /workspace

# installing cuda
# RUN curl -O https://developer.download.nvidia.com/compute/cuda/12.5.0/local_installers/cuda-repo-debian11-12-5-local_12.5.0-555.42.02-1_amd64.deb
# RUN dpkg -i cuda-repo-debian11-12-5-local_12.5.0-555.42.02-1_amd64.deb
# RUN cp /var/cuda-repo-debian11-12-5-local/cuda-*-keyring.gpg /usr/share/keyrings/
# RUN add-apt-repository contrib
# RUN apt-get update
# RUN apt-get -y install cuda-toolkit-12-5

# RUN apt-get install -y cuda-drivers
# RUN apt-get install -y cuda-drivers

#installing farfalle
# Copy dependency files to avoid cache invalidations
COPY ./farfalle/pyproject.toml ./farfalle/poetry.lock ./

COPY ./farfalle/src/backend/ src/backend/

RUN pip install --no-cache-dir poetry && poetry install

#installing ollama
# RUN apt update && apt install -y systemd
RUN curl -fsSL https://ollama.com/install.sh | sh
# RUN useradd -r -s /bin/false -m -d /usr/share/ollama ollama || true
# COPY ./ollama.service /etc/systemd/system/ollama.service
# RUN systemctl daemon-reload
# RUN systemctl enable ollama


# SearxNG installation
WORKDIR /workspace/searxng

# Install searxng dependencies
RUN apt-get install -y \
    python3-dev python3-babel python3-venv \
    uwsgi uwsgi-plugin-python3 \
    git build-essential libxslt-dev zlib1g-dev libffi-dev libssl-dev

RUN git clone https://github.com/searxng/searxng.git .

RUN pip3 install -U pip setuptools wheel pyyaml

RUN pip3 install .

COPY /farfalle/searxng/uwsgi.ini /workspace/searxng/uwsgi.ini
COPY /farfalle/searxng/settings.yml /workspace/searxng/settings.yml
COPY /farfalle/searxng/limiter.toml /workspace/searxng/limiter.toml

WORKDIR /workspace

COPY ./startup.sh /workspace/startup.sh
RUN chmod +x /workspace/startup.sh

EXPOSE 8000
ENV ENABLE_LOCAL_MODELS=True
ENV SEARCH_PROVIDER=searxng
ENV SEARXNG_BASE_URL=http://localhost:8080
ENV OLLAMA_HOST=http://localhost:11434

CMD ["./startup.sh"]
