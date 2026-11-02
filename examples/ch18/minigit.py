#!/usr/bin/env python3
"""minigit: init, add, commit, log, cat-file. Writes REAL Git objects, index v2 and refs."""
import datetime, hashlib, os, struct, sys, time, zlib

GIT = ".git"

def write_object(kind, data):
    raw = b"%s %d\0" % (kind.encode(), len(data)) + data
    sha = hashlib.sha1(raw).hexdigest()
    path = os.path.join(GIT, "objects", sha[:2], sha[2:])
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(zlib.compress(raw))
    return sha

def read_object(sha):
    with open(os.path.join(GIT, "objects", sha[:2], sha[2:]), "rb") as f:
        raw = zlib.decompress(f.read())
    header, _, body = raw.partition(b"\0")
    return header.split()[0].decode(), body

def init():
    for d in ("objects", "refs/heads", "refs/tags"):
        os.makedirs(os.path.join(GIT, d), exist_ok=True)
    with open(os.path.join(GIT, "HEAD"), "w") as f:
        f.write("ref: refs/heads/main\n")

def read_index():
    p = os.path.join(GIT, "index")
    if not os.path.exists(p):
        return {}
    data = open(p, "rb").read()
    n = struct.unpack(">I", data[8:12])[0]
    entries, pos = {}, 12
    for _ in range(n):
        mode, = struct.unpack(">I", data[pos + 24:pos + 28])
        sha = data[pos + 40:pos + 60].hex()
        flags, = struct.unpack(">H", data[pos + 60:pos + 62])
        name = data[pos + 62:pos + 62 + (flags & 0xFFF)].decode()
        entries[name] = (mode, sha)
        pos += (62 + len(name) + 8) // 8 * 8
    return entries

def write_index(entries):
    out = b"DIRC" + struct.pack(">II", 2, len(entries))
    for name in sorted(entries):
        mode, sha = entries[name]
        b = name.encode()
        e = struct.pack(">10I", 0, 0, 0, 0, 0, 0, mode, 0, 0, 0)
        e += bytes.fromhex(sha) + struct.pack(">H", min(len(b), 0xFFF)) + b
        out += e + b"\0" * (8 - len(e) % 8)
    out += hashlib.sha1(out).digest()
    with open(os.path.join(GIT, "index"), "wb") as f:
        f.write(out)

def add(paths):
    idx = read_index()
    for p in paths:
        data = open(p, "rb").read()
        mode = 0o100755 if os.access(p, os.X_OK) else 0o100644
        idx[os.path.normpath(p)] = (mode, write_object("blob", data))
    write_index(idx)

def write_tree(entries, prefix=""):
    items = {}
    for name, (mode, sha) in entries.items():
        if not name.startswith(prefix):
            continue
        head, _, rest = name[len(prefix):].partition("/")
        items[head] = (mode, sha) if not rest else None
    body = []
    for head in items:
        if items[head] is None:
            sub = write_tree(entries, prefix + head + "/")
            body.append((head + "/", b"40000 %s\0" % head.encode() + bytes.fromhex(sub)))
        else:
            mode, sha = items[head]
            body.append((head, b"%o %s\0" % (mode, head.encode()) + bytes.fromhex(sha)))
    body.sort(key=lambda t: t[0])  # git sorts a directory as if its name ended in "/"
    return write_object("tree", b"".join(b for _, b in body))

def head_ref():
    with open(os.path.join(GIT, "HEAD")) as f:
        return f.read().strip().split(": ")[1]

def current():
    p = os.path.join(GIT, head_ref())
    return open(p).read().strip() if os.path.exists(p) else None

def commit(msg):
    tree = write_tree(read_index())
    parent = current()
    ts = "%d +0000" % time.time()
    if "GIT_COMMITTER_DATE" in os.environ:  # accept ISO dates, as the demo scripts export
        ts = "%d +0000" % datetime.datetime.strptime(
            os.environ["GIT_COMMITTER_DATE"], "%Y-%m-%dT%H:%M:%S%z").timestamp()
    who = "%s <%s> %s" % (os.environ.get("GIT_AUTHOR_NAME", "Mini Git"),
                          os.environ.get("GIT_AUTHOR_EMAIL", "mini@example.com"), ts)
    lines = ["tree " + tree] + (["parent " + parent] if parent else [])
    lines += ["author " + who, "committer " + who, "", msg, ""]
    sha = write_object("commit", "\n".join(lines).encode())
    ref = os.path.join(GIT, head_ref())
    os.makedirs(os.path.dirname(ref), exist_ok=True)
    with open(ref, "w") as f:
        f.write(sha + "\n")
    print(sha)

def log():
    sha = current()
    while sha:
        _, body = read_object(sha)
        head, _, msg = body.decode().partition("\n\n")
        print("commit " + sha + "\n\n    " + msg.strip() + "\n")
        parents = [l.split()[1] for l in head.split("\n") if l.startswith("parent ")]
        sha = parents[0] if parents else None

def cat_file(sha):
    kind, body = read_object(sha)
    if kind == "tree":
        pos = 0
        while pos < len(body):
            end = body.index(b"\0", pos)
            mode, name = body[pos:end].split(b" ", 1)
            print("%06d %s" % (int(mode), body[end + 1:end + 21].hex()), name.decode())
            pos = end + 21
    else:
        sys.stdout.write(body.decode())

if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    {"init": lambda: init(), "add": lambda: add(args), "commit": lambda: commit(args[0]),
     "log": lambda: log(), "cat-file": lambda: cat_file(args[0])}[cmd]()
