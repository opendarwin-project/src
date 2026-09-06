#!/usr/bin/env python3
"""Write Manifest files for a local overlay using Portage's own digests."""

import os
import sys

sys.path.insert(0, "/home/theo/.gentoo/usr/lib/python3.14/site-packages")

from portage.checksum import perform_multiple_checksums

DIGESTS = ["BLAKE2B", "BLAKE2S", "SHA256", "SHA512"]
DISTDIR = os.environ.get("DISTDIR", "/home/theo/.gentoo/var/cache/distfiles")


def digests(path: str) -> str:
    got = perform_multiple_checksums(path, hashes=DIGESTS)
    parts = []
    for name in DIGESTS:
        if name in got:
            parts += [name, got[name]]
    return " ".join(parts)


def entry(kind: str, rel: str) -> str:
    size = os.path.getsize(rel)
    return f"{kind} {rel} {size} {digests(rel)}\n"


def dist_entries(portdb, cpv: str) -> list:
    """DIST lines for every SRC_URI file already cached in DISTDIR."""
    lines = []
    tokens = portdb.aux_get(cpv, ["SRC_URI"])[0].split()
    for i, parm in enumerate(tokens):
        if parm == "->" or (i + 1 < len(tokens) and tokens[i + 1] == "->"):
            continue
        name = parm if (i and tokens[i - 1] == "->") else parm.rsplit("/", 1)[-1]
        if not name.endswith((".tar", ".tz", ".tar.gz", ".tgz", ".tar.bz2", ".tbz2",
                             ".tar.xz", ".txz", ".tar.zst", ".zip", ".gz", ".bz2", ".xz")):
            continue
        path = os.path.join(DISTDIR, name)
        if not os.path.isfile(path):
            print(f"  ! {name} not in DISTDIR, skipping", file=sys.stderr)
            continue
        lines.append(f"DIST {name} {os.path.getsize(path)} {digests(path)}\n")
    return lines


def main(repo: str) -> int:
    import portage

    portdb = portage.db[list(portage.db.keys())[0]]["porttree"].dbapi
    for cat in sorted(os.listdir(repo)):
        catdir = os.path.join(repo, cat)
        if not os.path.isdir(catdir) or cat in ("profiles", "metadata", "eclass"):
            continue
        for pkg in sorted(os.listdir(catdir)):
            pkgdir = os.path.join(catdir, pkg)
            if not os.path.isdir(pkgdir):
                continue
            cwd = os.getcwd()
            os.chdir(pkgdir)
            lines = []
            for f in sorted(os.listdir(".")):
                if f.endswith(".ebuild"):
                    lines.append(entry("EBUILD", f))
                    lines += dist_entries(portdb, f"{cat}/{f[:-7]}")
                elif f == "metadata.xml":
                    lines.append(entry("MISC", f))
            for root, _, walked in os.walk("files"):
                for f in sorted(walked):
                    lines.append(entry("MISC", os.path.join(root, f)))
            os.chdir(cwd)
            if not lines:
                continue
            with open(os.path.join(pkgdir, "Manifest"), "w") as out:
                out.writelines(sorted(lines))
            print(f"wrote {os.path.relpath(os.path.join(pkgdir, 'Manifest'), repo)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
