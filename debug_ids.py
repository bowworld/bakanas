import csv
import json
import re

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'

# Mappings
# We suspect '2695' etc are ConfigItemIDs.
# We want to know which People record has which ID.
# Since we don't have the ID in the CSV, we might have to guess or look for clues.

# Wait, if I look at 'Approvals', it has 'Owner' which is a CIClassReference to 'People'.
# In many records, 'Owner' = '1690' and 'Responsible' = '20' (UserID).
# There must be a way to link 1690 to a name.

# Let's check 'People' rows specifically.
# Maybe the 'Name' column (row[1]) contains something?
# Header: class,name,cur_status,data_json

with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if row[0] == 'People':
            # print(f"People Name: {row[1]}, Status: {row[2]}, JSON: {row[3][:100]}")
            pass

# I'll search for '2695' in the whole file and see the context.
with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()
    # Find all occurrences of 2695 and look at surrounding CMDB class
    matches = re.finditer(r'2695', content)
    for i, m in enumerate(matches):
        start = max(0, m.start() - 100)
        end = min(len(content), m.end() + 100)
        # print(f"Match {i}: ... {content[start:end]} ...")
        if i > 5: break

# Actually, I'll just create a map of all ResolvedUser and ResolvedName.
user_id_to_login = {}
id_to_name = {}

def find_all(obj):
    if isinstance(obj, dict):
        cid = obj.get('Content')
        if cid:
            cid_str = str(cid)
            if 'ResolvedUser' in obj:
                user_id_to_login[cid_str] = obj['ResolvedUser']
            if 'ResolvedName' in obj:
                id_to_name[cid_str] = obj['ResolvedName']
        for v in obj.values():
            find_all(v)
    elif isinstance(obj, list):
        for item in obj:
            find_all(item)

with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        try:
            data = json.loads(row[3])
            find_all(data)
        except: continue

print(f"Users: {len(user_id_to_login)}")
print(f"Names: {len(id_to_name)}")

# Check if 1690 or 2695 are in id_to_name
print(f"1690 -> {id_to_name.get('1690')}")
print(f"2695 -> {id_to_name.get('2695')}")
print(f"1691 -> {id_to_name.get('1691')}")
print(f"1979 -> {id_to_name.get('1979')}")
