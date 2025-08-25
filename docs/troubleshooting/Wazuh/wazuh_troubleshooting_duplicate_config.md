Wazuh Docker Troubleshooting – Duplicate Config & Agent Cleanup
📝 Problem

After initial deployment of Wazuh via Docker Compose, the manager container failed to start cleanly:

wazuh-db did not start correctly

Error reading XML file 'etc/ossec.conf': (line 0)

wazuh-apid: Killed during startup

Agents appeared with duplicate IDs/names and flapped between never connected and disconnected

🔎 Investigation

Checked root config tags

docker exec -it wazuh-manager bash -lc "
  printf 'opens: '; grep -c '^<ossec_config>' /var/ossec/etc/ossec.conf
  printf 'closes: '; grep -c '^</ossec_config>' /var/ossec/etc/ossec.conf
"


→ Found 2 opening and 2 closing <ossec_config> tags.

Looked for hidden bytes (BOM, CRLF, NULs).
Cleaned with sed, perl, and tr to normalize the file.

Checked if OOM was killing the API

docker inspect -f '{{.State.OOMKilled}}' wazuh-manager


→ false (not memory related).

Reviewed API logs

docker exec -it wazuh-manager tail -n 200 /var/ossec/logs/api.log


→ No critical errors after config cleanup.

Verified agents

docker exec -it wazuh-manager /var/ossec/bin/agent_control -lc


→ Saw duplicate IDs for the same host.

🔧 Fix

Normalized ossec.conf

Removed duplicate <ossec_config> root elements.

Stripped BOM/CRLF characters.

Ensured file ownership/permissions:

chown root:wazuh /var/ossec/etc/*.conf
chmod 640 /var/ossec/etc/*.conf


Disabled broken Telegram integration

Renamed local_integration.conf → local_integration.conf.disabled

Removed unused telegram.py + wrapper scripts.

Removed duplicate agents

Used manage_agents inside the manager container to delete old IDs.

Re-enrolled each host with a unique name via agent-auth -A <UNIQUE_NAME>.

Restarted Wazuh services

docker exec -it wazuh-manager /var/ossec/bin/wazuh-control restart

✅ Outcome

Manager started successfully.

API bound to 0.0.0.0:55000 and web interface accessible.

Agents showed up with unique IDs and stable status.

No recurring “Killed” messages or XML parse errors.

📚 Lessons Learned

Always check for multiple <ossec_config> blocks when configs are merged.

Remove BOM/CRLF early when mounting configs from Windows editors.

Use unique agent names per host to avoid duplicate IDs.

Verify if wazuh-apid was OOM-killed before chasing config issues.

Document fixes for repeatability and faster recovery.
