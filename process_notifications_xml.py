import xml.etree.ElementTree as ET
import json

# Old system mappings
class_map = {
    141: "Approvals",
    198: "Medical",
    184: "Passport",
    281: "Keys"
}

user_map = {
    2: "sz",
    11: "idedik",
    21: "office",
    55: "bz"
}

depl_state_map = {
    151: "Approvals::разрешено",
    29: "Maintenance",
    150: "Approvals::оформление",
    152: "Approvals::недействительно",
    27: "Expired",
    28: "Inactive",
    294: "on_stock",
    188: "Passport::действительный",
    137: "Replace",
    295: "СКЛАД"
}

role_map = {
    12: "office_manager"
}

def map_json_ids(data_str, mapping, key_prefix):
    if not data_str or data_str == "{}" or data_str == "NULL":
        return data_str
    try:
        data = json.loads(data_str)
        new_data = {}
        for k, v in data.items():
            if k.startswith(key_prefix):
                if isinstance(v, list):
                    new_v = []
                    for item in v:
                        if str(item).isdigit():
                            id_int = int(item)
                            new_v.append(mapping.get(id_int, item))
                        else:
                            new_v.append(item)
                    new_data[k] = new_v
                else:
                    if str(v).isdigit():
                        id_int = int(v)
                        new_data[k] = mapping.get(id_int, v)
                    else:
                        new_data[k] = v
            else:
                new_data[k] = v
        return json.dumps(new_data, ensure_ascii=False)
    except:
        return data_str

tree = ET.parse('old_notifications.xml')
root = tree.getroot()

notifications = []
for row_xml in root.findall('row'):
    row = {}
    for field in row_xml.findall('field'):
        row[field.get('name')] = field.text

    # Map IDs to Names
    def safe_int(val):
        if val is None or val == "" or val == "NULL":
            return 0
        try:
            return int(val)
        except:
            return 0

    row['class_name'] = class_map.get(safe_int(row.get('class_id')), "Unknown")
    row['create_by_login'] = user_map.get(safe_int(row.get('create_by')), "root")
    row['change_by_login'] = user_map.get(safe_int(row.get('change_by')), "root")
    
    # Map IDs inside JSON fields
    row['filter'] = map_json_ids(row.get('filter'), depl_state_map, "Filter")
    row['recipients'] = map_json_ids(row.get('recipients'), user_map, "Recipient.Agents")
    row['recipients'] = map_json_ids(row.get('recipients'), role_map, "Recipient.Roles")
    
    notifications.append(row)

with open('notifications_logical.json', 'w', encoding='utf-8') as f:
    json.dump(notifications, f, ensure_ascii=False, indent=4)

print(f"Successfully processed {len(notifications)} notifications from XML.")
