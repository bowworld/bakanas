import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_keys = '/Users/sabyrzhanzhakipov/znuny-mount/keys_migration.csv'

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

# Keys Migration
with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_keys, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # Znuny Keys Schema:
    # Order: Name; DeplState; InciState; Type; Vendor; Owner; ActivationDate; ExpirationDate; Status; Note
    
    for row in reader:
        cls, name_orig, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Keys': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            k_type = fix_mojibake(v.get('KeysType', [None, {}])[1].get('ResolvedName', ''))
            vendor = fix_mojibake(v.get('Vendor', [None, {}])[1].get('ResolvedName', ''))
            act_date = v.get('KeysActivationDay', [None, {}])[1].get('Content', '')
            exp_date = v.get('KeysValidtillDate', [None, {}])[1].get('Content', '')
            note = fix_mojibake(v.get('Note', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            owner_name = fix_mojibake(v.get('Vladelec', [None, {}])[1].get('ResolvedUserFull', ''))
            owner_login = name_to_login.get(owner_name, "sz")
            
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{k_type} ({vendor})" if vendor else k_type

            # Mapping: Name; Depl; Inci; Type; Vendor; Owner; ActivationDate; ExpirationDate; Status; Note
            writer.writerow([
                item_name,
                "Production",
                "Ok",
                k_type,
                vendor,
                owner_login if owner_login else "sz",
                act_date or "",
                exp_date or "",
                "Production",
                note or ""
            ])
        except: continue

print("Keys migration CSV generated.")
