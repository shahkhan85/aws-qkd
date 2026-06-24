# QKD Integration Guide

Post-deployment steps to integrate QKD devices with the VM-Series firewalls.

## Prerequisites

- Terraform deployment completed (`terraform apply`)
- QKD KME devices (e.g., IDQuantique Clavis XG, Toshiba QKD + Q-KMS)
- Dark fiber between sites for quantum and classical channels
- mTLS certificates for firewall-to-KME authentication

## Step 1: Connect QKD Devices to Management Subnet

Each QKD KME device needs an IP on the management subnet:

| Site | Mgmt Subnet | Suggested KME IP |
|------|-------------|-----------------|
| Site A | 10.100.0.0/24 | 10.100.0.100 |
| Site B | 10.200.0.0/24 | 10.200.0.100 |

The management subnet security group allows HTTPS (tcp/443) inbound from the subnet CIDR, enabling the firewall to reach the KME's ETSI 014 API.

## Step 2: Establish QKD Link

Connect the quantum and classical channels between KME devices:
- **Quantum channel**: O-band fiber (~1310nm) for single-photon key exchange
- **Classical channel**: C-band fiber (~1550nm) for key reconciliation

Verify key generation:
```
# On KME A — check ETSI 014 status endpoint
curl -k --cert fw-client.crt --key fw-client.key \
  https://10.100.0.100:443/api/v1/keys/kme-b-sae-id/status
```

## Step 3: Generate mTLS Certificates

```bash
# Create CA
openssl genrsa -out ca.key 4096
openssl req -new -x509 -key ca.key -out ca.crt -days 3650 \
  -subj "/CN=QKD-mTLS-CA"

# Per-site firewall client cert
for site in site-a site-b; do
  openssl genrsa -out fw-${site}.key 4096
  openssl req -new -key fw-${site}.key -out fw-${site}.csr \
    -subj "/CN=fw-${site}"
  openssl x509 -req -in fw-${site}.csr -CA ca.crt -CAkey ca.key \
    -out fw-${site}.crt -days 365 -CAcreateserial
done

# Per-site KME server cert
for site in site-a site-b; do
  openssl genrsa -out kme-${site}.key 4096
  openssl req -new -key kme-${site}.key -out kme-${site}.csr \
    -subj "/CN=kme-${site}"
  openssl x509 -req -in kme-${site}.csr -CA ca.crt -CAkey ca.key \
    -out kme-${site}.crt -days 365 -CAcreateserial
done
```

Install:
- `ca.crt` on both firewalls and both KMEs (trusted CA)
- `fw-site-a.crt` + `fw-site-a.key` on Site A firewall
- `kme-site-a.crt` + `kme-site-a.key` on Site A KME
- (Same pattern for Site B)

## Step 4: Import Certificates into PAN-OS

SSH to each firewall management IP (from `terraform output`):

```
# Import CA certificate
> request certificate import type ca certificate-name "qkd-mtls-ca" \
    format pem filename ca.crt

# Import client certificate + key
> request certificate import type local certificate-name "fw-client-cert" \
    format pem filename fw-site-a.crt private-key fw-site-a.key
```

## Step 5: Configure PAN-OS QKD Profile

On **Site A** firewall:

```
# Create QKD profile
> configure
# set deviceconfig setting quantum qkd-profile QKD-SiteA
#   kme-url https://10.100.0.100:443/api/v1/keys
#   ssl-client-certificate fw-client-cert
#   ssl-ca-certificate qkd-mtls-ca
#   key-refresh-interval 3600
#   key-size 256

# Create IKE crypto profile (quantum-safe algorithms)
# set network ike crypto-profiles ike-crypto-profiles QKD-IKE-Crypto
#   encryption aes-256-gcm
#   hash sha512
#   dh-group group20
#   lifetime seconds 28800

# Create IPsec crypto profile
# set network ike crypto-profiles ipsec-crypto-profiles QKD-IPsec-Crypto
#   encryption aes-256-gcm
#   dh-group group20
#   lifetime seconds 3600

# Create IKE gateway with QKD profile
# set network ike gateway QKD-IKE-GW
#   authentication qkd-profile QKD-SiteA
#   peer-address ip <SITE_B_UNTRUST_EIP>
#   local-address interface ethernet1/1
#   protocol ikev2 ike-crypto-profile QKD-IKE-Crypto
#   protocol ikev2 dpd enable yes interval 10 retry 3

# Create IPsec tunnel
# set network tunnel ipsec QKD-Tunnel
#   auto-key ike-gateway QKD-IKE-GW
#   auto-key ipsec-crypto-profile QKD-IPsec-Crypto
#   tunnel-interface tunnel.1

> commit
```

Repeat on **Site B** with:
- KME URL: `https://10.200.0.100:443/api/v1/keys`
- Peer address: Site A's untrust EIP

## Step 6: Verify

```
> show vpn ike-sa
> show vpn ipsec-sa
> show qkd profile QKD-SiteA
> show qkd key-cache
```

## Troubleshooting

| Issue | Check |
|-------|-------|
| KME unreachable | `ping source 10.100.0.x host 10.100.0.100` from mgmt interface |
| mTLS failure | Verify cert CN matches, CA cert is trusted, cert not expired |
| IKE SA not forming | Check peer untrust EIP is correct, SG allows UDP 500/4500 + ESP |
| No QKD keys | Verify quantum link is up on KME, check KME ETSI 014 status endpoint |
| Key exhaustion | Increase `key-refresh-interval` or check QKD key generation rate |

## Distance Limitations

QKD fiber range is typically **50-100 km** depending on fiber loss and device model. Both sites must be within this range via dark fiber. For longer distances, trusted node (quantum repeater) architectures are needed.
