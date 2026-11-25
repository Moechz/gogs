# Privacy Policy — Gogs for TerraMaster TOS 7

**Package:** `gogsdocker` · **Version:** 0.14.4-1 · **Effective:** 2026-11-25
**Upstream software:** Gogs 0.14.4 (<https://github.com/gogs/gogs>, MIT)

This policy describes what the Gogs application package stores, where it is
stored, what leaves the NAS, and how you can access or delete it. It covers the
container image `gogs/gogs:0.14.4` and the TOS packaging around it. Gogs is a
self-hosted service: the NAS owner is the operator and controls the data.

## 1. Who is responsible

The package is published by **Moechz**, an independent community packager, not
by TerraMaster or by the Gogs authors. Privacy questions and data requests:
open an issue at <https://github.com/Moechz/gogs/issues>. There is no separate
analytics or advertising controller, because the package contains neither.

## 2. What is stored, and where

Everything the application writes lives below the application data directory:

```
/Volume1/DockerAppData/gogsdocker/data/        (host)
/data                                          (inside the container)
├── gogs/conf/app.ini         configuration, SECRET_KEY, SMTP/webhook secrets (mode 0600)
├── gogs/data/gogs.db         SQLite database (accounts, repositories metadata, issues, ...)
├── gogs/data/sessions/       file-backed web sessions
├── gogs/data/attachments/    issue/PR/release attachments uploaded by users
├── gogs/data/avatars/        generated or uploaded avatars
├── gogs-repositories/        Git repositories (bare repositories on disk)
├── log/                      gogs.log, xorm.log, gorm.log
└── .ssh/, .gitconfig         Gogs-managed git identity (SSH is disabled in this package)
```

The SQLite database contains:

| Data | Purpose |
|---|---|
| Username, display name, e-mail address, avatar setting | account and profile |
| Salted **PBKDF2-SHA256** password hash (never the password) | sign-in |
| TOTP two-factor secret, if the user enables 2FA | sign-in |
| API access tokens (stored as a hash/identifier, not the clear token) | API and Git-over-HTTP access |
| SSH public keys, if a user adds them | authentication (SSH is not published by this package, so keys are stored but unused) |
| Repository metadata, issues, pull requests, comments, wikis, releases, labels, milestones | the Git service itself |
| Webhook URLs, payload settings and webhook secrets | outbound notifications configured by an administrator |
| E-mail addresses and notification preferences | optional e-mail notifications |

Logs may contain IP addresses, usernames, repository names and error text. They
are ordinary server logs, kept until you delete them; enable external log
rotation if you need a fixed retention period.

## 3. What leaves the NAS (third-party disclosures)

The package contains **no analytics, telemetry, advertising or crash-reporting
SDK**. It does not contact the packager. The only outbound traffic is listed
below; the first row is on by default, the rest require you to configure them.

| # | Endpoint / service | What is sent | Destination / region | When / default |
|---|---|---|---|---|
| 1 | `https://secure.gravatar.com/avatar/<md5>` (Gravatar) | **MD5 hash of the lower-cased, trimmed e-mail address**, requested image size, `d=identicon`; no plain e-mail, name or password | Automattic / Gravatar global CDN (United States and edge locations worldwide) | Whenever an avatar is rendered for a user who has not uploaded a custom avatar. **Enabled by default.** Disable with `[picture] DISABLE_GRAVATAR = true` in `app.ini` (or `[server] OFFLINE_MODE = true`) and restart. |
| 2 | `https://secddn.libravatar.org/avatar/<hash>` plus DNS SRV lookups (Libravatar / federated avatars) | e-mail hash and size; DNS queries reveal the e-mail domain | Libravatar / worldwide | Only if an administrator sets `[picture] ENABLE_FEDERATED_AVATAR = true`. **Disabled by default.** |
| 3 | Webhook endpoints configured by an administrator (generic HTTP(S), Slack, Discord, DingTalk, Telegram, etc.) | repository, branch, commit, issue/PR and user data in the JSON payload, plus the configured secret used for signing | The exact host chosen by the administrator; region depends on that service | Only for webhooks an administrator creates. **None configured by default.** |
| 4 | SMTP server configured by an administrator | sender/recipient e-mail addresses, subject and message body (activation, password reset, notifications) | The SMTP host chosen by the administrator; region depends on that provider | Only if `[email] ENABLED = true` and an SMTP host is set. **Disabled by default.** |
| 5 | Remote Git URLs configured for repository **mirrors** or **migrations/imports** | the Git protocol request and credentials if the URL contains them | The remote Git host chosen by the administrator | Only for mirrors/imports an administrator creates. **None configured by default.** |
| 6 | Update check | **None.** Gogs 0.14.4 does not call an update or version service; the version is shown locally in the site footer/admin page. | — | Never |

The Git protocol itself is served **inbound** on the published HTTP port; it
does not call out. If you put Gogs behind a reverse proxy, the proxy's own
privacy policy applies to traffic reaching it.

## 4. Cookies and sessions

Gogs sets a session cookie (`i_like_gogs`) and a CSRF cookie. They are
first-party, host-only (the packaged default `EXTERNAL_URL = /` deliberately
avoids a `Domain=localhost` cookie that browsers reject) and are used only to
keep you signed in and to protect forms. There are no advertising or
cross-site tracking cookies.

## 5. Retention

- Account, repository, issue, wiki and attachment data: kept until you delete
  the item, delete the account/repository, or remove the application data
  directory. There is no automatic expiry.
- Sessions: removed by Gogs' session garbage collector after the configured
  lifetime; expired files may remain until then.
- Logs: kept until rotated or deleted by the administrator.
- Backups you create are governed by your own retention policy.

## 6. Your rights and how to exercise them

Because the NAS owner operates the service, requests are handled locally:

- **Access / portability:** sign in and view your profile, or clone repositories
  over HTTP and use the API (`/api/v1`) to export data. The SQLite database and
  the bare repositories are readable by the NAS administrator.
- **Rectification:** edit your profile, e-mail, password, 2FA and SSH keys in
  the web UI; repository owners can edit repository metadata.
- **Erasure:** delete repositories, issues, comments, attachments and your
  account in the UI (administrators can delete any account). To erase
  **everything**, stop the application and delete
  `/Volume1/DockerAppData/gogsdocker/data`; this removes the database,
  repositories, sessions, logs and configuration. Uninstalling the App Center
  entry alone may keep that directory, so delete it explicitly if you want the
  data gone.
- **Objection / restriction:** disable Gravatar, federated avatars, e-mail and
  webhooks (see §3), or stop the container.

## 7. Security measures

- The container runs as **uid 1000 (non-root)**, with **all Linux capabilities
  dropped** and `no-new-privileges`.
- `app.ini`, which holds `SECRET_KEY`, SMTP and webhook secrets, is created with
  mode **0600**; the configuration and database directories are mode 0700.
- SSH (port 22) is **not published** and is disabled in the seeded
  configuration; the only reachable service is the HTTP UI on the published
  port.
- No telemetry, no default webhook, no default SMTP and no default admin
  account: the first-run wizard creates the administrator.
- The UI is plain HTTP. Before exposing it beyond a trusted LAN, put a TLS
  reverse proxy in front of it and restrict NAS/App Center access to trusted
  administrators. Keep the NAS and the Docker image updated.

No method of storage is perfectly secure; this package reduces exposure but
cannot protect data from an administrator who controls the NAS.

## 8. Children

The application is a general-purpose developer tool and is not directed at
children. The operator decides who may have accounts.

## 9. Changes to this policy

The policy is versioned with the package. Material changes are described in
`CHANGELOG.md` and the release notes; the effective date at the top is updated.
The current text is always available at
<https://github.com/Moechz/gogs/blob/main/PRIVACY.md>.

## 10. Contact

Privacy questions or data requests: <https://github.com/Moechz/gogs/issues>.
Do not send passwords, tokens or repository contents in a public issue.

---

*This policy covers the TOS package and the unmodified upstream image. Gogs
itself is Copyright the Gogs Authors, MIT-licensed; see `NOTICE.md`.*
