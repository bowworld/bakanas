import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_file = '/Users/sabyrzhanzhakipov/znuny-mount/tools_for_znuny.csv'

# Map full names to logins from People class
name_to_login = {}
with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if row[0] == 'People':
            try:
                data = json.loads(row[3])
                v = data[1]['Version'][1]
                login = v.get('FIO', [None, {}])[1].get('ResolvedUser', '')
                full_name = v.get('FIO', [None, {}])[1].get('ResolvedUserFull', '')
                if login and full_name: name_to_login[full_name] = login
            except: pass

def fix_mojibake(s):
    if not s: return ""
    try: return s.encode('latin1').decode('utf-8')
    except: return s

with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_file, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    for row in reader:
        cls, name_orig, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Tools': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            t_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            # Resolve Owner
            owner_name = fix_mojibake(v.get('Vladelec', [None, {}])[1].get('ResolvedUserFull', ''))
            owner_login = name_to_login.get(owner_name, "")
            
            # Use states from DB: Production (Depl) and Ok (Inci)
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{t_type} ({serial})" if serial else t_type
            
            if not item_name: continue
            
            # FINAL ORDER (no first empty column): 
            # 1: Name, 2: DeplState, 3: InciState, 4: Type, 5: Serial, 6: Owner, 7: Notes
            writer.writerow([
                item_name,
                "Production",
                "Ok",
                t_type,
                serial,
                owner_login or "",
                notes
            ])
                
        except: continue

print("Corrected CSV for Znuny generated with verified states.")
