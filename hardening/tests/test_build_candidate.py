#!/usr/bin/env python3
"""Focused binary integrity tests; no plugin execution or network access.

Run: python -m unittest discover -s tests -p 'test_build_candidate.py' -v
Set MOON_ANIMATOR_TEST_INPUT to the pinned RBXM to enable package tests.
The original package is intentionally not embedded in this test suite.
"""

from __future__ import annotations

import os
from pathlib import Path
import stat
import struct
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_candidate as builder


MARKER_TARGET = "Moon_Animator_2/Classes/LayerSystemItem/MarkerTrack.luau"
REVIEWED_JOINT_REFS = frozenset({
    6559, 6574, 6591, 6599, 6870, 6871, 6872, 6881, 6884,
    6895, 6910, 6927, 6935, 7210, 7211, 7212, 7221, 7224,
})


def replace_chunk(model: builder.Model, index: int, payload: bytes,
                  tag: bytes | None = None) -> bytes:
    """Construct a parser-negative fixture without altering the input file."""
    return model.header + b"".join(
        struct.pack("<4sIII", tag or chunk.tag, 0, len(payload), 0) + payload
        if i == index else chunk.raw
        for i, chunk in enumerate(model.chunks)
    )


class PrimitiveTests(unittest.TestCase):
    def test_lz4_literal_and_overlapping_match_vectors(self):
        self.assertEqual(builder.decode_lz4_block(b"\x50hello", 5), b"hello")
        self.assertEqual(builder.decode_lz4_block(b"\x14a\x01\x00", 9), b"a" * 9)
        self.assertEqual(builder.decode_lz4_block(b"\xf0\x01" + b"x" * 16, 16), b"x" * 16)

    def test_lz4_rejects_truncation_invalid_offsets_and_size_mismatch(self):
        vectors = [
            (b"\xf0", 15),                 # Missing extended literal length.
            (b"\x50abc", 5),               # Truncated literals.
            (b"\x10a\x01", 5),            # Truncated offset.
            (b"\x10a\x00\x00", 5),        # Zero offset.
            (b"\x10a\x02\x00", 5),        # Offset before output start.
            (b"\x14a\x01\x00", 8),        # Match exceeds stated output.
            (b"\x50hello", 6),             # Too little output.
            (b"\x28\xb5\x2f\xfd", 4),    # Unsupported Zstandard frame.
        ]
        for encoded, size in vectors:
            with self.subTest(encoded=encoded), self.assertRaises(builder.BuildError):
                builder.decode_lz4_block(encoded, size)

    def test_referent_known_vector_and_null_encoding(self):
        # Deltas 1, 4, -1, -5; zigzag 2, 8, 1, 9; then byte interleaving.
        vector = b"\0" * 12 + b"\x02\x08\x01\x09"
        values = (1, 5, 4, -1)
        self.assertEqual(builder.encode_refs(values), vector)
        reader = builder.Reader(vector)
        self.assertEqual(reader.refs(4), values)
        reader.end()
        self.assertEqual(builder.encode_refs((-1, -1)), b"\0" * 6 + b"\x01\x00")

    def test_unknown_property_and_path_anomalies_rejected(self):
        with self.assertRaises(builder.BuildError):
            builder.decode_property(builder.Reader(b""), 29, 1, 0)
        for parts in [("..",), ("/absolute",), ("a\\b",), (".hidden",), ("",)]:
            with self.subTest(parts=parts), self.assertRaises(builder.BuildError):
                builder.canonical_target(parts)

    def test_wrong_input_identity_rejected_before_parsing_or_patches(self):
        with self.assertRaisesRegex(builder.BuildError, "SHA-256"):
            builder.build_candidate(b"not the reviewed package", Path("absent-patches"))

    def test_windows_reparse_points_rejected_without_path_is_junction(self):
        # Windows junctions look like directories, not POSIX symbolic links.
        # Emulate their lstat attributes so this security check runs on Linux too.
        junction = SimpleNamespace(st_mode=stat.S_IFDIR | 0o755, st_file_attributes=0x410)
        with patch.object(Path, "lstat", return_value=junction):
            with self.assertRaisesRegex(builder.BuildError, "Symbolic links"):
                builder.reject_links(Path("junction") / "patch.luau")

    def test_missing_output_leaf_still_checks_linked_ancestors(self):
        ordinary = SimpleNamespace(st_mode=stat.S_IFDIR | 0o755, st_file_attributes=0)
        junction = SimpleNamespace(st_mode=stat.S_IFDIR | 0o755, st_file_attributes=0x400)
        with patch.object(Path, "lstat", side_effect=[FileNotFoundError(), junction]):
            with self.assertRaisesRegex(builder.BuildError, "Symbolic links"):
                builder.reject_links(Path("junction") / "new.rbxm")
        with patch.object(Path, "lstat", return_value=ordinary):
            builder.reject_links(Path("regular") / "new.rbxm")

    def test_existing_outputs_are_preserved_and_partial_output_is_removed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output, manifest = root / "candidate.rbxm", root / "manifest.json"
            manifest.write_bytes(b"existing manifest")
            with self.assertRaises(FileExistsError):
                builder.write_outputs(output, manifest, b"candidate", {})
            self.assertFalse(output.exists())
            self.assertEqual(manifest.read_bytes(), b"existing manifest")
            output.write_bytes(b"existing candidate")
            with self.assertRaises(FileExistsError):
                builder.write_outputs(output, root / "new.json", b"new", {})
            self.assertEqual(output.read_bytes(), b"existing candidate")
            self.assertFalse((root / "new.json").exists())


class PinnedPackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        input_path = os.environ.get("MOON_ANIMATOR_TEST_INPUT")
        if not input_path:
            raise unittest.SkipTest("Set MOON_ANIMATOR_TEST_INPUT for pinned-package integrity tests")
        cls.source = builder.read_bounded_file(Path(input_path), builder.SOURCE_BYTES)
        if builder.sha256(cls.source) != builder.SOURCE_SHA256:
            raise AssertionError("MOON_ANIMATOR_TEST_INPUT does not match the pinned SHA-256")
        cls.original = builder.parse_model(cls.source)
        cls.sources = builder.extract_script_sources(cls.source)

    def make_patch(self, directory: str, content: bytes | None = None) -> Path:
        root = Path(directory)
        path = root / MARKER_TARGET
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content if content is not None else
                         self.sources[MARKER_TARGET] + b"\n-- Binary-builder test fixture.\n")
        return root

    def test_deterministic_build_only_changes_expected_sources_and_joint_endpoints(self):
        with tempfile.TemporaryDirectory() as directory:
            patches = self.make_patch(directory)
            output, manifest = builder.build_candidate(self.source, patches)
            repeated, repeated_manifest = builder.build_candidate(self.source, patches)
        self.assertEqual(output, repeated)
        self.assertEqual(manifest, repeated_manifest)
        candidate = builder.parse_model(output)
        self.assertEqual(len(candidate.script_targets), 139)
        self.assertEqual(len(candidate.nodes), 7351)
        self.assertEqual(candidate.header, self.original.header)
        self.assertEqual(candidate.paths, self.original.paths)
        changed_indices = {i for i, (a, b) in enumerate(zip(self.original.chunks, candidate.chunks))
                           if a.raw != b.raw}
        # One ModuleScript.Source chunk plus Snap/Weld Part0/Part1 arrays.
        self.assertEqual(changed_indices, {501, 726, 727, 1015, 1016})
        for index in changed_indices:
            self.assertEqual(struct.unpack_from("<I", candidate.chunks[index].raw, 4)[0], 0)
        candidate_sources = builder.extract_script_sources(output)
        changed_sources = {path for path in self.sources
                           if self.sources[path] != candidate_sources[path]}
        self.assertEqual(changed_sources, {MARKER_TARGET})
        self.assertEqual(candidate_sources[MARKER_TARGET],
                         self.sources[MARKER_TARGET] + b"\n-- Binary-builder test fixture.\n")
        self.assertEqual(manifest["disabled_joints"], 18)
        self.assertEqual({entry["referent"] for entry in manifest["joints"]}, REVIEWED_JOINT_REFS)
        changed_properties = []
        for ref, old_node in self.original.nodes.items():
            new_node = candidate.nodes[ref]
            self.assertEqual(new_node.class_id, old_node.class_id)
            self.assertEqual(new_node.parent, old_node.parent)
            for name, old_value in old_node.properties.items():
                if new_node.properties[name] != old_value:
                    changed_properties.append((ref, name))
        expected = {(self.original.script_targets[MARKER_TARGET], "Source")}
        expected.update((ref, name) for ref in REVIEWED_JOINT_REFS for name in ("Part0", "Part1"))
        self.assertEqual(set(changed_properties), expected)
        for ref in REVIEWED_JOINT_REFS:
            self.assertEqual(candidate.nodes[ref].properties["Part0"], -1)
            self.assertEqual(candidate.nodes[ref].properties["Part1"], -1)
        for class_name, expected_count in (("Motor6D", 72), ("Camera", 2)):
            class_ids = [cid for cid, group in self.original.classes.items() if group.name == class_name]
            self.assertEqual(sum(len(self.original.classes[cid].refs) for cid in class_ids), expected_count)
            for key, prop in self.original.properties.items():
                if key[0] in class_ids:
                    self.assertEqual(candidate.properties[key].body, prop.body)

    def test_empty_noop_and_non_script_patches_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(builder.BuildError, "No replacement"):
                builder.build_candidate(self.source, Path(directory))
            root = self.make_patch(directory, self.sources[MARKER_TARGET])
            with self.assertRaisesRegex(builder.BuildError, "no change"):
                builder.build_candidate(self.source, root)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Moon_Animator_2" / "Rigs.luau"
            path.parent.mkdir()
            path.write_bytes(b"return nil")
            with self.assertRaisesRegex(builder.BuildError, "known script target"):
                builder.build_candidate(self.source, Path(directory))

    def test_invalid_utf8_and_symlink_patches_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_patch(directory, b"\xff\xfe")
            with self.assertRaisesRegex(builder.BuildError, "UTF-8"):
                builder.build_candidate(self.source, root)
            target = root / MARKER_TARGET
            target.unlink()
            try:
                target.symlink_to(Path(os.environ["MOON_ANIMATOR_TEST_INPUT"]).absolute())
            except (OSError, NotImplementedError):
                self.skipTest("Creating symlinks is unavailable in this environment")
            with self.assertRaisesRegex(builder.BuildError, "Symbolic links"):
                builder.build_candidate(self.source, root)

    def test_modified_input_hash_rejected(self):
        changed = bytearray(self.source)
        changed[-1] ^= 1
        with self.assertRaisesRegex(builder.BuildError, "SHA-256"):
            builder.build_candidate(bytes(changed), Path("unused"))

    def test_parser_rejects_unknown_chunks_property_types_and_duplicate_script_paths(self):
        original = self.original
        with self.assertRaisesRegex(builder.BuildError, "Unknown chunk"):
            builder.parse_model(replace_chunk(original, 0, original.chunks[0].payload, b"BAD!"))
        marker_ref = original.script_targets[MARKER_TARGET]
        cid = original.nodes[marker_ref].class_id
        prop = original.properties[(cid, "Source")]
        with self.assertRaisesRegex(builder.BuildError, "Unsupported property type"):
            builder.parse_model(replace_chunk(original, prop.chunk_index,
                                              prop.header[:-1] + b"\x1d" + prop.body))
        names = original.properties[(cid, "Name")]
        sibling_ref = next(ref for ref in original.classes[cid].refs
                           if ref != marker_ref and original.nodes[ref].parent == original.nodes[marker_ref].parent)
        modified_names = list(names.values)
        modified_names[original.classes[cid].refs.index(sibling_ref)] = original.nodes[marker_ref].properties["Name"]
        with self.assertRaisesRegex(builder.BuildError, "Duplicate/ambiguous"):
            builder.parse_model(replace_chunk(original, names.chunk_index,
                                              names.header + builder.encode_strings(tuple(modified_names))))


if __name__ == "__main__":
    unittest.main()
