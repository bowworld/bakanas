import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_file = '/Users/sabyrzhanzhakipov/znuny-mount/measuring_tools_aligned_import.csv'

def fix_mojibake(s):
    if not s: return ""
    try: return s.encode('latin1').decode('utf-8')
    except: return s

with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_file, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # Structure based on measuring_tools_definition.yml:
    # 1. Name (Standard)
    # 2. Deployment State (Standard)
    # 3. Incident State (Standard)
    # 4. ToolsType
    # 5. SerialNumber
    # 6. Vladelec
    # 7. Notes
    # 8. Object
    
    for row in reader:
        if len(row) < 4: continue
        cls, name, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'MeasuringTools': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            item_name = fix_mojibake(name)
            item_depl = 'In Use'
            item_inci = 'Operational'
            
            tools_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            owner_login = "" 
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            obj = fix_mojibake(v.get('Object', [None, {}])[1].get('Content', ''))
            
            if not item_name or item_name.strip() == "":
                item_name = f"{tools_type} ({serial})" if serial else tools_type
            
            if not item_name: continue
            
            writer.writerow([item_name, item_depl, item_inci, tools_type, serial, owner_login, notes, obj])
                
        except: continue

print("MeasuringTools aligned CSV generated.")
