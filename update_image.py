import json

with open('english_daily_life_a1_a2.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

data['decks'][0]['image_path'] = 'https://i.ytimg.com/vi/iWo34xW5D-0/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLDzllsz_3jAxeiIP49SK9BFNcpU8w'

with open('english_daily_life_a1_a2.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)