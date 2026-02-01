import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_file = '/Users/sabyrzhanzhakipov/znuny-mount/tools_aligned_import.csv'

def fix_mojibake(s):
    if not s: return ""
    try: return s.encode('latin1').decode('utf-8')
    except: return s

with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_file, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # Structure based on tools_definition.yml:
    # 1. Name (Standard)
    # 2. Deployment State (Standard)
    # 3. Incident State (Standard)
    # 4. ToolsType (from YAML)
    # 5. SerialNumber (from YAML)
    # 6. Vladelec (from YAML)
    # 7. Notes (from YAML)
    
    for row in reader:
        if len(row) < 4: continue
        cls, name, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Tools': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            item_name = fix_mojibake(name)
            item_depl = 'In Use' # Known working in People import
            item_inci = 'Operational' # Known working
            
            tools_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            
            # Vladelec in new system is CIClassReference to People(FIO).
            # We don't have the login mapping yet for all, but let's try to get it from the name if possible, 
            # or just leave empty for now to ensure item creation.
            owner_login = "" 
            
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            if not item_name or item_name.strip() == "":
                item_name = f"{tools_type} ({serial})" if serial else tools_type
            
            if not item_name: continue
            
            writer.writerow([item_name, item_depl, item_inci, tools_type, serial, owner_login, notes])
                
        except: continue

print("Aligned CSV (no header, matching new schema) generated.")
