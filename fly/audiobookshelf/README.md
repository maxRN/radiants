# Audiobookshelf on Fly.io

Fly deployment for `abs.maxrn.dev`, migrated from the NixOS host `kaladin`.

- **App config/DB**: Fly volume at `/data` (`/data/config`, `/data/metadata`)
- **Media**: Hetzner Storage Box mounted at `/mnt/ssh` via rclone SFTP (same path as on kaladin)
- **Machine**: `shared-cpu-1x` 256MB + 512MB swap in `fra`

## Prerequisites

- [flyctl](https://fly.io/docs/hands-on/install-flyctl/) installed and authenticated (`fly auth login`)
- SSH access to kaladin
- Ability to add an SSH public key to the Hetzner Storage Box

## 1. Storage Box SSH key

Generate a dedicated key for Fly (do not reuse kaladin's host key):

```bash
ssh-keygen -t ed25519 -f ./abs-fly-storagebox -N "" -C "audiobookshelf-fly"
```

Register the public key on the Storage Box:

```bash
ssh-copy-id -i ./abs-fly-storagebox.pub -p 23 -s u462951@u462951.your-storagebox.de
```

Or add `abs-fly-storagebox.pub` via Hetzner Robot → Storage Box → SSH Keys.

Verify:

```bash
sftp -P 23 -i ./abs-fly-storagebox u462951@u462951.your-storagebox.de
```

## 2. Export data from kaladin

On kaladin, stop ABS briefly and archive config + metadata **without cache** (cache is ~6.4GB and rebuilds automatically):

```bash
sudo systemctl stop audiobookshelf
sudo tar czf /tmp/abs-data-slim.tgz -C /var/lib/audiobookshelf \
  config \
  metadata/authors \
  metadata/backups \
  metadata/items \
  metadata/logs \
  metadata/streams \
  metadata/tmp
sudo systemctl start audiobookshelf
ls -lh /tmp/abs-data-slim.tgz   # expect ~220MB
```

| Path | Size | Needed? |
|------|------|---------|
| `config/` | 37MB | Yes — DB, users, libraries, settings |
| `metadata/items/` | 121MB | Yes — cover art, item metadata |
| `metadata/backups/` | 85MB | Nice to have |
| `metadata/authors/` | 13MB | Nice to have |
| `metadata/logs/`, `tmp/`, `streams/` | ~38MB | Optional |
| `metadata/cache/covers` + `cache/images` | ~16MB | Yes — resized cover art served by the UI |
| `metadata/cache/items/` | **6.4GB** | **Skip** — HLS stream segments, rebuilt on playback |

Copy to your local machine:

```bash
scp kaladin:/tmp/abs-data-slim.tgz ./fly/audiobookshelf/abs-data-slim.tgz
```

## 3. Create Fly app and volume

```bash
cd fly/audiobookshelf

# Create the app (skip deploy until secrets/volume are ready)
fly apps create radiants-abs --org personal  # skip if app already exists

# Create persistent volume for config/DB/cache
fly volumes create abs_data --size 10 --region fra -a radiants-abs
```

## 4. Set secrets

```bash
fly secrets set STORAGEBOX_SSH_KEY="$(cat ../../abs-fly-storagebox)" -a radiants-abs
```

## 5. Deploy

```bash
fly deploy -a radiants-abs
```

Wait for the machine to pass health checks:

```bash
fly status -a radiants-abs
fly logs -a radiants-abs
```

Confirm the storage box mounted:

```bash
fly ssh console -a radiants-abs -C "mountpoint /mnt/ssh && ls /mnt/ssh | head"
```

## 6. Import migrated config/DB

Stop the machine so ABS isn't writing the database:

```bash
fly machine list -a radiants-abs
fly machine stop <machine-id> -a radiants-abs
```

Copy the archive into the volume and extract:

```bash
fly ssh sftp shell -a radiants-abs
# In the sftp shell:
put abs-data-slim.tgz /data/abs-data-slim.tgz
```

```bash
fly ssh console -a radiants-abs -C "tar xzf /data/abs-data-slim.tgz -C /data && rm /data/abs-data-slim.tgz"
```

Start the machine again:

```bash
fly machine start <machine-id> -a radiants-abs
```

## 7. Test on fly.dev

Open `https://radiants-abs.fly.dev` and verify:

- Login with existing users works
- Libraries point at `/mnt/ssh/...` and books appear
- Listening progress and covers are intact
- Playback and seeking work

Trigger a manual library scan if needed (Settings → Libraries → Scan).

## 8. Cutover to abs.maxrn.dev

Only after testing is successful:

```bash
fly certs add abs.maxrn.dev -a radiants-abs
```

Fly will show the DNS records to add. Point `abs.maxrn.dev` at Fly (typically a CNAME to `radiants-abs.fly.dev` or the A/AAAA records Fly provides).

Verify TLS:

```bash
fly certs show abs.maxrn.dev -a radiants-abs
```

## 9. Decommission kaladin ABS (after cutover)

In [hosts/kaladin/default.nix](../hosts/kaladin/default.nix), remove the `./audiobookshelf` import and redeploy kaladin with `nixos-rebuild switch`.

Keep the Storage Box mount on kaladin if other services (e.g. paperless) still use it.

## Troubleshooting

### rclone mount fails

```bash
fly logs -a radiants-abs
fly ssh console -a radiants-abs -C "cat /data/rclone-cache/rclone.log | tail -50"
```

Check the SSH key secret and that the public key is registered on the Storage Box.

### OOM during library scan

Bump memory in [fly.toml](./fly.toml):

```toml
[[vm]]
  memory = "512mb"
```

Then `fly deploy`.

### Library paths broken after migration

Library folders in the ABS database must use `/mnt/ssh/...` paths (matching kaladin). The entrypoint mounts the Storage Box root at `/mnt/ssh`.

## Cost estimate

| Resource | Approx. monthly |
|----------|-----------------|
| shared-cpu-1x 256MB (fra) | ~$1.94 |
| 10GB volume | ~$1.50 |
| Egress (after 100GB free) | $0.02/GB |
