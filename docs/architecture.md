# Architecture Details

## Network Topology

```
                    ┌─────────────────────────────────────────────────────┐
                    │              AWS Region (e.g. us-east-1)            │
                    │                                                     │
  ══════════════════╪═════════════════════════════════════════════════════╪═════
  │ Security VPC A (10.100.0.0/16)           Security VPC B (10.200.0.0/16)  │
  │                 │                                                    │    │
  │  ┌──────────────┴───┐  IPsec Tunnel (QKD-secured)  ┌────────────────┴┐   │
  │  │ VM-Series FW A   │◄════════════════════════════►│ VM-Series FW B   │  │
  │  │ eth0: mgmt (EIP) │  (untrust EIP ◄──► EIP)     │ eth0: mgmt (EIP) │  │
  │  │ eth1: untrust(EIP│                              │ eth1: untrust(EIP│  │
  │  │ eth2: trust      │                              │ eth2: trust      │  │
  │  └────────┬─────────┘                              └────────┬─────────┘  │
  │           │ mTLS (via mgmt interface)                       │ mTLS       │
  │  ┌────────▼─────────┐                              ┌────────▼─────────┐  │
  │  │ QKD Device A     │                              │ QKD Device B     │  │
  │  │ (KME)            │                              │ (KME)            │  │
  │  │ on mgmt subnet   │◄╌╌╌ Quantum + Classical ╌╌╌►│ on mgmt subnet   │  │
  │  └──────────────────┘    (dedicated dark fiber)    └──────────────────┘  │
  │                                                                          │
  ═══════════════════════════════════════════════════════════════════════════
```

## Subnet Layout

| Subnet | Site A CIDR | Site B CIDR | Purpose |
|--------|-------------|-------------|---------|
| mgmt | 10.100.0.0/24 | 10.200.0.0/24 | Management access + QKD KME API |
| untrust | 10.100.1.0/24 | 10.200.1.0/24 | Internet-facing, IPsec endpoints |
| trust | 10.100.2.0/24 | 10.200.2.0/24 | Internal/private traffic |

## Routing

| Subnet | Default Route | Purpose |
|--------|---------------|---------|
| mgmt | Internet Gateway | Outbound via EIP for bootstrap S3, KME API, PAN-OS updates |
| untrust | Internet Gateway | EIP-based IPsec tunnel termination |
| trust | None (local only) | Internal traffic stays within VPC |

## Traffic Flows

### IPsec Tunnel (QKD-Secured)
```
FW A untrust (EIP) ──── UDP 500/4500 + ESP ────► FW B untrust (EIP)
```

### QKD Key Fetch (ETSI 014 API)
```
FW A mgmt interface ──── HTTPS/mTLS ────► KME A (10.100.0.x:443)
FW B mgmt interface ──── HTTPS/mTLS ────► KME B (10.200.0.x:443)
```

### QKD Key Exchange (Physical)
```
KME A ════ O-band fiber (quantum channel, ~1310nm) ════► KME B
KME A ════ C-band fiber (classical channel, ~1550nm) ═══► KME B
```

## VM-Series Interface Mapping

| Interface | ENI | Subnet | EIP | source_dest_check | Purpose |
|-----------|-----|--------|-----|-------------------|---------|
| eth0 | device_index=0 | mgmt | Yes | true | Management + KME API |
| eth1 | device_index=1 | untrust | Yes | false | IPsec tunnel endpoint |
| eth2 | device_index=2 | trust | No | false | Internal traffic |

## QKD Integration Points

The Terraform deployment creates the network infrastructure. QKD integration is performed post-deployment:

1. **KME Placement**: QKD devices connect to the management subnet at each site
2. **mTLS Certificates**: Installed on both the firewall and KME for mutual authentication
3. **PAN-OS QKD Profile**: Configured on the firewall pointing to the local KME's ETSI 014 API
4. **IKE Gateway**: References the QKD profile for quantum-derived key material

See `qkd_integration_guide.md` for step-by-step instructions.
