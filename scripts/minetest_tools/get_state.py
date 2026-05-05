from __future__ import annotations

import argparse

from common import bridge_dir_from_args, print_json, read_state, read_state_via_api


def main() -> int:
    parser = argparse.ArgumentParser(description="Read ONI-CADIA Minetest/Luanti state via the Minetest API.")
    parser.add_argument("--api-base-url", default="", help="Minetest API base URL. Defaults to OPENCLAW_MINETEST_API_BASE_URL.")
    parser.add_argument("--bridge-dir", default="", help="Legacy bridge directory fallback. Only used with --direct-bridge.")
    parser.add_argument("--direct-bridge", action="store_true", help="Legacy fallback: read state.json directly from the bridge.")
    args = parser.parse_args()
    payload = read_state(bridge_dir_from_args(args)) if args.direct_bridge else read_state_via_api(args)
    print_json(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
