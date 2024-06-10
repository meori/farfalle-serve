#! /bin/bash
ollama serve &
echo "waiting for ollama to load"
sleep 60
echo "waiting for llama3 to load"
ollama pull llama3
uvicorn backend.main:app --host 0.0.0.0 --port 8000
