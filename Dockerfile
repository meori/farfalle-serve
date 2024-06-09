FROM python:3.11

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8
ENV PYTHONPATH=/workspace/src/
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

ENV VIRTUAL_ENV=/workspace/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /workspace

RUN apt update &&  apt-get install software-properties-common -y

# installing cuda
RUN wget https://developer.download.nvidia.com/compute/cuda/12.5.0/local_installers/cuda-repo-debian11-12-5-local_12.5.0-555.42.02-1_amd64.deb
RUN dpkg -i cuda-repo-debian11-12-5-local_12.5.0-555.42.02-1_amd64.deb
RUN cp /var/cuda-repo-debian11-12-5-local/cuda-*-keyring.gpg /usr/share/keyrings/
RUN add-apt-repository contrib
RUN apt-get update
RUN apt-get -y install cuda-toolkit-12-5

RUN apt-get install -y cuda-drivers
RUN apt-get install -y cuda-drivers

#installing farfalle
# Copy dependency files to avoid cache invalidations
COPY ./farfalle/pyproject.toml ./farfalle/poetry.lock ./

COPY ./farfalle/src/backend/ src/backend/

RUN pip install --no-cache-dir poetry && poetry install

#installing ollama
RUN curl -fsSL https://ollama.com/install.sh | sh
RUN useradd -r -s /bin/false -m -d /usr/share/ollama ollama
COPY ./ollama.service /etc/systemd/system/ollama.service
RUN systemctl daemon-reload
RUN systemctl enable ollama

#installing llama3
RUN ollama pull llama3

COPY ./startup.sh /
RUN chmod +x ./startup.sh

EXPOSE 8000

CMD ["./startup.sh"]
