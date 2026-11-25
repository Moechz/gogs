# Changelog

All notable user-visible changes to the Gogs TOS application package.

## 0.14.4-1 — 2026-11-25

Remediation of the TerraMaster App Center review of 0.13.3-3
(x86_64: C2/C3/C4/C5/C6/C8/T1/F7/F9; aarch64: C4/C6/C8/T1/F2/F7/F9/S10/S11).

### Security
- **T1** — upgraded the bundled Gogs from **0.13.3 to 0.14.4** (released
  2026-11-12), the current stable release. This includes the security fixes
  that 0.13.3 lacks: GHSA-pmfh-wh5m-gmjm (password-reset link sign-in bypass),
  GHSA-f9cv-gfvg-3464 (blocked/inactive accounts kept access),
  GHSA-53f6-cgcf-gp6v (private-repository issue comment), GHSA-799r-mx22-r63q
  (webhook/mirror SSRF via IPv6 `[::]`), GHSA-hr26-3fq5-9365 (Org-mode file
  read), GHSA-vhf5-f34f-vhq9 (stored XSS via external username),
  GHSA-p92p-7887-3g33 (attachment cross-repository move), plus the 0.14.3
  reverse-proxy trust fix (GHSA-w6j9-vw59-27wv), 0.14.2 LFS/XSS fixes and the
  0.14.1 unauthenticated-upload fix (GHSA-fc3h-92p8-h36f). The database is
  migrated automatically on first start; back up
  `DockerAppData/gogsdocker/data` before upgrading.
- **S10 / S11** — container keeps `user: "1000:1000"` (non-root) and now also
  drops **all** Linux capabilities and sets `no-new-privileges`; `app.ini`
  (SECRET_KEY, SMTP and webhook secrets) is created **0600**, config/database
  directories 0700, repositories/logs 0750. SSH stays unpublished and is
  disabled in the seeded configuration.
- Image is pinned to the fixed release tag `gogs/gogs:0.14.4`; the
  multi-architecture index and per-architecture digests are recorded in
  `NOTICE.md`.

### Fixed
- **F2 / F7 / F9** — the file session store now uses the absolute path
  `/data/gogs/data/sessions` instead of the relative default `data/sessions`.
  Gogs 0.14 resolves the relative path against `/app/gogs`; that directory is
  root-owned in the aarch64 image, so the session middleware panicked with
  `mkdir data: permission denied` and **every page returned HTTP 500** after
  the first-run setup, including after a restart. The wrapper seeds and
  normalises `app.ini` so both architectures use the writable volume.
- **F7** — the first-run wizard is prefilled with SQLite and
  `EXTERNAL_URL = /` instead of `http://localhost:3000/`. The old default made
  the CSRF cookie `Domain=localhost` (rejected by browsers opening the NAS IP)
  and redirected the freshly installed instance to the viewer's own localhost.
  Existing `localhost`/`127.0.0.1` URLs are rewritten to `/` on the next start.
- Existing 0.13.x relative database/repository/log paths are converted to
  their previous absolute locations, so an in-place upgrade keeps the same
  data.

### Added
- **C3 / C4 / C5 / C7** — `PRIVACY.md`: stored data, location, outbound
  transfers, retention, user rights, security measures, deletion channel and
  contact. The `help` link in `config.ini` (and therefore the App Center help
  button) opens it.
- **C2** — `NOTICE.md`: verified MIT licence of Gogs, the upstream copyright
  notice, image source and digests, bundled components and their licences,
  trademark attribution and the packaging licence.
- **C8** — third-party/outbound disclosure table: Gravatar avatar lookups
  (MD5 of the e-mail address, default on, can be disabled), Libravatar
  (default off), administrator-configured webhooks, SMTP, repository
  mirrors/imports, and confirmation that 0.14.4 performs **no** update check.
- **C6** — store description, `important` text and privacy policy now describe
  the actual runtime behaviour (SQLite, no telemetry, no default admin, SSH
  unpublished, relative clone URL with `EXTERNAL_URL=/`).
- **C10** — README: repository layout, first-run/`EXTERNAL_URL` explanation,
  privacy, notices, build, data and uninstall.
- **F11** — data/uninstall section documents that the Docker package has no
  uninstall hook and that `DockerAppData/gogsdocker/data` is the removal unit.

### Changed
- Base image/tag `gogs/gogs:0.13.3` → `gogs/gogs:0.14.4`; package version
  `0.13.3-*` → `0.14.4-1`.
- Healthcheck now probes `/healthcheck` (the upstream endpoint) instead of `/`,
  with a 60 s start period for slow aarch64 pulls.

### Migration notes
- Stop the app, back up `DockerAppData/gogsdocker/data`, update the App Center
  entry. Gogs 0.14.4 migrates the SQLite schema on first start; then sign in
  with the existing account.
- Installations created by the 0.13.3 wizard with `EXTERNAL_URL=http://localhost:3000/`
  are corrected to `/` automatically on the next start.
