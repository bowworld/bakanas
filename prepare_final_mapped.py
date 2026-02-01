import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_file = '/Users/sabyrzhanzhakipov/znuny-mount/tools_final_mapped.csv'

# Step 1: Create ID -> Login map from the People class in the export
id_to_login = {}
with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if row[0] == 'People':
            try:
                data = json.loads(row[3])
                # In OTRS export, the ConfigItemID of the person is often the key
                # but we need to find where it's stored.
                # Actually, we can just use the user_id_to_login we found earlier.
                v = data[1]['Version'][1]
                fio_cid = v.get('FIO', [None, {}])[1].get('Content', '')
                fio_login = v.get('FIO', [None, {}])[1].get('ResolvedUser', '')
                if fio_cid and fio_login:
                    id_to_login[str(fio_cid)] = fio_login
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
    
    # Matching the order: Name; Deployment State; Incident State; Type; Vendor; Serial Number; Owner; Notes
    
    for row in reader:
        cls, name, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Tools': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            item_name = fix_mojibake(name)
            item_depl = 'In Use' 
            item_inci = 'Operational'
            
            t_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            vendor = fix_mojibake(v.get('Vendor', [None, {}])[1].get('ResolvedName', ''))
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            
            # Map Vladelec ID to Login
            owner_id = str(v.get('Vladelec', [None, {}])[1].get('Content', ''))
            owner_login = id_to_login.get(owner_id, "")
            
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            if not item_name or item_name.strip() == "":
                item_name = f"{t_type} ({serial})" if serial else t_type
            
            if not item_name: continue
            
            writer.writerow([item_name, item_depl, item_inci, t_type, vendor, serial, owner_login, notes])
                
        except: continue

print("Final mapped CSV generated successfully.")
