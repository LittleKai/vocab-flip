
import sqlite3
import os
from pymongo import MongoClient

def main():
    print('Connecting to MongoDB...')
    mongo_uri = os.environ.get('MONGODB_URI')
    if not mongo_uri:
        print("Error: MONGODB_URI environment variable not set. Please set it before running.")
        return
    client = MongoClient(mongo_uri)
    db = client['alpha-studio']
    collection = db['vocab_chinese_dictionaries']
    
    print('Reading SQLite...')
    conn = sqlite3.connect('assets/chinese_dict.db')
    cursor = conn.cursor()
    cursor.execute('SELECT id, word, pinyin, han_viet, definition FROM words')
    rows = cursor.fetchall()
    
    print(f'Found {len(rows)} rows. Dropping old collection...')
    collection.drop()
    
    docs = []
    for row in rows:
        docs.append({
            'wordId': row[0],
            'word': row[1],
            'pinyin': row[2],
            'hanViet': row[3],
            'definition': row[4]
        })
    
    print('Inserting to MongoDB...')
    if docs:
        collection.insert_many(docs)
        
    print('Creating indexes...')
    collection.create_index('word')
    collection.create_index('pinyin')
    
    print('Done.')

if __name__ == '__main__':
    main()

