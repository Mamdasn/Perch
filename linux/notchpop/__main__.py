import sys


def main():
    try:
        from .app import run
        return run()
    except (ImportError, ValueError) as exc:
        print(f"Notchpop could not load its desktop libraries: {exc}\n"
              "On Arch Linux install: python-gobject python-cairo gtk3 "
              "gtk-layer-shell evolution-data-server", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
