#!/usr/bin/env python3
import os
import sys
from pathlib import Path


if __name__ == "__main__":
    project_root = Path(__file__).resolve().parent / "qa_insight_backend"
    sys.path.insert(0, str(project_root))

    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "qa_insight_backend.settings")

    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)
