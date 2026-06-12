import json, requests, os
from dotenv import load_dotenv
import uuid

load_dotenv()
token = None
api_url = os.getenv('API_URL', 'https://alpha-studio-backend.fly.dev/api')
res = requests.post(f"{api_url}/auth/login", json={'email': os.getenv('PUBLISHER_EMAIL'), 'password': os.getenv('PUBLISHER_PASSWORD')})
if res.status_code == 200:
    token = res.json()['data']['token']

if token:
    payload = {
        'id': str(uuid.uuid4())[:8].upper(),
        'short_id': str(uuid.uuid4())[:8].upper(),
        'original_local_id': str(uuid.uuid4()),
        'name': "Test Deck",
        'description': "test",
        'source_language': "en",
        'target_language': "vi",
        'category_id': "daily",
        'tags': ["test"],
        'flashcards': [{"front": "test", "back": "test", "examples": ["test"]}],
        'image_url': "",
        'front_fields': 'word,phonetic',
        'back_fields': 'meaning,example,notes',
        'author_name': 'test',
        'image_display_mode': 'none',
        'show_back_first': False
    }
    
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    r = requests.post(f"{api_url}/vocab/public-decks", json=payload, headers=headers)
    print(r.status_code, r.text)
else:
    print("Login failed")