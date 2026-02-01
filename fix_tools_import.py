import csv
import json
import re

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'

user_map = {}
catalog_map = {}

def extract_mappings(obj):
    if isinstance(obj, dict):
        if 'Content' in obj and 'ResolvedUser' in obj:
            user_map[str(obj['Content'])] = obj['ResolvedUser']
        if 'Content' in obj and 'ResolvedName' in obj:
            catalog_map[str(obj['Content'])] = obj['ResolvedName']
        for v in obj.values():
            extract_mappings(v)
    elif isinstance(obj, list):
        for item in obj:
            extract_mappings(item)

with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader) # skip header
    for row in reader:
        if len(row) < 4: continue
        try:
            data = json.loads(row[3])
            extract_mappings(data)
        except:
            continue

print(f"Mapped {len(user_map)} users and {len(catalog_map)} catalog items.")

# Now fix the tools CSV
tools_output = '/Users/sabyrzhanzhakipov/znuny-mount/tools_ready_v2.csv'
mtools_output = '/Users/sabyrzhanzhakipov/znuny-mount/measuring_tools_ready_v2.csv'

def fix_mojibake(s):
    if not s: return ""
    try:
        return s.encode('latin1').decode('utf-8')
    except:
        return s

with open(source_file, 'r', encoding='utf-8') as f, \
     open(tools_output, 'w', encoding='utf-8', newline='') as f_tools, \
     open(mtools_output, 'w', encoding='utf-8', newline='') as f_mtools:
    
    reader = csv.reader(f)
    next(reader)
    
    writer_tools = csv.writer(f_tools, delimiter=';')
    writer_mtools = csv.writer(f_mtools, delimiter=';')
    
    writer_tools.writerow(['Name', 'DeplState', 'InciState', 'ToolsType', 'SerialNumber', 'Vladelec', 'Vendor', 'Object', 'Notes'])
    writer_mtools.writerow(['Name', 'DeplState', 'InciState', 'ToolsType', 'SerialNumber', 'Vladelec', 'Object', 'Notes'])
    
    for row in reader:
        if len(row) < 4: continue
        cls, name, status, json_data = row[0], row[1], row[2], row[3]
        if cls not in ['Tools', 'MeasuringTools']: continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            item_name = fix_mojibake(name)
            # Use 'In Use' or 'Operational' if common, but let's try to map if possible.
            # OTRS status usually matches DeploymentState.
            # In people_to_import, they used 'In Use' / 'Operational'.
            # Let's map everything to 'In Use' / 'Operational' to be safe,
            # or try to match if the user has created those states.
            
            # Actually, let's keep the original OTRS names but clean them.
            item_status = status.split('::')[-1]
            if item_status == 'Production': item_status = 'In Use'
            if item_status == 'СКЛАД': item_status = 'Planned' # or something safe
            
            # Znuny default states are usually: In Use, Retired, Inactive, etc.
            
            tools_type_id = str(v.get('ToolsType', [None, {}])[1].get('Content', ''))
            tools_type = catalog_map.get(tools_type_id, fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', '')))
            
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            
            owner_id = str(v.get('Vladelec', [None, {}])[1].get('Content', ''))
            # Vladelec is a CIClassReference to People(FIO). 
            # In people_to_import.csv, Name and FIO are Logins.
            # So Vladelec should be the Login.
            owner_login = user_map.get(owner_id, "")
            
            vendor_id = str(v.get('Vendor', [None, {}])[1].get('Content', ''))
            # Vendor is a CIClassReference to Vendor(Name).
            vendor_name = catalog_map.get(vendor_id, fix_mojibake(v.get('Vendor', [None, {}])[1].get('ResolvedName', '')))
            
            obj = fix_mojibake(v.get('Object', [None, {}])[1].get('Content', ''))
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            if not item_name or item_name.strip() == "":
                item_name = f"{tools_type} ({serial})" if serial else tools_type
            
            inci_state = 'Operational' # Standard Znuny InciState
            
            if cls == 'Tools':
                writer_tools.writerow([item_name, item_status, inci_state, tools_type, serial, owner_login, vendor_name, obj, notes])
            else:
                writer_mtools.writerow([item_name, item_status, inci_state, tools_type, serial, owner_login, obj, notes])
                
        except Exception as e:
            pass

print("Fixed CSVs generated with ID-to-Login mapping.")
