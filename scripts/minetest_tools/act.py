from __future__ import annotations

import argparse

from common import append_action, append_action_via_api, bridge_dir_from_args


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Queue one ONI-CADIA Minetest/Luanti citizen action via the Minetest API.")
    parser.add_argument("--api-base-url", default="", help="Minetest API base URL. Defaults to OPENCLAW_MINETEST_API_BASE_URL.")
    parser.add_argument("--agent-token", default="", help="Agent API token. Defaults to OPENCLAW_MINETEST_AGENT_TOKEN.")
    parser.add_argument("--bridge-dir", default="", help="Legacy bridge directory fallback. Only used with --direct-bridge.")
    parser.add_argument("--direct-bridge", action="store_true", help="Legacy fallback: write directly to the bridge JSONL queue.")
    parser.add_argument("--instance", type=int, default=0, help="Agent instance id. Defaults to OPENCLAW_MINETEST_AGENT_ID.")
    parser.add_argument("--agent-name", default="", help="Optional display name override.")
    subparsers = parser.add_subparsers(dest="action", required=True)

    say = subparsers.add_parser("say", help="Send a citizen chat line into the Minetest world.")
    say.add_argument("--message", required=True)

    move = subparsers.add_parser("move", help="Move the citizen avatar.")
    move.add_argument("--direction", choices=["north", "south", "east", "west", "up", "down"], default="east")
    move.add_argument("--steps", type=int, default=1)

    mine = subparsers.add_parser("mine", help="Mine nearby natural terrain into the agent inventory.")
    mine.add_argument("--material", choices=["stone", "wood", "grass", "brick", "glass", "road", "light"], default="")
    mine.add_argument("--count", type=int, default=8)

    build = subparsers.add_parser("build", help="Build a small structure using mined inventory resources.")
    build.add_argument("--shape", choices=["marker", "tower", "wall", "road", "house", "plaza"], default="marker")
    build.add_argument("--material", choices=["stone", "wood", "glass", "brick", "light", "grass", "road"], default="stone")
    build.add_argument("--label", default="")
    build.add_argument("--direction", choices=["north", "south", "east", "west"], default="east")
    build.add_argument("--height", type=int, default=6)
    build.add_argument("--width", type=int, default=5)
    build.add_argument("--length", type=int, default=12)
    build.add_argument("--radius", type=int, default=4)

    return parser


def main() -> int:
    args = build_parser().parse_args()
    payload: dict[str, object] = {
        "action": args.action,
    }
    if args.agent_name:
        payload["agent_name"] = args.agent_name
    if args.action == "say":
        payload["message"] = args.message
    elif args.action == "move":
        payload["direction"] = args.direction
        payload["steps"] = args.steps
    elif args.action == "mine":
        payload["material"] = args.material
        payload["count"] = args.count
    elif args.action == "build":
        payload["shape"] = args.shape
        payload["material"] = args.material
        payload["label"] = args.label
        payload["direction"] = args.direction
        payload["height"] = args.height
        payload["width"] = args.width
        payload["length"] = args.length
        payload["radius"] = args.radius

    if args.direct_bridge:
        queued = append_action(bridge_dir_from_args(args), args.instance, payload)
    else:
        queued = append_action_via_api(args, payload)
    print(f"MINETEST_ACTION {queued['id']} agent={queued['agent_name']} action={queued['action']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
