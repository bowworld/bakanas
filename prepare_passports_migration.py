import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv'
output_passports = '/Users/sabyrzhanzhakipov/znuny-mount/passports_final.csv'

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

# Passports Migration
with open(source_file, 'r', encoding='utf-8') as f, \
     open(output_passports, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f)
    next(reader)
    writer = csv.writer(f_out, delimiter=';')
    
    # Order: Name; DeplState; InciState; Vladelec; IDType; FIOcyr; IDnum; FIOlat; BirthDate; Issueorgan; IssueDate; ExpDate; Status
    
    for row in reader:
        cls, name_orig, status, json_data = row[0], row[1], row[2], row[3]
        if cls != 'Passport': continue
            
        try:
            data = json.loads(json_data)
            v = data[1]['Version'][1]
            
            p_type = fix_mojibake(v.get('IDType', [None, {}])[1].get('ResolvedName', ''))
            fio_cyr = fix_mojibake(v.get('FIOcyr', [None, {}])[1].get('Content', ''))
            id_num = v.get('IDnum', [None, {}])[1].get('Content', '')
            fio_lat = fix_mojibake(v.get('FIOlat', [None, {}])[1].get('Content', ''))
            birth = v.get('BirthDate', [None, {}])[1].get('Content', '')
            organ = fix_mojibake(v.get('Issueorgan', [None, {}])[1].get('Content', ''))
            issue = v.get('IssueDate', [None, {}])[1].get('Content', '')
            exp = v.get('ExpDate', [None, {}])[1].get('Content', '')
            
            owner_name = fix_mojibake(v.get('Vladelec', [None, {}])[1].get('ResolvedUserFull', ''))
            owner_login = name_to_login.get(owner_name, "sz")
            
            item_name = fix_mojibake(name_orig)
            if not item_name or item_name.strip() == "":
                item_name = f"{p_type} ({fio_cyr})" if fio_cyr else p_type

            writer.writerow([
                item_name,
                "Production",
                "Ok",
                owner_login,
                p_type,
                fio_cyr,
                id_num,
                fio_lat,
                birth,
                organ,
                issue,
                exp,
                "Production"
            ])
        except: continue

print("Passports CSV generated.")
