import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'

def fix_mojibake(s):
    if not s: return ""
    try: return s.encode('latin1').decode('utf-8')
    except: return s

mapping = {}
with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if row[0] == 'Approvals':
            try:
                data = json.loads(row[3])
                v = data[1]['Version'][1]
                grp = fix_mojibake(v.get('Group', [None, {}])[1].get('ResolvedName', ''))
                t = fix_mojibake(v.get('Type', [None, {}])[1].get('ResolvedName', ''))
                if grp not in mapping: mapping[grp] = set()
                mapping[grp].add(t)
            except: pass

for g, types in mapping.items():
    print(f"\n--- Group: {g} ---")
    for t in sorted(list(types)):
        print(t)
