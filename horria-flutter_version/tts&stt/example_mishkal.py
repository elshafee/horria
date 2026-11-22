import mishkal.tashkeel

def add_tashkeel_mishkal(text: str) -> str:
    """
    Generates diacritics/harakat (Tashkeel) for plain Arabic text using Mishkal.
    Mishkal is a much better, context-aware rule-based diacritizer compared to Qalsadi.
    """
    print(f"Original text : '{text}'")
    
    try:
        # Initialize the Mishkal vocalizer
        vocalizer = mishkal.tashkeel.TashkeelClass()
        
        # Mishkal can vocalize an entire string at once!
        # It handles context and rules better than basic morphological analyzers
        vocalized_text = vocalizer.tashkeel(text)
        
        print(f"Vocalized text: '{vocalized_text.strip()}'")
        return vocalized_text.strip()
        
    except Exception as e:
        print(f"Failed to generate tashkeel with Mishkal: {e}")
        return text

if __name__ == "__main__":
    # Example Usage:
    # Note: Mishkal handles most contextual grammar much better than Qalsadi!
    sample_text = "مرحبا بك يا صديقي في هذا التطبيق"
    add_tashkeel_mishkal(sample_text)
