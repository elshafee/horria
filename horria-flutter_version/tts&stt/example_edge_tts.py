import asyncio
import edge_tts

async def synthesize_text(
    text: str, 
    output_path: str, 
    voice: str = "ar-EG-ShakirNeural", # Changed to a male voice for a "moderator" feel
    rate: str = "+0%",                 # Speed of the speech
    volume: str = "+0%",               # Volume of the speech
    pitch: str = "-10Hz"               # Pitch of the speech (lower pitch sounds more authoritative)
):
    """
    Synthesizes text to speech using Microsoft Edge Read Aloud API.
    
    POSSIBLE PARAMETERS (NOTES):
    ----------------------------
    1. voice (str): 
       - "ar-EG-SalmaNeural" (Female, Egyptian Arabic)
       - "ar-EG-ShakirNeural" (Male, Egyptian Arabic) - Good for a moderator!
       - "ar-SA-HamedNeural" (Male, Saudi Arabic)
       - "ar-SA-ZariyahNeural" (Female, Saudi Arabic)
       - "en-US-AriaNeural" (Female, English US)
       - "en-US-GuyNeural" (Male, English US)
       * You can run `edge-tts --list-voices` in your terminal to see all options.
       
    2. rate (str): 
       - Controls the speed of the speech.
       - Format: "+20%", "-10%", "+0%"
       - Example: "+10%" speaks 10% faster.
       
    3. volume (str): 
       - Controls the loudness.
       - Format: "+20%", "-10%", "+0%"
       - Example: "-20%" speaks 20% quieter.
       
    4. pitch (str): 
       - Controls the tone/pitch of the voice.
       - Format: "+10Hz", "-5Hz", "+0Hz"
       - Example: "-10Hz" makes the voice deeper (great for a serious moderator).
    """
    print(f"Synthesizing text: '{text}'")
    print(f"Using voice: '{voice}' | rate: {rate} | volume: {volume} | pitch: {pitch}")
    
    # Initialize the edge-tts Communicate object with the custom parameters
    communicate = edge_tts.Communicate(
        text=text, 
        voice=voice,
        rate=rate,
        volume=volume,
        pitch=pitch
    )
    
    # Save the synthesized audio to an MP3 file
    await communicate.save(output_path)
    print(f"Success! Audio saved to: {output_path}")

if __name__ == "__main__":
    # Sample text for the moderator
    text_to_speak = "أهلاً بكم جميعاً في هذه الجلسة. أرجو من الجميع الالتزام بالقواعد المحددة."
    output_filename = "moderator_output.mp3"
    
    # Python 3.7+ way to run async functions
    # Using a deeper pitch and slightly slower rate for an authoritative moderator tone
    asyncio.run(synthesize_text(
        text=text_to_speak, 
        output_path=output_filename,
        voice="ar-EG-ShakirNeural",
        rate="-5%",   # Slightly slower
        pitch="-10Hz" # Deeper pitch
    ))
