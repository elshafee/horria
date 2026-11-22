import qalsadi.analex as qala

def add_tashkeel(text: str) -> str:
    """
    Generates diacritics/harakat (Tashkeel) for plain Arabic text using Qalsadi.
    This analyzes the text and returns it with proper vocalization.
    """
    print(f"Original text : '{text}'")
    
    try:
        # Initialize the Qalsadi analyzer
        analyzer = qala.Analex()
        
        # check_text returns a list of objects containing vocalized/analyzed words
        analysis_results = analyzer.check_text(text)

        vocalized_words = []
        for word_list in analysis_results:
            if word_list:
                # Take the vocalized form from the analyzed object
                vocalized_words.append(word_list[0].vocalized)
            else:
                # Fallback to unvocalized if analysis fails for a specific word
                vocalized_words.append(word_list)
                
        result = " ".join(vocalized_words)
        print(f"Vocalized text: '{result}'")
        return result
        
    except Exception as e:
        print(f"Failed to generate tashkeel: {e}")
        return text

if __name__ == "__main__":
    # Example Usage:
    sample_text = "مرحبا بك يا صديقي في هذا التطبيق"
    add_tashkeel(sample_text)
