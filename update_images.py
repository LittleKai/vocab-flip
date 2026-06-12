import json

deck_file = 'assets/decks/toeic_core_workplace_finance.json'
with open(deck_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

if 'decks' in data:
    deck = data['decks'][0]
else:
    deck = data
    data = {'decks': [deck]}

deck['image_path'] = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=1000&auto=format&fit=crop'

for card in deck['cards']:
    card['front_image_url'] = f"https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=500&auto=format&fit=crop&text={card['front']}"

with open(deck_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Updated deck with placeholder images and wrapped in decks array.")
