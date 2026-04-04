#!/usr/bin/env python3
# purpose:  Read the canonical test-suite manifest for local execution, CI matrix generation, and suite inventory validation.
# when:     Use when running the full local suite, generating CI suite jobs, or validating suite inventory; not for path-to-suite selection logic itself.
# inputs:   Subcommand (validate|ci-matrix|run-local|run-suite), optional --root PATH, and a suite path for run-suite.
# outputs:  Prints a validation message, CI matrix JSON, or the full local suite transcript and exit code.
# risk:     safe
# source:   original

from __future__ import annotations

import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import time


MANIFEST_RELATIVE_PATH = pathlib.Path("scripts/tests/suite-manifest.json")
PRE_FLIGHT_SCRIPT = "scripts/ci/validate-test-output.sh"


def default_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parents[2]


def resolve_root(raw_root: str | None) -> pathlib.Path:
    if raw_root:
        return pathlib.Path(raw_root).resolve()
    return pathlib.Path.cwd().resolve()


def load_manifest(root: pathlib.Path) -> tuple[dict[str, object], pathlib.Path]:
    manifest_path = root / MANIFEST_RELATIVE_PATH
    if not manifest_path.is_file():
        raise SystemExit(f"suite manifest not found: {manifest_path}")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid suite manifest JSON: {manifest_path}: {exc}") from exc
    return manifest, manifest_path


def validate_manifest(manifest: dict[str, object], root: pathlib.Path) -> tuple[list[dict[str, object]], list[dict[str, object]], dict[str, dict[str, object]]]:
    if manifest.get("schemaVersion") != "1.0":
        raise SystemExit("suite manifest missing schemaVersion 1.0")

    phases = manifest.get("phases")
    suites = manifest.get("suites")
    if not isinstance(phases, list) or not phases:
        raise SystemExit("suite manifest must contain a non-empty phases array")
    if not isinstance(suites, list) or not suites:
        raise SystemExit("suite manifest must contain a non-empty suites array")

    phase_ids: set[str] = set()
    phases_by_id: dict[str, dict[str, object]] = {}
    for phase in phases:
        if not isinstance(phase, dict):
            raise SystemExit("suite manifest phases must be objects")
        phase_id = phase.get("id")
        label = phase.get("label")
        if not isinstance(phase_id, str) or not phase_id:
            raise SystemExit(f"invalid phase id: {phase!r}")
        if not isinstance(label, str) or not label:
            raise SystemExit(f"invalid phase label for {phase_id}")
        if phase_id in phase_ids:
            raise SystemExit(f"duplicate phase id in suite manifest: {phase_id}")
        requirement = phase.get("optionalRequirement")
        if requirement is not None:
            if not isinstance(requirement, dict):
                raise SystemExit(f"optionalRequirement for phase {phase_id} must be an object")
            command = requirement.get("command")
            req_label = requirement.get("label", command)
            probe_args = requirement.get("probeArgs", [])
            if not isinstance(command, str) or not command:
                raise SystemExit(f"phase {phase_id} optionalRequirement must define a non-empty command")
            if not isinstance(req_label, str) or not req_label:
                raise SystemExit(f"phase {phase_id} optionalRequirement must define a non-empty label")
            if not isinstance(probe_args, list) or any(not isinstance(arg, str) for arg in probe_args):
                raise SystemExit(f"phase {phase_id} optionalRequirement probeArgs must be a string array")
        phase_ids.add(phase_id)
        phases_by_id[phase_id] = phase

    suite_ids: set[str] = set()
    suite_paths: set[str] = set()
    normalized_suites: list[dict[str, object]] = []
    for suite in suites:
        if not isinstance(suite, dict):
            raise SystemExit("suite manifest suites must be objects")
        suite_id = suite.get("id")
        suite_path = suite.get("path")
        phase_id = suite.get("phase")
        ci_label = suite.get("ciLabel")
        if not isinstance(suite_id, str) or not suite_id:
            raise SystemExit(f"invalid suite id: {suite!r}")
        if not isinstance(suite_path, str) or not suite_path:
            raise SystemExit(f"invalid suite path for {suite_id}")
        if not isinstance(phase_id, str) or phase_id not in phases_by_id:
            raise SystemExit(f"suite {suite_id} references unknown phase: {phase_id}")
        if not isinstance(ci_label, str) or not ci_label:
            raise SystemExit(f"suite {suite_id} missing ciLabel")
        if suite_id in suite_ids:
            raise SystemExit(f"duplicate suite id in suite manifest: {suite_id}")
        if suite_path in suite_paths:
            raise SystemExit(f"duplicate suite path in suite manifest: {suite_path}")
        if not (root / suite_path).is_file():
            raise SystemExit(f"suite path missing from repository: {suite_path}")
        suite_ids.add(suite_id)
        suite_paths.add(suite_path)
        normalized_suites.append(suite)

    return phases, normalized_suites, phases_by_id


def requirement_for_phase(phase: dict[str, object]) -> dict[str, object] | None:
    requirement = phase.get("optionalRequirement")
    if isinstance(requirement, dict):
        return requirement
    return None


def command_available(command: str) -> bool:
    return shutil.which(command) is not None


def requirement_probe_passes(command: str, probe_args: list[str], root: pathlib.Path) -> bool:
    if not probe_args:
        return True
    result = subprocess.run(
        [command, *probe_args],
        cwd=root,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def run_command(command: list[str], root: pathlib.Path) -> int:
    return subprocess.run(command, cwd=root, check=False).returncode


def requirement_skip_reason(phase: dict[str, object], root: pathlib.Path) -> str | None:
    requirement = requirement_for_phase(phase)
    if requirement is None:
        return None

    label = str(phase["label"])
    command = str(requirement["command"])
    requirement_label = str(requirement.get("label", command))
    probe_args = [str(arg) for arg in requirement.get("probeArgs", [])]

    if not command_available(command):
        return f"Skipping {label}: missing {requirement_label}"
    if not requirement_probe_passes(command, probe_args, root):
        return f"Skipping {label}: {requirement_label} is installed but non-functional (runtime error)"
    return None


def suite_lookup_by_path(suites: list[dict[str, object]]) -> dict[str, dict[str, object]]:
    return {str(suite["path"]): suite for suite in suites}


def cmd_validate(root: pathlib.Path) -> int:
    manifest, _ = load_manifest(root)
    phases, suites, _ = validate_manifest(manifest, root)
    print(f"OK: suite manifest is valid ({len(phases)} phases, {len(suites)} suites)")
    return 0


def cmd_ci_matrix(root: pathlib.Path) -> int:
    manifest, _ = load_manifest(root)
    phases, suites, phases_by_id = validate_manifest(manifest, root)
    del phases
    del phases_by_id
    include = []
    for suite in suites:
        include.append(
            {
                "id": suite["id"],
                "name": suite["ciLabel"],
                "path": suite["path"],
            }
        )
    print(json.dumps({"include": include}, indent=2))
    return 0


def cmd_run_suite(root: pathlib.Path, suite_path: str) -> int:
    manifest, _ = load_manifest(root)
    phases, suites, phases_by_id = validate_manifest(manifest, root)
    del phases
    suite_lookup = suite_lookup_by_path(suites)
    suite = suite_lookup.get(suite_path)
    if suite is None:
        raise SystemExit(f"suite path not present in manifest: {suite_path}")

    phase = phases_by_id[str(suite["phase"])]
    skip_reason = requirement_skip_reason(phase, root)
    if skip_reason is not None:
        print(skip_reason)
        return 0

    return run_command(["bash", suite_path], root)


def cmd_run_local(root: pathlib.Path) -> int:
    manifest, _ = load_manifest(root)
    phases, suites, phases_by_id = validate_manifest(manifest, root)
    suites_by_phase: dict[str, list[dict[str, object]]] = {str(phase["id"]): [] for phase in phases}
    for suite in suites:
        suites_by_phase[str(suite["phase"])] .append(suite)

    failed_suites = 0
    failed_list: list[str] = []
    total_suites = 0

    print("## Pre-flight")
    if run_command(["bash", PRE_FLIGHT_SCRIPT], root) == 0:
        print("  pre-flight: validate-test-output OK")
    else:
        print("  pre-flight: validate-test-output FAILED")
        failed_suites = 1
        failed_list.append(PRE_FLIGHT_SCRIPT)
    print("")

    for phase in phases:
        label = str(phase["label"])
        print("")
        print(f"## {label}")
        skip_reason = requirement_skip_reason(phase, root)
        if skip_reason is not None:
            print(skip_reason)
            continue

        for suite in suites_by_phase[str(phase["id"])]:
            suite_path = str(suite["path"])
            total_suites += 1
            print(f"==> {suite_path}")
            sys.stdout.flush()
            start = time.monotonic()
            rc = run_command(["bash", suite_path], root)
            elapsed = int(time.monotonic() - start)
            if rc == 0:
                print(f"  ({elapsed}s)")
            else:
                print(f"  ({elapsed}s) FAILED")
                failed_suites += 1
                failed_list.append(suite_path)

    print("")
    if failed_suites > 0:
        print(f"## FAILED ({failed_suites} of {total_suites} suites)")
        for failed in failed_list:
            print(f"  - {failed}")
        return 1

    print(f"All {total_suites} test suites passed.")
    return 0


def add_root_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--root", default=str(default_root()), help="Repository root to inspect")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="python3 scripts/tests/suite-manifest.py")
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate_parser = subparsers.add_parser("validate")
    add_root_argument(validate_parser)

    ci_matrix_parser = subparsers.add_parser("ci-matrix")
    add_root_argument(ci_matrix_parser)

    run_local_parser = subparsers.add_parser("run-local")
    add_root_argument(run_local_parser)

    run_suite_parser = subparsers.add_parser("run-suite")
    add_root_argument(run_suite_parser)
    run_suite_parser.add_argument("suite_path", help="Manifest suite path for run-suite")

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    root = resolve_root(args.root)

    if args.command == "validate":
        return cmd_validate(root)
    if args.command == "ci-matrix":
        return cmd_ci_matrix(root)
    if args.command == "run-local":
        return cmd_run_local(root)
    if args.command == "run-suite":
        return cmd_run_suite(root, args.suite_path)
    raise SystemExit(f"unsupported command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())