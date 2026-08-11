#!/usr/bin/env python3
import functools
import os
import sys
from http.server import SimpleHTTPRequestHandler, test


class NoStoreHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    test(functools.partial(NoStoreHandler, directory=root), port=port)
