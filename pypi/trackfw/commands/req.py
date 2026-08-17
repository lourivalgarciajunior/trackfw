"""
commands/req.py — Subcomando `trackfw req`.
Registra o grupo de subcomandos REQ no argparse principal.
"""

import sys


def register(subparsers):
    """Adiciona subcomando `req` com sub-subcomando `new` ao parser principal."""
    req_parser = subparsers.add_parser(
        "req",
        help="Manage Requirements",
    )
    req_sub = req_parser.add_subparsers(dest="req_command", metavar="COMMAND")

    # req new [<title>]
    new_parser = req_sub.add_parser(
        "new",
        help="Create a new REQ",
    )
    new_parser.add_argument(
        "title",
        nargs="?",
        default=None,
        help="REQ title (prompted if omitted)",
    )

    # req move <name> <state>
    #
    # O roadmap tinha transicao de estado como comando desde sempre; a REQ nao,
    # apesar de o validator ja varrer os cinco estados dela.
    # Ver REQ-2026-08-17-req-move.
    move_parser = req_sub.add_parser(
        "move",
        help="Move a REQ between states (backlog|wip|blocked|done|abandoned)",
    )
    move_parser.add_argument("name", help="REQ name (partial match)")
    move_parser.add_argument("state", help="Target state")

    # req list
    req_sub.add_parser("list", help="List all REQs with status")

    req_parser.set_defaults(func=_dispatch)


def _dispatch(args):
    """Despacha para o sub-subcomando correto."""
    if args.req_command == "new":
        _cmd_new(args)
    elif args.req_command == "move":
        _cmd_move(args)
    elif args.req_command == "list":
        _cmd_list(args)
    else:
        print("Usage: trackfw req <command>")
        print("Commands: new, list, move")
        sys.exit(0)


def _cmd_list(args):
    from trackfw.config import load as load_config
    from trackfw.generators.req import list_reqs

    list_reqs(load_config())


def _cmd_move(args):
    from trackfw.config import load as load_config
    from trackfw.generators.req import move_req

    try:
        dst = move_req(args.name, args.state, load_config())
    except (ValueError, FileNotFoundError) as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)

    print(f"✓ moved {args.name} → {dst}")


def _cmd_new(args):
    from trackfw.config import load as load_config
    from trackfw.generators.req import generate_req

    title = args.title
    if not title:
        try:
            title = input("REQ title: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("")
            sys.exit(0)

    if not title:
        print("Error: title is required", file=sys.stderr)
        sys.exit(1)

    cfg = load_config()
    req_dir = cfg.get("req_dir", "docs/req")

    filepath = generate_req(title=title, req_dir=req_dir)
    print(f"created {filepath}")
