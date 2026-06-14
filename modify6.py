import re

filepath = 'lib/data/remote/api/chinese_dict_api.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace Online API with Alpha Studio API
content = content.replace("dataSource: 'Online API'", "dataSource: 'REST API'")
content = content.replace("Found (Online API)", "Found (REST API)")
content = content.replace("results (Online API)", "results (REST API)")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
