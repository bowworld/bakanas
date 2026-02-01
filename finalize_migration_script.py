with open('notifications_logical.json', 'r', encoding='utf-8') as f:
    json_content = f.read()

with open('migrate_ci_notifications.pl', 'r', encoding='utf-8') as f:
    pl_content = f.read()

# Escape backslashes in JSON for Perl heredoc (if any)
# Actually, heredoc <<'JSON_DATA' with single quotes doesn't interpolate.
# But we need to make sure the delimiter JSON_DATA is not inside the json.

final_pl = pl_content.replace('[DATA_PLACEHOLDER]', json_content)

with open('migrate_ci_notifications_final.pl', 'w', encoding='utf-8') as f:
    f.write(final_pl)

print("Final migration script generated: migrate_ci_notifications_final.pl")
