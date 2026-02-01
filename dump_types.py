import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'

def fix_mojibake(s):
    if not s: return ""
    try: return s.encode('latin1').decode('utf-8')
    except: return s

classes = ['Tools', 'MeasuringTools']
types = {cls: set() for cls in classes}

with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if row[0] in classes:
            try:
                data = json.loads(row[3])
                v = data[1]['Version'][1]
                t = v.get('ToolsType', [None, {}])[1].get('ResolvedName', '')
                if t:
                    types[row[0]].add(fix_mojibake(t))
            except: pass

for cls in classes:
    print(f"\n--- {cls} Types ---")
    for t in sorted(list(types[cls])):
        print(t)
