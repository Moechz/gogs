# Notices and attributions — Gogs for TerraMaster TOS 7

**Package:** `gogsdocker` 0.14.4-1
**Upstream project:** Gogs — <https://github.com/gogs/gogs>
**Container image:** `gogs/gogs:0.14.4` (Docker Hub, used unmodified)

## 1. Upstream licence (verified)

Gogs is distributed under the **MIT License**. The upstream repository's
`LICENSE` file at tag `v0.14.4` reads:

```
Copyright (c) The Gogs Authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

This is the only licence that applies to Gogs itself; earlier metadata that
described the project differently was incorrect and has been corrected.

## 2. Container image and immutable digest

The package pulls the official multi-architecture image from Docker Hub and
does not rebuild or repackage it. The tag was resolved on 2026-11-25 to the
following **OCI image index** (multi-arch manifest list):

| Item | Digest |
|---|---|
| `gogs/gogs:0.14.4` (index, amd64 + arm64 + arm/v7) | `sha256:ad893b78298754fe83010b3fa3cfe6b3f6cf42dfb8944fdb42c9a75e7420056b` |
| `linux/amd64` manifest | `sha256:1094e6d292f135f954d699a2cbba7b0c1037ab00c0fca199f8fae2a6497b6e11` |
| `linux/arm64` manifest | `sha256:a734caf7f786a0a13ceb91d86b0771e17be3794c9be66800b4e5eb64c42cd14a` |

Maintainers can verify the same index with:

```bash
docker manifest inspect gogs/gogs:0.14.4
docker image inspect gogs/gogs:0.14.4 --format '{{json .RepoDigests}}'
```

## 3. Components bundled inside the upstream image

The image is based on **Alpine Linux 3.21.10** and contains, among others, the
following components. They are included by the upstream image, not added by
this package; each remains under its own licence and copyright.

| Component | Version in the image | Licence (upstream) |
|---|---|---|
| Gogs | 0.14.4 | MIT |
| Alpine Linux / apk-tools | 3.21.10 | MIT and others (see `/usr/share/licenses`) |
| musl libc | Alpine 3.21 | MIT |
| BusyBox | Alpine 3.21 | GPL-2.0-only |
| Git | 2.47.3 | GPL-2.0-only |
| OpenSSH (client + sshd, sshd not published) | 9.9p2 | BSD / public domain |
| socat | 1.8.1.3 | GPL-2.0-only |
| s6 / execline (upstream supervisor, bypassed by this package) | Alpine 3.21 | ISC |
| curl / libcurl | Alpine 3.21 | MIT-like |
| OpenSSL / libcrypto3, libssl3 | 3.3.7 | Apache-2.0 |
| Go runtime (compiled into the binary) | 1.25.x | BSD-3-Clause |
| go-libravatar | bundled in Gogs | MIT |
| identicon | bundled in Gogs | MIT |
| Other Go modules | see `go.mod` at tag v0.14.4 | respective licences |

The full licence texts are shipped inside the container (for Alpine packages,
`/usr/share/licenses/<package>/`). The Gogs source, including its `go.mod` and
the licences of all Go dependencies, is public at
<https://github.com/gogs/gogs/tree/v0.14.4>.

**No Gogs source code is redistributed in this repository.** Only the four TOS
packaging files (`config.ini`, `gogsdocker.lang`, `gogsdocker.svg`,
`docker-compose.yml`), the wrapper script and the documentation are original
work of this package.

## 4. Trademarks and affiliation

- “Gogs” and the Gogs logo are marks of the Gogs Authors. They are used here
  only to identify the upstream software that this package installs.
- “TerraMaster”, “TOS” and “App Center” are marks of TerraMaster. They are used
  only to describe the target platform.
- This is an **independent community package by Moechz**. It is not affiliated
  with, endorsed by, or sponsored by the Gogs Authors or TerraMaster.

## 5. Licence of this packaging

The TOS packaging files in this repository are released under the **MIT
License** (see `LICENSE`). The upstream image and the components inside it keep
their own licences listed above.

## 6. Validation tool

`TOSAppSelfTestingTool` is an official TerraMaster utility. It is redistributed
unmodified in this repository for local package validation; it is **not** part
of the `gogsdocker.tar.gz` application package and is not covered by this
packaging licence. Use of the tool is subject to TerraMaster's terms.

## 7. Privacy

What the application stores and which third-party endpoints it can call is
documented in [`PRIVACY.md`](PRIVACY.md). In particular, Gravatar avatar lookups
send an MD5 hash of the user's e-mail address by default and can be disabled.
