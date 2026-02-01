import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_certs = '/Users/sabyrzhanzhakipov/znuny-mount/certificates_final.csv'

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

# Certificates Migration
with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_certs, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # 1:Name, 2:DeplState, 3:InciState, 4:Type, 5:Vendor, 6:Reciever, 7:IssueDate, 8:EndDate, 9:Status
    
    for row in reader:
        cls, name_orig, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Certificate': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            c_type = fix_mojibake(v.get('Type', [None, {}])[1].get('ResolvedName', ''))
            vendor = fix_mojibake(v.get('Vendor', [None, {}])[1].get('ResolvedName', ''))
            issue_date = v.get('IssueDate', [None, {}])[1].get('Content', '')
            end_date = v.get('EndDate', [None, {}])[1].get('Content', '')
            
            owner_name = fix_mojibake(v.get('Reciever', [None, {}])[1].get('ResolvedUserFull', ''))
            owner_login = name_to_login.get(owner_name, "sz")
            
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{c_type} ({owner_name})" if owner_name else c_type

            writer.writerow([
                item_name,
                "Production",
                "Ok",
                c_type,
                vendor,
                owner_login,
                issue_date or "",
                end_date or "",
                "Production"
            ])
        except: continue

print("Certificates CSV generated.")
