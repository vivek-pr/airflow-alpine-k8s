#!/usr/bin/env python3
import os
import sys
import re
import urllib.request


OVERRIDES = {
    "werkzeug",
    "flask",
    "flask-appbuilder",
    "itsdangerous",
    "jinja2",
    "click",
    "blinker",
    "flask-login",
    "flask-wtf",
    "flask-babel",
}


def main():
    airflow_version = os.environ.get("AIRFLOW_VERSION")
    python_version = os.environ.get("PYTHON_VERSION")
    if not airflow_version or not python_version:
        print("AIRFLOW_VERSION and PYTHON_VERSION must be set", file=sys.stderr)
        return 2
    url = (
        f"https://raw.githubusercontent.com/apache/airflow/constraints-{airflow_version}/"
        f"constraints-{python_version}.txt"
    )
    print(f"Fetching upstream constraints: {url}")
    data = urllib.request.urlopen(url).read().decode("utf-8")
    out_lines = []
    for line in data.splitlines():
        pkg = line.strip().split("==")[0].lower()
        if pkg in OVERRIDES:
            continue
        out_lines.append(line)
    with open("constraints.airflow.base.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(out_lines) + "\n")
    print("Wrote constraints.airflow.base.txt (overrides removed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

