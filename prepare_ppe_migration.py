import csv
import json
import re

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_ppe = '/Users/sabyrzhanzhakipov/znuny-mount/ppe_migration.csv'

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

# PPE Migration
with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_ppe, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # Order: Name; DeplState; InciState; PPEType; Vladelec; IssueDate; EndDate; Size; Status; Notes
    
    for row in reader:
        cls, name_orig, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'PPE': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            p_type = fix_mojibake(v.get('PPEType', [None, {}])[1].get('ResolvedName', ''))
            size = v.get('Size', [None, {}])[1].get('Content', '')
            issue_date = v.get('IssueDate', [None, {}])[1].get('Content', '')
            end_date = v.get('EndDate', [None, {}])[1].get('Content', '')
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', ''))
            
            owner_name = fix_mojibake(v.get('Vladelec', [None, {}])[1].get('ResolvedUserFull', ''))
            owner_login = name_to_login.get(owner_name, "sz")
            
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{p_type} ({owner_name})" if owner_name else p_type
            
            # Mapping: Name; Depl; Inci; PPEType; Vladelec; IssueDate; EndDate; Size; Status; Notes
            writer.writerow([
                item_name,
                "Production",
                "Ok",
                p_type,
                owner_login,
                issue_date or "",
                end_date or "",
                size or "",
                "Production",
                notes or ""
            ])
        except: continue

print("PPE migration CSV generated.")
