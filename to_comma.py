import csv
import json

source_file = '/Users/sabyrzhanzhakipov/znuny-mount/tools_safe_import.csv'
output_file = '/Users/sabyrzhanzhakipov/znuny-mount/tools_safe_comma.csv'

with open(source_file, 'r', encoding='utf-8') as f_in, \
     open(output_file, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.reader(f_in, delimiter=';')
    writer = csv.writer(f_out, delimiter=',')
    
    for row in reader:
        writer.writerow(row)

print("Comma-separated version generated.")
