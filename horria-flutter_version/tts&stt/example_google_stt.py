import speech_recognition as sr

def transcribe_audio(audio_path: str, language: str = "ar-EG", show_all_results: bool = False):
    """
    Transcribes audio using Google Web Speech API.
    
    POSSIBLE PARAMETERS & CONFIGURATIONS (NOTES):
    ---------------------------------------------
    1. language (str): 
       - The BCP-47 language tag. 
       - Examples: "ar-EG" (Egyptian Arabic), "ar-SA" (Saudi Arabic), "en-US" (US English).
       
    2. show_all (bool):
       - If False (default), the API returns just a simple string of the most likely transcript.
       - If True, the API returns the raw JSON dictionary from Google containing multiple 
         alternative transcriptions and their "confidence" scores. Useful for moderators 
         to check how confident the AI is before taking action.
         
    3. recognizer.energy_threshold (int):
       - Minimum audio energy to consider for recording (default is 300).
       - Higher values mean it only picks up louder noises. Useful if the moderator is in a noisy room.
       
    4. recognizer.dynamic_energy_threshold (bool):
       - If True, it automatically adjusts the energy threshold based on ambient noise.
       
    5. recognizer.adjust_for_ambient_noise(source, duration=1):
       - Can be called before reading the audio to calibrate the recognizer to the background noise.
    """
    recognizer = sr.Recognizer()
    
    # Optional Configuration examples:
    # recognizer.energy_threshold = 400
    # recognizer.dynamic_energy_threshold = True

    try:
        with sr.AudioFile(audio_path) as source:
            print("Reading audio file...")
            # If dealing with noisy microphone input, you would use:
            # recognizer.adjust_for_ambient_noise(source, duration=0.5)
            audio_data = recognizer.record(source)
            
        print(f"Sending to Google Web Speech API (Language: {language})...")
        
        # recognize_google is a wrapper around the Google Web Speech API
        result = recognizer.recognize_google(
            audio_data, 
            language=language, 
            show_all=show_all_results
        )
        
        if show_all_results:
            print(f"Raw JSON Result (Alternatives & Confidence): \n{result}")
        else:
            print(f"Transcription result: {result}")
            
        return result
        
    except FileNotFoundError:
        print(f"Error: Could not find audio file at '{audio_path}'")
    except sr.UnknownValueError:
        print("Error: Google Web Speech API could not understand the audio.")
    except sr.RequestError as e:
        print(f"Error: Could not request results from Google Web Speech API; {e}")

if __name__ == "__main__":
    # Provide a path to a valid .wav audio file to test
    # Setting show_all_results=True to see confidence scores and alternatives
    transcribe_audio("sample.wav", language="ar-EG", show_all_results=False)
