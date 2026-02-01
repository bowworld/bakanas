import csv
import json
import re

def fix_mojibake(s):
    if not s:
        return ""
    try:
        # If it's double-encoded UTF-8:
        # 1. Encode to bytes as latin1 (mapping code points 0-255 to bytes 0-255)
        # 2. Decode as utf-8
        return s.encode('latin1').decode('utf-8')
    except:
        return s

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
tools_output = '/Users/sabyrzhanzhakipov/znuny-mount/tools_ready.csv'
mtools_output = '/Users/sabyrzhanzhakipov/znuny-mount/measuring_tools_ready.csv'

with open(source_file, 'r', encoding='utf-8') as f, \
     open(tools_output, 'w', encoding='utf-8', newline='') as f_tools, \
     open(mtools_output, 'w', encoding='utf-8', newline='') as f_mtools:
    
    reader = csv.reader(f)
    header = next(reader)
    
    writer_tools = csv.writer(f_tools, delimiter=';')
    writer_mtools = csv.writer(f_mtools, delimiter=';')
    
    writer_tools.writerow(['Name', 'DeplState', 'InciState', 'ToolsType', 'SerialNumber', 'Vladelec', 'Vendor', 'Object', 'Notes'])
    writer_mtools.writerow(['Name', 'DeplState', 'InciState', 'ToolsType', 'SerialNumber', 'Vladelec', 'Object', 'Notes'])
    
    for row in reader:
        if len(row) < 4:
            continue
        cls, name, status, json_data = row[0], row[1], row[2], row[3]
        
        if cls not in ['Tools', 'MeasuringTools']:
            continue
            
        try:
            data = json.loads(json_data)
            # OTRS structure: [None, {"Version": [None, {...}]}]
            v = data[1]['Version'][1]
            
            item_name = fix_mojibake(name)
            item_status = status.split('::')[-1]
            
            tools_type = fix_mojibake(v.get('ToolsType', [None, {}])[1].get('ResolvedName', ''))
            serial = v.get('SerialNumber', [None, {}])[1].get('Content', '')
            owner_id = v.get('Vladelec', [None, {}])[1].get('Content', '')
            vendor = fix_mojibake(v.get('Vendor', [None, {}])[1].get('ResolvedName', v.get('Vendor', [None, {}])[1].get('Content', '')))
            obj = fix_mojibake(v.get('Object', [None, {}])[1].get('Content', ''))
            notes = fix_mojibake(v.get('Notes', [None, {}])[1].get('Content', '')).replace('\n', ' ').replace('\r', '')
            
            if not item_name or item_name.strip() == "":
                item_name = f"{tools_type} ({serial})" if serial else tools_type
            
            if cls == 'Tools':
                writer_tools.writerow([item_name, item_status, 'Ok', tools_type, serial, owner_id, vendor, obj, notes])
            else:
                writer_mtools.writerow([item_name, item_status, 'Ok', tools_type, serial, owner_id, obj, notes])
                
        except Exception as e:
            print(f"Error processing row: {e}")

print("Migration files prepared successfully with Python.")
