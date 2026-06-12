import sqlite3
conn = sqlite3.connect('assets/chinese_dict.db')
print(conn.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name='words'").fetchone()[0])
