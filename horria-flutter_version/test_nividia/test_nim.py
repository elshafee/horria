import requests
import time
import json
import concurrent.futures

API_KEY = "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"
BASE_URL = "https://integrate.api.nvidia.com/v1"

def test_model(model_id):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Accept": "application/json"
    }
    payload = {
        "model": model_id,
        "messages": [{"role": "user", "content": "hi"}],
        "max_tokens": 10
    }
    try:
        start_req_time = time.time()
        res = requests.post(
            f"{BASE_URL}/chat/completions",
            headers=headers,
            json=payload,
            timeout=60
        )
        elapsed = time.time() - start_req_time
        
        if res.status_code == 200:
            print(f"[SUCCESS] {model_id} - {elapsed:.2f}s")
            return {"model": model_id, "time": elapsed}
        else:
            print(f"[FAILED] {model_id} - HTTP {res.status_code}")
            return None
    except Exception as e:
        print(f"[ERROR] {model_id} - {str(e)}")
        return None

def test_models():
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Accept": "application/json"
    }

    print("Fetching models...")
    response = requests.get(f"{BASE_URL}/models", headers=headers)
    if response.status_code != 200:
        print(f"Failed to fetch models: {response.text}")
        return

    models_data = response.json().get("data", [])
    print(f"Found {len(models_data)} models. Testing them in parallel...")

    working_models = []
    
    # Use ThreadPoolExecutor to run up to 50 requests concurrently
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(test_model, model.get("id")): model.get("id") for model in models_data}
        
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            if result:
                working_models.append(result)

    print("\n--- RESULTS ---")
    print("| Model | Response Time (s) |")
    print("|---|---|")
    working_models.sort(key=lambda x: x["time"])
    for wm in working_models:
        print(f"| {wm['model']} | {wm['time']:.2f} |")

if __name__ == "__main__":
    test_models()
