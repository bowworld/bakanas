import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_approvals = '/Users/sabyrzhanzhakipov/znuny-mount/approvals_migration.csv'

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

# Approvals Migration
with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_approvals, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # Znuny Approvals Schema:
    # 1:Name, 2:DeplState, 3:InciState, 4:Category, 5:Type, 6:Owner, 7:Number, 8:EndDate, 9:Status, 10:Notes
    
    for row in reader:
        cls, name_orig, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Approvals': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            a_type = fix_mojibake(v.get('Type', [None, {}])[1].get('ResolvedName', ''))
            
            # Map old groups to new categories
            # Based on our analysis, almost all go to "Health & Safety Permits"
            if a_type in ["Паспорт", "Удостоверение личности"]:
                category = "Personal Identification"
            elif "Медицинская" in a_type:
                category = "Medical & Others"
            else:
                category = "Health & Safety Permits"
                
            end_date = v.get('EndDate', [None, {}])[1].get('Content', '')
            
            owner_name = fix_mojibake(v.get('Owner', [None, {}])[1].get('ResolvedUserFull', ''))
            # Fallback to Group's ResolvedUserFull if Owner is missing
            if not owner_name:
                owner_name = fix_mojibake(v.get('Group', [None, {}])[1].get('ResolvedUserFull', ''))
            
            owner_login = name_to_login.get(owner_name, "sz")
            
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{a_type} ({owner_name})" if owner_name else a_type

            # Mapping: 1:Name, 2:DeplState, 3:InciState, 4:Category, 5:Type, 6:Owner, 7:Number, 8:EndDate, 9:Status, 10:Notes
            writer.writerow([
                item_name,
                "Production",
                "Ok",
                category,
                a_type,
                owner_login,
                "", # Number
                end_date or "",
                "Production",
                "" # Notes
            ])
        except: continue

print("Approvals migration CSV updated with correct categories.")
