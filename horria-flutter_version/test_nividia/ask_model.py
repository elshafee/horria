import requests

API_KEY = "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"
BASE_URL = "https://integrate.api.nvidia.com/v1"

model = "openai/gpt-oss-20b"
prompt = "ايف الفرق بين الموجه المترده و الثابته"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Accept": "application/json"
}

payload = {
    "model": model,
    "messages": [{"role": "user", "content": prompt}],
    "max_tokens": 1024
}

res = requests.post(
    f"{BASE_URL}/chat/completions",
    headers=headers,
    json=payload,
    timeout=60
)

if res.status_code == 200:
    data = res.json()
    print(data['choices'][0]['message']['content'])
else:
    print(f"Error: {res.status_code}")
    print(res.text)
