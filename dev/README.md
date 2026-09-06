# OpenDarwin Gentoo dev container

Uses `docker.io/gentoo/stage3:llvm` so emerge runs as root inside a real
stage3, with the overlay, gentoo tree, and distfiles bind-mounted from the
host. This avoids Prefix `EPREFIX` / `/var/db` permission issues.

## Build

```sh
podman build --cgroup-manager=cgroupfs -t localhost/opendarwin-dev:llvm \
  -f ~/src/opendarwin-work/dev/Dockerfile ~/src/opendarwin-work/dev
```

## Run

```sh
~/src/opendarwin-work/dev/run.sh
```

Default mounts:

| Host | Container |
| --- | --- |
| `~/src/opendarwin-work/overlay` | `/var/db/repos/darwin-cross` |
| `~/.gentoo/var/db/repos/gentoo` | `/var/db/repos/gentoo` (ro) |
| `~/.gentoo/var/cache/distfiles` | `/var/cache/distfiles` |
| `~/src/opendarwin-work` | `/src/opendarwin-work` |

Override with `GENTOO_REPO`, `DISTFILES`, `OVERLAY`, `OPENDARWIN_IMAGE`.

## First packages (inside the container)

Host tools land in `/usr` (container root). Target libc/headers land in the
sysroot via `ROOT`:

```sh
emerge -1 --noreplace dev-util/unifdef
emerge -1 sys-devel/xcode-toolchain-wrappers sys-devel/bootstrap-cmds
emerge -1 --root=/usr/arm64-apple-darwin --config-root=/usr/arm64-apple-darwin \
  --nodeps sys-libs/libsystem
```

`--cgroup-manager=cgroupfs` is required on this host (systemd cgroup manager
fails with an sd-bus I/O error).
