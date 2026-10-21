#!/usr/bin/env python3
"""Build a local Moon Animator candidate from one pinned, user-supplied package.

Python 3.10+; standard library only. No downloads, imports of plugin code, or
Roblox execution. This is a narrow binary editor, not a general RBXM converter.
Format reference: https://dom.rojo.space/binary.html

Only replacement Script.Source properties and the Part0/Part1 references of
18 pre-existing cross-rig Weld/Snap instances may change. Other chunks are
copied byte-for-byte. Changed chunks use the format's uncompressed encoding.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import sys
from typing import Any


SOURCE_SHA256 = "f757db4c6dd9eb68fea11891e12ac4e8cbe776b4d6d26d1c89625c5826d23206"
SOURCE_COMMIT = "69b88295776351b5aec1cdff783bb12a194daf43"
SOURCE_REPOSITORY = "https://github.com/zildjibian/moon-animator"
SOURCE_FILENAME = "Moon Animator 2 (v34000).rbxm"
SOURCE_BYTES = 420075
EXPECTED_CLASSES = 50
EXPECTED_INSTANCES = 7351
EXPECTED_SCRIPTS = 139
EXPECTED_CROSS_RIG_JOINTS = 18

MAX_FILE_BYTES = 8 * 1024 * 1024
MAX_CHUNK_BYTES = 4 * 1024 * 1024
MAX_DECODED_BYTES = 16 * 1024 * 1024
MAX_SCRIPT_BYTES = 1024 * 1024
MAX_PATCH_BYTES = 2 * 1024 * 1024
MAX_CHUNKS = 5000
MAX_INSTANCES = 20000
MAX_CLASSES = 256
MAX_DEPTH = 128
MAX_PATCH_ENTRIES = 2048

MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"
SCRIPT_CLASSES = frozenset({"Script", "LocalScript", "ModuleScript"})
# Only types present in the pinned source. Other types require a new review.
PROPERTY_TYPES = frozenset({1, 2, 3, 4, 5, 6, 7, 11, 12, 13, 14, 16,
                            18, 19, 24, 25, 26, 27, 28, 30, 32, 33})
FIXED_WIDTHS = {2: 1, 3: 4, 4: 4, 5: 8, 6: 8, 7: 16, 11: 4,
                12: 12, 13: 8, 14: 12, 18: 4, 19: 4, 24: 16,
                26: 3, 27: 8, 28: 4, 33: 8}
ROTATION_IDS = frozenset({2, 3, 5, 6, 7, 9, 10, 12, 13, 14, 16, 17,
                          20, 21, 23, 24, 25, 27, 28, 30, 31, 32, 34, 35})


class BuildError(ValueError):
    """A bounded parse, input identity, patch, or integrity check failed."""


def need(condition: bool, message: str) -> None:
    if not condition:
        raise BuildError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def decode_lz4_block(data: bytes, expected_size: int) -> bytes:
    """Decode a raw LZ4 block with explicit input/output bounds and overlap."""
    need(0 <= expected_size <= MAX_CHUNK_BYTES, "LZ4 output exceeds limit")
    need(not data.startswith(b"\x28\xb5\x2f\xfd"),
         "Zstandard compression is unsupported for this pinned build")
    out = bytearray()
    pos = 0

    def extended_length(initial: int) -> int:
        nonlocal pos
        length = initial
        if initial == 15:
            while True:
                need(pos < len(data), "Truncated LZ4 length")
                byte = data[pos]
                pos += 1
                length += byte
                need(length <= expected_size, "LZ4 run exceeds output limit")
                if byte != 255:
                    break
        return length

    while pos < len(data):
        token = data[pos]
        pos += 1
        literal_length = extended_length(token >> 4)
        need(pos + literal_length <= len(data), "Truncated LZ4 literals")
        need(len(out) + literal_length <= expected_size, "LZ4 literal overflow")
        out.extend(data[pos:pos + literal_length])
        pos += literal_length
        if pos == len(data):
            break
        need(pos + 2 <= len(data), "Truncated LZ4 match offset")
        offset = data[pos] | (data[pos + 1] << 8)
        pos += 2
        need(0 < offset <= len(out), "Invalid LZ4 match offset")
        match_length = extended_length(token & 15) + 4
        need(len(out) + match_length <= expected_size, "LZ4 match overflow")
        # LZ4 matches may overlap the bytes they are appending.
        pattern = bytes(out[-offset:])
        repetitions = (match_length + offset - 1) // offset
        out.extend((pattern * repetitions)[:match_length])
    need(len(out) == expected_size, "LZ4 decoded size does not match header")
    return bytes(out)


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def take(self, count: int) -> bytes:
        need(0 <= count <= len(self.data) - self.pos, "Truncated binary data")
        result = self.data[self.pos:self.pos + count]
        self.pos += count
        return result

    def u8(self) -> int:
        return self.take(1)[0]

    def u32(self) -> int:
        return struct.unpack("<I", self.take(4))[0]

    def string(self, limit: int = MAX_CHUNK_BYTES) -> bytes:
        count = self.u32()
        need(count <= limit, "Binary string exceeds limit")
        return self.take(count)

    def text(self, limit: int = 1024) -> str:
        try:
            value = self.string(limit).decode("utf-8")
        except UnicodeDecodeError as exc:
            raise BuildError("Invalid UTF-8 name") from exc
        need("\0" not in value, "NUL in binary name")
        return value

    def refs(self, count: int) -> tuple[int, ...]:
        need(0 <= count <= MAX_INSTANCES, "Referent count exceeds limit")
        raw = self.take(count * 4)
        total = 0
        values = []
        for i in range(count):
            encoded = int.from_bytes(bytes(raw[i + j * count] for j in range(4)), "big")
            total += (encoded >> 1) ^ -(encoded & 1)
            need(-(1 << 31) <= total < (1 << 31), "Referent overflow")
            values.append(total)
        return tuple(values)

    def end(self) -> None:
        need(self.pos == len(self.data), "Unexpected bytes after binary field")


def encode_refs(values: tuple[int, ...]) -> bytes:
    rows = []
    previous = 0
    for value in values:
        need(-(1 << 31) <= value < (1 << 31), "Referent out of range")
        delta = value - previous
        need(-(1 << 31) <= delta < (1 << 31), "Referent delta out of range")
        encoded = (delta << 1) ^ (delta >> 31)
        rows.append(encoded.to_bytes(4, "big"))
        previous = value
    return bytes(row[column] for column in range(4) for row in rows)


def encode_strings(values: tuple[bytes, ...]) -> bytes:
    return b"".join(struct.pack("<I", len(value)) + value for value in values)


@dataclass(frozen=True)
class Chunk:
    tag: bytes
    raw: bytes
    payload: bytes
    offset: int


@dataclass(frozen=True)
class ClassGroup:
    name: str
    refs: tuple[int, ...]


@dataclass(frozen=True)
class Property:
    class_id: int
    name: str
    type_id: int
    header: bytes
    body: bytes
    values: tuple[Any, ...] | None
    chunk_index: int


@dataclass
class Node:
    class_id: int
    properties: dict[str, Any] = field(default_factory=dict)
    parent: int | None = None


@dataclass
class Model:
    header: bytes
    chunks: list[Chunk]
    classes: dict[int, ClassGroup]
    nodes: dict[int, Node]
    properties: dict[tuple[int, str], Property]
    paths: dict[int, tuple[str, ...]]
    script_targets: dict[str, int]


def validate_cframes(reader: Reader, count: int) -> None:
    for _ in range(count):
        rotation = reader.u8()
        if rotation == 0:
            reader.take(36)
        else:
            need(rotation in ROTATION_IDS, "Unknown CFrame rotation code")
    reader.take(12 * count)


def decode_property(reader: Reader, type_id: int, count: int,
                    shared_count: int) -> tuple[Any, ...] | None:
    """Decode edited/identity fields; validate and preserve other typed data."""
    need(type_id in PROPERTY_TYPES, f"Unsupported property type {type_id:#x}")
    if type_id == 1:
        values: tuple[Any, ...] | None = tuple(reader.string() for _ in range(count))
    elif type_id == 2:
        raw = reader.take(count)
        need(all(value in (0, 1) for value in raw), "Invalid boolean value")
        values = tuple(bool(value) for value in raw)
    elif type_id == 19:
        values = reader.refs(count)
    elif type_id == 28:
        raw = reader.take(count * 4)
        for i in range(count):
            value = int.from_bytes(bytes(raw[i + j * count] for j in range(4)), "big")
            need(value < shared_count, "Invalid shared-string index")
        values = None
    elif type_id in FIXED_WIDTHS:
        reader.take(FIXED_WIDTHS[type_id] * count)
        values = None
    elif type_id == 16:
        validate_cframes(reader, count)
        values = None
    elif type_id == 25:
        for _ in range(count):
            flags = reader.u8()
            need(flags in (0, 1, 2, 3), "Unsupported physical-property flags")
            if flags & 1:
                reader.take(24 if flags & 2 else 20)
        values = None
    elif type_id == 30:
        need(reader.u8() == 16, "Invalid optional CFrame type")
        validate_cframes(reader, count)
        need(reader.u8() == 2, "Invalid optional CFrame presence type")
        need(all(v in (0, 1) for v in reader.take(count)), "Invalid CFrame presence value")
        values = None
    elif type_id == 32:
        for _ in range(count):
            reader.string()
            reader.take(3)
            reader.string()
        values = None
    else:
        raise BuildError(f"Unsupported property structure {type_id:#x}")
    reader.end()
    return values


def canonical_target(parts: tuple[str, ...]) -> str:
    cleaned = []
    for part in parts:
        need(part not in ("", ".", "..") and not any(c in part for c in "/\\\0"),
             "Unsafe script instance path")
        value = re.sub(r"[^A-Za-z0-9_.-]+", "_", part)
        need(value not in ("", ".", "..") and not value.startswith("."),
             "Unsafe normalized script path")
        cleaned.append(value)
    return "/".join(cleaned) + ".luau"


def parse_model(data: bytes) -> Model:
    need(32 <= len(data) <= MAX_FILE_BYTES, "Invalid package size")
    need(data[:14] == MAGIC, "Not a Roblox binary model")
    version, class_count, instance_count = struct.unpack_from("<HII", data, 14)
    need(version == 0 and data[24:32] == b"\0" * 8, "Unsupported Roblox header")
    need(0 < class_count <= MAX_CLASSES and 0 < instance_count <= MAX_INSTANCES,
         "Package count exceeds limits")
    chunks: list[Chunk] = []
    classes: dict[int, ClassGroup] = {}
    nodes: dict[int, Node] = {}
    properties: dict[tuple[int, str], Property] = {}
    shared_count = 0
    seen_meta = seen_shared = seen_parent = seen_end = False
    phase = 0  # metadata, instances, properties, parents, end
    pos = 32
    decoded_total = 0

    while pos < len(data):
        need(len(chunks) < MAX_CHUNKS and pos + 16 <= len(data), "Invalid chunk framing")
        start = pos
        tag, compressed_size, plain_size, reserved = struct.unpack_from("<4sIII", data, pos)
        pos += 16
        need(reserved == 0, "Nonzero reserved chunk field")
        need(plain_size <= MAX_CHUNK_BYTES, "Chunk exceeds decoded-size limit")
        stored_size = compressed_size or plain_size
        need(stored_size <= MAX_FILE_BYTES and pos + stored_size <= len(data), "Truncated chunk")
        stored = data[pos:pos + stored_size]
        pos += stored_size
        decoded_total += plain_size
        need(decoded_total <= MAX_DECODED_BYTES, "Package exceeds decoded-size limit")
        payload = decode_lz4_block(stored, plain_size) if compressed_size else stored
        chunk_index = len(chunks)
        chunks.append(Chunk(tag, data[start:pos], payload, start))
        reader = Reader(payload)

        if tag == b"META":
            need(phase == 0 and not seen_meta, "Unexpected META chunk")
            seen_meta = True
            count = reader.u32()
            need(count <= 256, "Too many metadata entries")
            keys = set()
            for _ in range(count):
                key = reader.text()
                need(key not in keys, "Duplicate metadata key")
                keys.add(key)
                reader.string()
            reader.end()
        elif tag == b"SSTR":
            need(phase == 0 and not seen_shared, "Unexpected SSTR chunk")
            seen_shared = True
            need(reader.u32() == 0, "Unsupported shared-string version")
            shared_count = reader.u32()
            need(shared_count <= MAX_INSTANCES, "Too many shared strings")
            for _ in range(shared_count):
                reader.take(16)
                reader.string()
            reader.end()
        elif tag == b"INST":
            need(phase <= 1, "INST chunk out of order")
            phase = 1
            class_id = reader.u32()
            name = reader.text()
            object_format = reader.u8()
            count = reader.u32()
            need(name and class_id not in classes and len(classes) < class_count,
                 "Invalid or duplicate instance class")
            need(object_format in (0, 1), "Unsupported instance object format")
            need(0 < count <= instance_count, "Invalid instance count")
            refs = reader.refs(count)
            if object_format:
                need(reader.take(count) == b"\1" * count, "Invalid service markers")
            reader.end()
            need(len(set(refs)) == count and all(ref >= 0 and ref not in nodes for ref in refs),
                 "Invalid or duplicate instance referent")
            classes[class_id] = ClassGroup(name, refs)
            nodes.update((ref, Node(class_id)) for ref in refs)
        elif tag == b"PROP":
            need(phase in (1, 2) and len(classes) == class_count, "PROP chunk out of order")
            phase = 2
            class_id = reader.u32()
            name = reader.text()
            type_id = reader.u8()
            need(class_id in classes and name and (class_id, name) not in properties,
                 "Invalid or duplicate property")
            header = payload[:reader.pos]
            body = payload[reader.pos:]
            refs = classes[class_id].refs
            values = decode_property(reader, type_id, len(refs), shared_count)
            prop = Property(class_id, name, type_id, header, body, values, chunk_index)
            properties[(class_id, name)] = prop
            if values is not None:
                for ref, value in zip(refs, values):
                    nodes[ref].properties[name] = value
        elif tag == b"PRNT":
            need(phase == 2 and not seen_parent, "Unexpected PRNT chunk")
            phase = 3
            seen_parent = True
            need(reader.u8() == 0, "Unsupported parent-table version")
            count = reader.u32()
            need(count == instance_count, "Parent-table count mismatch")
            children = reader.refs(count)
            parents = reader.refs(count)
            reader.end()
            need(len(set(children)) == count and set(children) == set(nodes),
                 "Parent-table referents do not match instances")
            for child, parent in zip(children, parents):
                need(parent == -1 or parent in nodes, "Invalid parent referent")
                nodes[child].parent = parent
        elif tag == b"END\0":
            need(phase == 3 and not seen_end and not compressed_size,
                 "Unexpected END chunk")
            need(payload == b"</roblox>" and pos == len(data), "Invalid ending/trailing bytes")
            seen_end = True
            phase = 4
        else:
            raise BuildError(f"Unknown chunk type {tag!r}")

    need(seen_end and seen_parent and len(classes) == class_count
         and len(nodes) == instance_count, "Incomplete model")
    for prop in properties.values():
        if prop.type_id == 19:
            need(all(ref == -1 or ref in nodes for ref in prop.values or ()),
                 "Property contains an invalid instance reference")

    names = {}
    for ref, node in nodes.items():
        value = node.properties.get("Name")
        need(isinstance(value, bytes), "Instance is missing a string Name")
        try:
            names[ref] = value.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise BuildError("Invalid instance-name encoding") from exc
    paths: dict[int, tuple[str, ...]] = {}
    for ref in nodes:
        chain = []
        visited = set()
        current = ref
        while current != -1 and current not in paths:
            need(current is not None and current not in visited and len(chain) < MAX_DEPTH,
                 "Cyclic or excessively deep instance hierarchy")
            visited.add(current)
            chain.append(current)
            current = nodes[current].parent
        prefix = paths.get(current, ())
        need(len(prefix) + len(chain) <= MAX_DEPTH, "Instance hierarchy exceeds depth limit")
        for item in reversed(chain):
            prefix = prefix + (names[item],)
            paths[item] = prefix

    targets: dict[str, int] = {}
    folded = set()
    for ref, node in nodes.items():
        if "Source" in node.properties:
            need(classes[node.class_id].name in SCRIPT_CLASSES, "Source on a non-script instance")
            need(isinstance(node.properties["Source"], bytes), "Unsupported script-source type")
            need(len(node.properties["Source"]) <= MAX_SCRIPT_BYTES,
                 "Script source exceeds size limit")
            need(not node.properties.get("LinkedSource"), "External LinkedSource is unsupported")
            target = canonical_target(paths[ref])
            need(target.casefold() not in folded, "Duplicate/ambiguous normalized script path")
            folded.add(target.casefold())
            targets[target] = ref
        elif classes[node.class_id].name in SCRIPT_CLASSES:
            raise BuildError("Executable instance has no explicit Source")
    return Model(data[:32], chunks, classes, nodes, properties, paths, targets)


def extract_script_sources(data: bytes) -> dict[str, bytes]:
    """Return canonical .luau paths and source bytes, without executing code.

    This accepts either the reviewed input or a structurally valid candidate.
    It validates the binary container but does not establish file authenticity;
    use the pinned input hash or the build manifest for identity verification.
    """
    model = parse_model(data)
    return {target: model.nodes[ref].properties["Source"]
            for target, ref in sorted(model.script_targets.items())}


def reject_links(path: Path) -> None:
    for component in (path.absolute(), *path.absolute().parents):
        try:
            info = component.lstat()
        except FileNotFoundError:
            # New output paths need not exist yet; their existing ancestors do.
            continue
        # Path.is_junction() only exists in Python 3.12+. lstat exposes Windows
        # reparse points on every supported version, including directory links.
        reparse_point = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
        need(not stat.S_ISLNK(info.st_mode)
             and not (getattr(info, "st_file_attributes", 0) & reparse_point),
             "Symbolic links/junctions are unsupported")


def read_bounded_file(path: Path, limit: int) -> bytes:
    reject_links(path)
    need(path.is_file(), f"Expected a regular file: {path}")
    with path.open("rb") as handle:
        data = handle.read(limit + 1)
    need(len(data) <= limit, f"File exceeds size limit: {path.name}")
    return data


def load_patches(root: Path, model: Model) -> dict[int, bytes]:
    reject_links(root)
    need(root.is_dir(), "Patches directory does not exist")
    entries: list[Path] = []
    entry_count = 0

    def walk_error(error: OSError) -> None:
        raise error

    for current, directories, files in os.walk(root, followlinks=False, onerror=walk_error):
        need(len(Path(current).relative_to(root).parts) < MAX_DEPTH, "Patch directory is too deep")
        entry_count += len(directories) + len(files)
        need(entry_count <= MAX_PATCH_ENTRIES, "Too many patch directory entries")
        for name in directories + files:
            child = Path(current) / name
            reject_links(child)
            need(child.is_dir() or child.is_file(), "Non-regular patch entry")
        entries.extend(Path(current) / name for name in files)
        need(len(entries) <= EXPECTED_SCRIPTS, "Too many patch files")
    need(entries, "No replacement source files were supplied")
    patches = {}
    seen = set()
    total = 0
    for path in sorted(entries):
        rel = path.relative_to(root).as_posix()
        parts = PurePosixPath(rel).parts
        need(all(p not in ("", ".", "..") and re.fullmatch(r"[A-Za-z0-9_.-]+", p)
                 for p in parts), "Unsafe patch path")
        need(rel.endswith(".luau"), f"Unexpected non-Luau file in patches: {rel}")
        need(rel.casefold() not in seen, "Duplicate patch path")
        seen.add(rel.casefold())
        need(rel in model.script_targets, f"Patch is not a known script target: {rel}")
        ref = model.script_targets[rel]
        replacement = read_bounded_file(path, MAX_SCRIPT_BYTES)
        total += len(replacement)
        need(total <= MAX_PATCH_BYTES, "Combined source patches exceed limit")
        need(replacement and b"\0" not in replacement and not replacement.startswith(b"\xef\xbb\xbf"),
             f"Empty, NUL-containing, or BOM-prefixed patch: {rel}")
        try:
            replacement.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise BuildError(f"Patch is not UTF-8: {rel}") from exc
        need(replacement != model.nodes[ref].properties["Source"], f"Patch makes no change: {rel}")
        patches[ref] = replacement
    return patches


def cross_rig_joints(model: Model) -> list[int]:
    def rig(ref: int) -> tuple[str, ...] | None:
        parts = model.paths.get(ref, ())
        if len(parts) >= 3 and parts[:2] == ("Moon Animator 2", "Rigs"):
            return parts[:3]
        return None

    joints = []
    for ref, node in model.nodes.items():
        if model.classes[node.class_id].name in ("Snap", "Weld"):
            part0 = node.properties.get("Part0")
            part1 = node.properties.get("Part1")
            need(isinstance(part0, int) and isinstance(part1, int), "Joint is missing reference properties")
            owner0, owner1 = rig(part0), rig(part1)
            if owner0 is not None and owner1 is not None and owner0 != owner1:
                joints.append(ref)
    need(len(joints) == EXPECTED_CROSS_RIG_JOINTS, "Cross-rig joint inventory does not match review")
    return sorted(joints)


def validate_output(original: Model, candidate: Model, replacements: dict[int, bytes],
                    detached: list[int], changed: dict[int, bytes]) -> None:
    need(candidate.header == original.header, "Model header changed")
    need(candidate.classes == original.classes and candidate.paths == original.paths,
         "Instance identities or hierarchy changed")
    need(candidate.script_targets == original.script_targets, "Script inventory changed")
    need(len(candidate.chunks) == len(original.chunks), "Chunk count changed")
    need(candidate.properties.keys() == original.properties.keys(), "Property inventory changed")
    for index, (old, new) in enumerate(zip(original.chunks, candidate.chunks)):
        if index in changed:
            need(new.tag == old.tag and new.payload == changed[index], "Changed chunk differs from expected payload")
        else:
            need(new.raw == old.raw, "An untouched chunk was modified")
    detached_set = set(detached)
    for key, old_prop in original.properties.items():
        new_prop = candidate.properties[key]
        need((new_prop.class_id, new_prop.name, new_prop.type_id, new_prop.header)
             == (old_prop.class_id, old_prop.name, old_prop.type_id, old_prop.header),
             "Property identity/type changed")
        if old_prop.chunk_index not in changed:
            need(new_prop.body == old_prop.body, "An untouched property changed")
            continue
        need(old_prop.values is not None and new_prop.values is not None,
             "An opaque property was modified")
        expected = list(old_prop.values)
        for index, ref in enumerate(original.classes[old_prop.class_id].refs):
            if old_prop.name == "Source" and ref in replacements:
                expected[index] = replacements[ref]
            elif old_prop.name in ("Part0", "Part1") and ref in detached_set:
                expected[index] = -1
        need(new_prop.values == tuple(expected), "Decoded property differs from intended edits")
    for ref in detached:
        need(candidate.nodes[ref].properties["Part0"] == -1
             and candidate.nodes[ref].properties["Part1"] == -1,
             "Cross-rig joint remains attached")


def build_candidate(source: bytes, patches_root: Path) -> tuple[bytes, dict[str, Any]]:
    need(len(source) == SOURCE_BYTES and sha256(source) == SOURCE_SHA256,
         "Input does not match the reviewed v34000 SHA-256; refusing to patch")
    original = parse_model(source)
    need(len(original.classes) == EXPECTED_CLASSES and len(original.nodes) == EXPECTED_INSTANCES
         and len(original.script_targets) == EXPECTED_SCRIPTS, "Pinned package inventory mismatch")
    replacements = load_patches(patches_root, original)
    detached = cross_rig_joints(original)
    detached_set = set(detached)
    changed: dict[int, bytes] = {}
    changed_records = []

    for prop in original.properties.values():
        values = list(prop.values) if prop.values is not None else None
        edited = False
        if prop.name == "Source":
            need(prop.type_id == 1 and values is not None, "Unsupported Source property")
            for index, ref in enumerate(original.classes[prop.class_id].refs):
                if ref in replacements:
                    values[index] = replacements[ref]
                    edited = True
        elif prop.name in ("Part0", "Part1") and original.classes[prop.class_id].name in ("Weld", "Snap"):
            need(prop.type_id == 19 and values is not None, "Unsupported joint reference property")
            for index, ref in enumerate(original.classes[prop.class_id].refs):
                if ref in detached_set:
                    values[index] = -1
                    edited = True
        if edited:
            body = encode_strings(tuple(values)) if prop.type_id == 1 else encode_refs(tuple(values))
            payload = prop.header + body
            need(len(payload) <= MAX_CHUNK_BYTES, "Patched chunk exceeds size limit")
            changed[prop.chunk_index] = payload
            changed_records.append({"index": prop.chunk_index, "tag": "PROP",
                                    "class": original.classes[prop.class_id].name,
                                    "property": prop.name})

    output = original.header + b"".join(
        struct.pack("<4sIII", chunk.tag, 0, len(changed[index]), 0) + changed[index]
        if index in changed else chunk.raw
        for index, chunk in enumerate(original.chunks)
    )
    need(len(output) <= MAX_FILE_BYTES, "Candidate package exceeds size limit")
    candidate = parse_model(output)
    validate_output(original, candidate, replacements, detached, changed)
    manifest = {
        "schema_version": 1,
        "builder": "moon-animator-pinned-candidate/1",
        "source": {"repository": SOURCE_REPOSITORY, "commit": SOURCE_COMMIT,
                   "filename": SOURCE_FILENAME, "sha256": SOURCE_SHA256, "bytes": len(source)},
        "output": {"sha256": sha256(output), "bytes": len(output)},
        "script_replacements": [
            {"path": target, "instance_path": "/".join(original.paths[ref]), "referent": ref,
             "before_sha256": sha256(original.nodes[ref].properties["Source"]),
             "after_sha256": sha256(replacements[ref])}
            for target, ref in sorted(original.script_targets.items()) if ref in replacements
        ],
        "disabled_joints": len(detached),
        "joint_action": "Retain instances; set both Part0 and Part1 to null",
        "joints": [
            {"referent": ref, "instance_path": "/".join(original.paths[ref]),
             "class": original.classes[original.nodes[ref].class_id].name,
             "previous_part0": "/".join(original.paths[original.nodes[ref].properties["Part0"]]),
             "previous_part1": "/".join(original.paths[original.nodes[ref].properties["Part1"]])}
            for ref in detached
        ],
        "changed_chunks": sorted(changed_records, key=lambda row: row["index"]),
        "validation": {"input_hash_pinned": True, "output_reparsed": True,
                       "unchanged_chunks_byte_identical": True,
                       "all_properties_match_expected": True,
                       "instance_hierarchy_unchanged": True,
                       "classes": len(original.classes), "instances": len(original.nodes),
                       "scripts": len(original.script_targets),
                       "unchanged_scripts": len(original.script_targets) - len(replacements),
                       "total_chunks": len(original.chunks),
                       "unchanged_chunks": len(original.chunks) - len(changed),
                       "studio_runtime_tested": False},
    }
    return output, manifest


def write_outputs(output: Path, manifest_path: Path, data: bytes, manifest: dict[str, Any]) -> None:
    need(output.absolute() != manifest_path.absolute(), "Output and manifest paths must differ")
    created = []
    handles = []
    try:
        for path in (output, manifest_path):
            reject_links(path)
            need(path.parent.is_dir(), f"Output directory does not exist: {path.parent}")
            handle = path.open("xb")  # Refuse overwrites, including races.
            created.append(path)
            handles.append(handle)
        handles[0].write(data)
        handles[1].write((json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8"))
        for handle in handles:
            handle.flush()
            os.fsync(handle.fileno())
    except BaseException:
        for handle in handles:
            handle.close()
        for path in created:
            path.unlink(missing_ok=True)
        raise
    finally:
        for handle in handles:
            handle.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="User-supplied pinned v34000 RBXM")
    parser.add_argument("--patches", type=Path, default=Path(__file__).resolve().parent / "patches")
    parser.add_argument("--output", type=Path, required=True, help="New RBXM path; existing files are refused")
    parser.add_argument("--manifest", type=Path, help="New JSON path; defaults beside the output")
    args = parser.parse_args(argv)
    manifest_path = args.manifest or args.output.with_suffix(args.output.suffix + ".manifest.json")
    try:
        need(args.output.absolute() != args.input.absolute()
             and manifest_path.absolute() != args.input.absolute(), "Refusing to overwrite input")
        source = read_bounded_file(args.input, SOURCE_BYTES)
        candidate, manifest = build_candidate(source, args.patches)
        write_outputs(args.output, manifest_path, candidate, manifest)
    except (BuildError, OSError) as exc:
        print(f"Build refused: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"output": str(args.output), "manifest": str(manifest_path),
                      "sha256": manifest["output"]["sha256"],
                      "replaced_scripts": len(manifest["script_replacements"]),
                      "disabled_joints": manifest["disabled_joints"],
                      "studio_runtime_tested": False}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
