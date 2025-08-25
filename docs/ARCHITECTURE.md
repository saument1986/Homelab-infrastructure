# Infrastructure Architecture Diagram

## Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                    Home Network (192.168.1.0/24)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │    Router    │────│   Pi-hole    │────│  Homelab     │      │
│  │192.168.1.1   │    │192.168.1.100 │    │ Host Server  │      │
│  │              │    │ (Host Net)   │    │192.168.1.100 │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                              │                    │             │
│                              │                    │             │
│                       DNS Filtering        Docker Engine        │
│                                                   │             │
└───────────────────────────────────────────────────┼─────────────┘
                                                    │
                            ┌───────────────────────┼─────────────────────────┐
                            │         Docker Host Environment                 │
                            ├─────────────────────────────────────────────────┤
                            │                       │                         │
                            │  ┌────────────────────┼──────────────────────┐  │
                            │  │          Container Networks              │  │
                            │  │                    │                     │  │
                            │  │  ┌─────────────────┼──────────────────┐  │  │
                            │  │  │    media_net (Bridge)            │  │  │
                            │  │  │                 │                │  │  │
                            │  │  │  ┌─────────────┐│┌─────────────┐ │  │  │
                            │  │  │  │  SABnzbd    ││ │   Sonarr    │ │  │  │
                            │  │  │  │ :8081       ││ │   :8989     │ │  │  │
                            │  │  │  └─────────────┘│└─────────────┘ │  │  │
                            │  │  │                 │                │  │  │
                            │  │  │  ┌─────────────┐│┌─────────────┐ │  │  │
                            │  │  │  │   Radarr    ││ │   Lidarr    │ │  │  │
                            │  │  │  │   :7878     ││ │   :8686     │ │  │  │
                            │  │  │  └─────────────┘│└─────────────┘ │  │  │
                            │  │  │                 │                │  │  │
                            │  │  │  ┌─────────────┐│┌─────────────┐ │  │  │
                            │  │  │  │  Prowlarr   ││ │ Overseerr   │ │  │  │
                            │  │  │  │   :9696     ││ │   :5055     │ │  │  │
                            │  │  │  └─────────────┘│└─────────────┘ │  │  │
                            │  │  └─────────────────┼──────────────────┘  │  │
                            │  │                    │                     │  │
                            │  │  ┌─────────────────┼──────────────────┐  │  │
                            │  │  │  monitoring (Bridge)             │  │  │
                            │  │  │                 │                │  │  │
                            │  │  │  ┌─────────────┐│┌─────────────┐ │  │  │
                            │  │  │  │ Watchtower  ││ │ Portainer   │ │  │  │
                            │  │  │  │ (Updates)   ││ │   :9000     │ │  │  │
                            │  │  │  └─────────────┘│└─────────────┘ │  │  │
                            │  │  │                 │                │  │  │
                            │  │  │  ┌─────────────┐│┌─────────────┐ │  │  │
                            │  │  │  │Uptime Kuma  ││ │  Tautulli   │ │  │  │
                            │  │  │  │   :3001     ││ │   :8181     │ │  │  │
                            │  │  │  └─────────────┘│└─────────────┘ │  │  │
                            │  │  │                 │                │  │  │
                            │  │  │  ┌─────────────┐│                │  │  │
                            │  │  │  │   Dozzle    ││                │  │  │
                            │  │  │  │   :8082     ││                │  │  │
                            │  │  │  └─────────────┘│                │  │  │
                            │  │  └─────────────────┼──────────────────┘  │  │
                            │  └──────────────────────────────────────────┘  │
                            │                       │                         │
                            │  ┌────────────────────┼──────────────────────┐  │
                            │  │         Host Network Services             │  │
                            │  │                    │                     │  │
                            │  │  ┌─────────────────┼──────────────────┐  │  │
                            │  │  │      Plex Media Server           │  │  │
                            │  │  │         :32400                  │  │  │
                            │  │  │    (Host Network Mode)          │  │  │
                            │  │  └─────────────────┼──────────────────┘  │  │
                            │  └──────────────────────────────────────────┘  │
                            │                       │                         │
                            │  ┌────────────────────┼──────────────────────┐  │
                            │  │         Security Stack                   │  │
                            │  │                    │                     │  │
                            │  │  ┌─────────────────┼──────────────────┐  │  │
                            │  │  │      Wazuh SIEM :443            │  │  │
                            │  │  │  ┌─────────────┐ │ ┌─────────────┐ │  │  │
                            │  │  │  │   Manager   │ │ │  Dashboard  │ │  │  │
                            │  │  │  └─────────────┘ │ └─────────────┘ │  │  │
                            │  │  │  ┌─────────────┐ │ ┌─────────────┐ │  │  │
                            │  │  │  │   Indexer   │ │ │   Worker    │ │  │  │
                            │  │  │  └─────────────┘ │ └─────────────┘ │  │  │
                            │  │  └─────────────────┼──────────────────┘  │  │
                            │  │                    │                     │  │
                            │  │  ┌─────────────────┼──────────────────┐  │  │
                            │  │  │    Nessus Scanner :8834          │  │  │
                            │  │  │                 │                │  │  │
                            │  │  │  ┌─────────────┐ │                │  │  │
                            │  │  │  │Vulnerability│ │                │  │  │
                            │  │  │  │  Assessment │ │                │  │  │
                            │  │  │  └─────────────┘ │                │  │  │
                            │  │  └─────────────────┼──────────────────┘  │  │
                            │  └──────────────────────────────────────────┘  │
                            └─────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Security Data Flow                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Network Traffic                                                │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────┐    DNS Queries     ┌──────────────┐          │
│  │   Pi-hole    │◄───────────────────│   Clients    │          │
│  │192.168.1.100 │                    │              │          │
│  │              │────Log Events─────►│              │          │
│  └──────────────┘                    └──────────────┘          │
│       │                                                         │
│       │ DNS Logs                                               │
│       ▼                                                         │
│  ┌──────────────┐                                              │
│  │    Wazuh     │                                              │
│  │   Manager    │◄───Vulnerability Scans───┌──────────────┐   │
│  │              │                          │    Nessus    │   │
│  │              │                          │   Scanner    │   │
│  │              │────Alerts/Dashboards────►│              │   │
│  └──────────────┘                          └──────────────┘   │
│       │                                                         │
│       │ Processed Events                                       │
│       ▼                                                         │
│  ┌──────────────┐                                              │
│  │  Dashboard   │                                              │
│  │   & Alerts   │                                              │
│  └──────────────┘                                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     Media Data Flow                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User Requests                                                  │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────┐    API Calls    ┌──────────────┐             │
│  │  Overseerr   │◄──────────────── │   Users      │             │
│  │   :5055      │                 │              │             │
│  │              │──────────────────►│              │             │
│  └──────────────┘                  └──────────────┘             │
│       │                                                         │
│       │ Automation Requests                                     │
│       ▼                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Sonarr     │    │   Radarr     │    │   Lidarr     │      │
│  │   :8989      │    │   :7878      │    │   :8686      │      │
│  │              │    │              │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│       │                    │                    │              │
│       │ Search Requests    │                    │              │
│       ▼                    ▼                    ▼              │
│  ┌──────────────┐          │                    │              │
│  │   Prowlarr   │◄─────────┴────────────────────┘              │
│  │   :9696      │                                              │
│  │              │──────Download Requests──────┐                │
│  └──────────────┘                             │                │
│                                               ▼                │
│                                         ┌──────────────┐       │
│                                         │   SABnzbd    │       │
│                                         │   :8081      │       │
│                                         │              │       │
│                                         └──────────────┘       │
│                                               │                │
│                                               │ Downloads      │
│                                               ▼                │
│  ┌──────────────┐                      ┌──────────────┐       │
│  │     Plex     │◄──────Media Files─────│   Storage    │       │
│  │  (Host Net)  │                      │   /mnt/media │       │
│  │              │                      │              │       │
│  └──────────────┘                      └──────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

## Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Storage Layout                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Host Filesystem: /home/scott/docker/                          │
│  ├── wazuh-docker/              # Security monitoring          │
│  │   ├── config/                # Wazuh configuration         │
│  │   │   └── wazuh_cluster/     # Manager configs             │
│  │   │       ├── wazuh_manager.conf                          │
│  │   │       └── custom/         # Custom rules & decoders   │
│  │   └── docker-compose.yml     # Wazuh stack definition     │
│  │                                                            │
│  ├── mediastack/                # Media automation           │
│  │   └── docker-compose.yml     # All media services        │
│  │                                                            │
│  ├── monitoring-stack/          # System monitoring          │
│  │   └── docker-compose.yml     # Monitoring services       │
│  │                                                            │
│  ├── plex/                      # Media server               │
│  │   ├── config/                # Plex configuration        │
│  │   └── docker-compose.yml     # Plex service              │
│  │                                                            │
│  ├── pihole/                    # DNS filtering              │
│  │   ├── etc-pihole/           # Pi-hole configs            │
│  │   ├── etc-dnsmasq.d/        # DNS configs                │
│  │   ├── logs/                 # DNS logs (→ Wazuh)         │
│  │   └── docker-compose.yml    # Pi-hole service            │
│  │                                                            │
│  ├── nessus/                    # Vulnerability scanning     │
│  │   ├── logs/                 # Scan logs (→ Wazuh)        │
│  │   └── docker-compose.yml    # Nessus service             │
│  │                                                            │
│  └── [service]/config/          # Service-specific configs   │
│                                                               │
│  Media Storage: /mnt/media/                                   │
│  ├── TV/                       # Television shows            │
│  ├── Movies/                   # Movie collection            │
│  ├── Music/                    # Music library               │
│  └── downloads/                # Download staging           │
│      ├── completed/            # Finished downloads         │
│      └── intermediate/         # Processing area            │
│                                                               │
│  Docker Volumes:                                              │
│  ├── wazuh_wazuh_data          # Wazuh persistent data      │
│  ├── wazuh_wazuh_logs          # Wazuh log storage          │
│  ├── wazuh_wazuh_etc           # Wazuh configuration        │
│  ├── portainer_data            # Portainer settings         │
│  ├── uptime_kuma_data          # Uptime Kuma database       │
│  ├── tautulli_config           # Tautulli configuration     │
│  └── nessus_data               # Nessus scanner data        │
└─────────────────────────────────────────────────────────────────┘
```

## Security Integration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                Security Event Processing                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Network Activity                                               │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────┐                                              │
│  │   Pi-hole    │                                              │
│  │ DNS Filtering│                                              │
│  └──────────────┘                                              │
│       │                                                         │
│       │ DNS Query Logs                                         │
│       ▼                                                         │
│  ┌──────────────┐    Custom Decoders    ┌──────────────┐      │
│  │    Wazuh     │◄────────────────────── │ Pi-hole Logs │      │
│  │   Manager    │                        │              │      │
│  │              │                        └──────────────┘      │
│  │   ┌────────┐ │                                              │
│  │   │Decoder │ │                                              │
│  │   │Rules   │ │                                              │
│  │   │Engine  │ │                                              │
│  │   └────────┘ │                                              │
│  │              │                                              │
│  │   ┌────────┐ │    Alert Rules         ┌──────────────┐      │
│  │   │Security│ │◄────────────────────── │ Custom Rules │      │
│  │   │Analysis│ │                        │  (150100-    │      │
│  │   │Engine  │ │                        │   150141)    │      │
│  │   └────────┘ │                        └──────────────┘      │
│  └──────────────┘                                              │
│       │                                                         │
│       │ Correlated Events                                      │
│       ▼                                                         │
│  ┌──────────────┐                                              │
│  │  Dashboard   │                                              │
│  │   & Alerts   │                                              │
│  │              │                                              │
│  │ • DNS Threats│                                              │
│  │ • Vuln Scans │                                              │
│  │ • Host Events│                                              │
│  └──────────────┘                                              │
│                                                                 │
│  Vulnerability Assessment Pipeline                              │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────┐                                              │
│  │    Nessus    │                                              │
│  │  Vulnerability│                                             │
│  │   Scanner    │                                              │
│  └──────────────┘                                              │
│       │                                                         │
│       │ Scan Results                                           │
│       ▼                                                         │
│  ┌──────────────┐                                              │
│  │    Wazuh     │                                              │
│  │ Vulnerability│                                              │
│  │  Detection   │                                              │
│  │              │                                              │
│  │ • Ubuntu     │                                              │
│  │ • Debian     │                                              │
│  │ • RedHat     │                                              │
│  │ • Amazon     │                                              │
│  └──────────────┘                                              │
│       │                                                         │
│       │ Threat Intelligence                                    │
│       ▼                                                         │
│  ┌──────────────┐                                              │
│  │   Combined   │                                              │
│  │   Security   │                                              │
│  │  Dashboard   │                                              │
│  └──────────────┘                                              │
└─────────────────────────────────────────────────────────────────┘
```

## Port Allocation Map

| Service | Port | Protocol | Access | Network |
|---------|------|----------|--------|---------|
| Wazuh Dashboard | 443 | HTTPS | Internal | Default |
| Pi-hole Admin | 80 | HTTP | Host | Host |
| Pi-hole DNS | 53 | UDP | Host | Host |
| Nessus | 8834 | HTTPS | Internal | Default |
| Plex | 32400 | HTTP | Host | Host |
| SABnzbd | 8081 | HTTP | Internal | media_net |
| Sonarr | 8989 | HTTP | Internal | media_net |
| Radarr | 7878 | HTTP | Internal | media_net |
| Lidarr | 8686 | HTTP | Internal | media_net |
| Prowlarr | 9696 | HTTP | Internal | media_net |
| Overseerr | 5055 | HTTP | Internal | media_net |
| Huntarr | 9705 | HTTP | Internal | media_net |
| Portainer | 9000 | HTTP | Internal | monitoring |
| Uptime Kuma | 3001 | HTTP | Internal | monitoring |
| Tautulli | 8181 | HTTP | Internal | monitoring |
| Dozzle | 8082 | HTTP | Internal | monitoring |