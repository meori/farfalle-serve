#! /bin/bash
ollama serve &
echo "waiting for ollama to start"
sleep 60

echo "waiting for llama3 to load"
ollama pull llama3

echo "Running searxng"
cd /workspace/searxng
export SEARXNG_SETTINGS_PATH="/workspace/searxng/settings.yml"
python3 searx/webapp.py &

uvicorn backend.main:app --host 0.0.0.0 --port 8000
