"""Generate calm Hebrew breath-guide voice clips via edge-tts."""
import asyncio
import os

import edge_tts

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = os.path.join(ROOT, 'assets', 'audio', 'voice')
os.makedirs(OUT, exist_ok=True)

PHRASES_HE = {
    'intro.mp3': 'ננשום יחד. עקבו אחרי הקול והעיגול.',
    'inhale.mp3': 'שאפו לאט דרך האף. ארבע שניות.',
    'hold.mp3': 'החזיקו רגע. אתם בטוחים כאן.',
    'exhale.mp3': 'נשפו לאט מהפה. שש שניות. שחררו.',
    'rest.mp3': 'מנוחה קצרה. ממשיכים יחד.',
}

PHRASES_EN = {
    'intro.mp3': 'We will breathe together. Follow the voice and the circle.',
    'inhale.mp3': 'Breathe in slowly through your nose. Four seconds.',
    'hold.mp3': 'Hold gently. You are safe here.',
    'exhale.mp3': 'Breathe out slowly through your mouth. Six seconds.',
    'rest.mp3': 'Short rest. We continue together.',
}


async def main():
    voices = await edge_tts.list_voices()
    he = [v for v in voices if str(v.get('Locale', '')).startswith('he')]
    print('HE voices:', [(v['ShortName'], v.get('Gender')) for v in he])
    if he:
        # Prefer calm female Hebrew voice when available.
        hila = next((v for v in he if 'Hila' in v['ShortName']), None)
        voice = (hila or he[0])['ShortName']
        phrases = PHRASES_HE
    else:
        voice = 'en-US-JennyNeural'
        phrases = PHRASES_EN
        print('No Hebrew voice — using English fallback')
    print('using', voice)
    for name, text in phrases.items():
        path = os.path.join(OUT, name)
        communicate = edge_tts.Communicate(text, voice, rate='-15%')
        await communicate.save(path)
        print('saved', name, os.path.getsize(path))


if __name__ == '__main__':
    asyncio.run(main())
