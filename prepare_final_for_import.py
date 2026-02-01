import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_file = '/Users/sabyrzhanzhakipov/znuny-mount/tools_final_for_import.csv'

# Create Name to Login map for People
# In the export, People items have a "Name" field (row[1]) like "Урусов Денис" 
# and inside JSON there is a ResolvedUser (Login).
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
                if login and full_name:
                    name_to_login[full_name] = login
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
            
            # Extract fields
            t_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            vendor = fix_mojibake(v.get('Vendor', [None, {}])[1].get('ResolvedName', ''))
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            # Try to resolve owner
            # Often OTRS "ResolvedUserFull" in the XML of the Tool's Vladelec field contains the name
            owner_name = fix_mojibake(v.get('Vladelec', [None, {}])[1].get('ResolvedUserFull', ''))
            owner_login = name_to_login.get(owner_name, "")
            
            # If still no login, look at the Tool's own name, it often has the owner in parens
            if not owner_login:
                name_fixed = fix_mojibake(name_orig)
                import re
                m = re.search(r'\((.*?)\)', name_fixed)
                if m:
                    pot_name = m.group(1)
                    owner_login = name_to_login.get(pot_name, "")
            
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{t_type} ({serial})" if serial else t_type
            
            # Row order: Number(empty), Name, DeplState, InciState, Type, Vendor, Serial, Owner, Status(empty), Notes
            writer.writerow([
                "", # Number
                item_name,
                "In Use",
                "Operational",
                t_type,
                vendor,
                serial,
                owner_login,
                "", # Status
                notes
            ])
                
        except: continue

print("Final CSV for Tools generated.")
