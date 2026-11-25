# gogs-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Gogs](https://github.com/gogs/gogs), a painless self-hosted Git service.

Package version **0.14.4-1** · upstream image **`gogs/gogs:0.14.4`** (MIT) ·
non-root · SQLite · port **8163**

## What this is

A four-file TOS Docker application archive (`gogsdocker.tar.gz`, plus the
per-architecture `<appid>_<arch>.tar.gz` assets) that installs Gogs on TOS 7
through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `gogsdocker`)
- `gogsdocker.lang` — 23-language superset (TOS requires 14)
- `gogsdocker.svg` — application icon
- `docker-compose.yml` — one service, image `gogs/gogs:0.14.4`, plus the
  first-start wrapper embedded as a block scalar

## Repository layout

```
.
├── src/
│   ├── config.ini            TOS metadata (help -> PRIVACY.md)
│   ├── docker-compose.yml    one service, non-root, healthcheck, x-app-meta
│   ├── entrypoint.sh         first-start seeding/normalisation + `gogs web`
│   ├── gogsdocker.lang       23-language store text
│   └── gogsdocker.svg        icon
├── scripts/
│   ├── build.sh              build one package (x86_64 or aarch64)
│   └── build-dual.sh         build both + official self-test
├── tools/verify.py           review-standards self-check (build gate)
├── test/install-and-verify.sh on-device E2E (official installer)
├── tosapp.json               build spec and store metadata
├── PRIVACY.md                privacy policy (linked from config.ini help)
├── NOTICE.md                 licences, image digests, trademarks
├── CHANGELOG.md
├── LICENSE                   MIT for this packaging
└── TOSAppSelfTestingTool     official validator (not shipped in the package)
```

## How it works

| | |
|---|---|
| Container image | `gogs/gogs:0.14.4` (Docker Hub, image unmodified) |
| Open | `http://<NAS-IP>:8163/` (container port 3000) |
| Runs as | non-root, `user: "1000:1000"`, `cap_drop: [ALL]`, `no-new-privileges` |
| Persistent data | `/data` → `/Volume1/DockerAppData/gogsdocker/data` |
| Logs | `docker logs gogsdocker` and `DockerAppData/gogsdocker/data/log/` |
| Health | `GET /healthcheck` on container port 3000 |

`/data` holds `gogs/conf/app.ini` (mode 0600), the SQLite database, file
sessions, repositories, attachments, avatars and logs. See `PRIVACY.md` for the
full data map.

### First start

1. The App Center starts the container; the entrypoint creates the directories
   and seeds a minimal `app.ini` with SQLite, an absolute session path and the
   host-agnostic `EXTERNAL_URL = /`.
2. Open `http://<NAS-IP>:8163/`. Gogs shows its **setup wizard**.
3. Keep **SQLite**, keep the prefilled **Application URL `/`**, choose the
   admin account and click **Install**. Do not change the URL to
   `http://localhost:3000/` — that would make cookies and the post-install
   redirect point at the container's own loopback instead of the NAS.
4. Sign in with the account you just created.

The wizard writes the administrator to the SQLite database; there is no default
password and no hidden account. The database is migrated automatically when
upgrading from 0.13.x — back up `/Volume1/DockerAppData/gogsdocker/data` first.

### Why `EXTERNAL_URL = /`?

Gogs derives the CSRF cookie domain from `[server] EXTERNAL_URL`. The upstream
default is `http://localhost:3000/`, so an installation created by clicking
through the wizard gets `Domain=localhost` cookies; browsers reject them when
the NAS is opened at `http://192.168.x.x:8163`, and the post-install redirect
goes to the viewer's own localhost. The wrapper therefore seeds and normalises
`EXTERNAL_URL = /`: cookies stay host-only, links are root-relative and the UI
works from any NAS address or reverse-proxy hostname.

The trade-off is that Gogs builds clone and webhook URLs from `EXTERNAL_URL`, so
the clone box shows `/<user>/<repo>.git` and webhook payload URLs are relative.
If you need absolute URLs (external webhooks), set the wizard's Application URL
(or `[server] EXTERNAL_URL` in `app.ini`) to `http://<NAS-IP>:8163/` and restart.
Only one address can be correct for that setting; `/` is the safe default.

### Entrypoint wrapper

The upstream image starts an s6 supervisor **as root**, calls
`groupmod`/`usermod` and chowns `/data`; none of that works in a container that
already runs as uid 1000 (the TOS rule). The wrapper bypasses s6 and runs
`gogs web` directly with `GOGS_WORK_DIR=/data`.

It also fixes a 0.14.4 behaviour that would otherwise produce **HTTP 500 on
every page after the first-run setup**: the file session store resolves the
default `data/sessions` against the current directory (`/app/gogs`). In the
amd64 image that directory happens to be writable by the git user, but in the
aarch64 image it is root-owned, so `mkdir data` panics. The wrapper writes
`PROVIDER_CONFIG = /data/gogs/data/sessions` (and absolute database, repository
and log paths) on every start, so both architectures behave identically and
survive container/NAS restarts.

## Privacy

The application is self-hosted: repositories, accounts, issues and attachments
stay in the application data directory. There is **no telemetry, analytics or
advertising**, and the packager receives nothing.

The default configuration **does** call Gravatar for users without a custom
avatar, sending an MD5 hash of the e-mail address (never the address itself).
Administrators can add webhooks and SMTP servers, which send data to the hosts
they configure, and users can create repository mirrors/imports. Every outbound
endpoint, the exact data sent, the destination and how to turn it off are listed
in **[PRIVACY.md](PRIVACY.md)**.

## Notices

Gogs is MIT-licensed (verified at tag `v0.14.4`). The container image, its
multi-architecture digest, the bundled Alpine/Git/OpenSSH/socat components and
the trademark statement are in **[NOTICE.md](NOTICE.md)**. This is an
independent community package by Moechz, not affiliated with the Gogs Authors
or TerraMaster.

## Build

```bash
scripts/build.sh 0.14.4-1            # one package, x86_64
scripts/build.sh 0.14.4-1 aarch64    # one package, aarch64
scripts/build-dual.sh 0.14.4-1       # both + official TOSAppSelfTestingTool -c
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`),
removes CRLF/BOM/AppleDouble, then runs `tools/verify.py`, a review-standards
self-check (archive layout, JSON validity, required fields, 14+ language
coverage, version consistency, Docker-Hub-only images, fixed tag, host port,
non-root user, dropped capabilities, per-service healthcheck/TZ/restart, data
path below the application data root, no `/Volume*` wildcard, comment-free
sequence blocks, `x-app-meta` position, no literal secrets, icon limits and the
entrypoint byte-for-byte match).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/gogsdocker_x86_64.tar.gz   # official spec check
python3 ../stage.py .                                     # isolated runtime check
bash test/install-and-verify.sh                           # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Data and uninstall

- Persistent data: `/Volume1/DockerAppData/gogsdocker/data` (database,
  repositories, attachments, avatars, sessions, logs, `app.ini`).
- Uninstalling the App Center entry may leave that directory in place. To
  remove everything, stop the application and delete
  `/Volume1/DockerAppData/gogsdocker`; this is irreversible.
- Back up by copying the data directory (stop the container first for a
  consistent SQLite copy) or use `gogs backup` inside the container.
- The Docker package has no uninstall hook; the data directory is the complete
  removal unit. See `PRIVACY.md` §6 for the erasure channel.

## Store submission checklist

1. Public GitHub repo (code + README + PRIVACY + NOTICE).
2. Release **tag `v0.14.4-1`**, assets `gogsdocker_x86_64.tar.gz` and
   `gogsdocker_aarch64.tar.gz` (+ `.sha256`).
3. Developer platform: app `gogsdocker`, versions `0.14.4-1` for `x86_64` and
   `aarch64`.
4. Submission remark: “Rectified per review comments.”

## License / branding

The packaging in this repository is MIT (see `LICENSE`). Gogs itself is MIT,
Copyright (c) The Gogs Authors. The container image is the official Docker Hub
image `gogs/gogs:0.14.4`, used unmodified; no upstream source is redistributed
here. “Gogs” and “TerraMaster” are trademarks of their respective owners and are
used only descriptively.

## Limitations

- SSH cloning is not published; use HTTP(S) or a reverse proxy. SSH is disabled
  in the seeded configuration.
- The clone box shows a relative URL (`/<user>/<repo>.git`); prepend
  `http://<NAS-IP>:8163`. Set an absolute `EXTERNAL_URL` if you need absolute
  clone/webhook URLs.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the
  internet.
- First-run settings live in `app.ini`; changing them needs a restart.
