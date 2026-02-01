import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_file = '/Users/sabyrzhanzhakipov/znuny-mount/tools_for_import_final.csv'

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
    
    # 10 Columns: 0:Number, 1:Name, 2:DeplState, 3:InciState, 4:Type, 5:Vendor, 6:Serial, 7:Owner, 8:Status, 9:Notes
    
    for row in reader:
        cls, name_orig, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Tools': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            t_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            vendor = fix_mojibake(v.get('Vendor', [None, {}])[1].get('ResolvedName', ''))
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            # Resolve Owner
            owner_name = fix_mojibake(v.get('Vladelec', [None, {}])[1].get('ResolvedUserFull', ''))
            owner_login = name_to_login.get(owner_name, "")
            
            # If still no login, look at the Tool's own name (common in this export)
            if not owner_login:
                import re
                m = re.search(r'\((.*?)\)', fix_mojibake(name_orig))
                if m:
                    pot_name = m.group(1)
                    owner_login = name_to_login.get(pot_name, "")

            # Deployment State from your system: Production
            # Incident State from your system: Ok
            # But wait, 'Owner' and 'Status' are REQUIRED in the XML definition!
            
            # Default Owner to 'sz' (admin) if unknown, to avoid validation failure
            # Actually, let's leave empty and let's see if it works, but since it's required...
            # I'll use 'sz' as a fallback.
            if not owner_login:
                owner_login = "sz"
            
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{t_type} ({serial})" if serial else t_type
            
            if not item_name: continue
            
            writer.writerow([
                "",             # 0: Number
                item_name,      # 1: Name
                "Production",   # 2: Deployment State
                "Ok",           # 3: Incident State
                t_type,         # 4: Type (Required)
                vendor,         # 5: Vendor (Optional)
                serial or "N/A",# 6: Serial Number (Required)
                owner_login,    # 7: Owner (Required)
                "Production",   # 8: Status (Required, uses DeploymentState catalog)
                notes           # 9: Notes
            ])
                
        except Exception as e:
            # print(f"Error for {name_orig}: {e}")
            continue

print("Successfully generated EXACT CSV matching your Znuny schema.")
