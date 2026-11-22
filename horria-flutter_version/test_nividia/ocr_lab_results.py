import requests
import base64
import sys
import os

# NVIDIA NIM API Credentials
API_KEY = "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"
BASE_URL = "https://integrate.api.nvidia.com/v1"

# We use a Vision-capable model from NIM for OCR tasks. 
# Note: Text-only models like gpt-oss-120b cannot process images directly.
MODEL = "meta/llama-3.2-11b-vision-instruct" 

def encode_image(image_path):
    """Encodes the image file into a base64 string."""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def extract_lab_results(image_path):
    if not os.path.exists(image_path):
        print(f"Error: File '{image_path}' not found.")
        return

    print(f"Reading image: {image_path}...")
    base64_image = encode_image(image_path)
    
    # Determine mime type based on extension
    ext = image_path.split('.')[-1].lower()
    mime_type = f"image/{ext}" if ext in ["jpg", "jpeg", "png", "webp"] else "image/jpeg"

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Accept": "application/json"
    }

    # System instruction tailored for Medical Laboratory Results
    prompt = (
        "You are an expert medical data extraction AI. "
        "Please act as an OCR and carefully read the laboratory test results from this image. "
        "Extract the data and format the output as a clear Markdown table containing the following columns: "
        "Test Name, Result Value, Unit, and Reference Range. "
        "If there are any abnormal results flagged in the image (like High or Low), please add a 'Status' column and highlight them."
    )

    payload = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{mime_type};base64,{base64_image}"
                        }
                    }
                ]
            }
        ],
        "max_tokens": 1500,
        "temperature": 0.1 # Low temperature for accurate, factual extraction
    }

    print(f"Sending image to {MODEL} via NVIDIA NIM API...")
    
    try:
        response = requests.post(
            f"{BASE_URL}/chat/completions",
            headers=headers,
            json=payload,
            timeout=120
        )
        
        if response.status_code == 200:
            data = response.json()
            print("\n" + "="*50)
            print("🔬 EXTRACTED LABORATORY RESULTS")
            print("="*50 + "\n")
            print(data['choices'][0]['message']['content'])
        else:
            print(f"API Error ({response.status_code}): {response.text}")
            
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ocr_lab_results.py <path_to_image_file>")
        sys.exit(1)
        
    image_file_path = sys.argv[1]
    extract_lab_results(image_file_path)
