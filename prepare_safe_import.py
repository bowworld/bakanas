import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
tools_output = '/Users/sabyrzhanzhakipov/znuny-mount/tools_safe_import.csv'

def fix_mojibake(s):
    if not s: return ""
    try:
        return s.encode('latin1').decode('utf-8')
    except:
        return s

with open(source_file, 'r', encoding='utf-8') as f, \
     open(tools_output, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # We'll use only standard headers that we know work or are required.
    writer.writerow(['Name', 'DeplState', 'InciState', 'ToolsType', 'SerialNumber', 'Object', 'Notes'])
    
    for row in reader:
        if len(row) < 4: continue
        cls, name, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Tools': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            item_name = fix_mojibake(name)
            
            # Use states known to work in People import
            item_depl = 'In Use' 
            item_inci = 'Operational'
            
            tools_type_id = str(v.get('ToolsType', [None, {}])[1].get('Content', ''))
            tools_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            obj = fix_mojibake(v.get('Object', [None, {}])[1].get('Content', ''))
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            if not item_name or item_name.strip() == "":
                item_name = f"{tools_type} ({serial})" if serial else tools_type
            
            # Important: if name is still empty, skip
            if not item_name: continue
            
            writer.writerow([item_name, item_depl, item_inci, tools_type, serial, obj, notes])
                
        except:
            continue

print("Safe import CSV generated.")
