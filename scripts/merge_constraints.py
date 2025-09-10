#!/usr/bin/env python3
import os
import re
import sys
import urllib.request


OVERRIDES = {
    "Werkzeug": "3.1.3",
    "Flask": "3.0.3",
    "Flask-AppBuilder": "5.0.0",
    "itsdangerous": "2.2.0",
    "Jinja2": "3.1.4",
    "click": "8.1.7",
    "blinker": "1.8.2",
    "Flask-Login": "0.6.3",
    "Flask-WTF": "1.2.1",
    "Flask-Babel": "4.0.0",
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
    lines = data.splitlines()
    out = []
    seen = set()
    for line in lines:
        m = re.match(r"^([A-Za-z0-9_.\-]+)==([A-Za-z0-9_.\-]+)$", line.strip())
        if m:
            name = m.group(1)
            lname = name.lower()
            # Normalize key for overrides lookup (case-sensitive in file varies)
            key = None
            for k in OVERRIDES:
                if k.lower() == lname:
                    key = k
                    break
            if key and key not in seen:
                out.append(f"{name}=={OVERRIDES[key]}")
                seen.add(key)
            else:
                out.append(line)
        else:
            out.append(line)
    # Ensure all overrides present in case upstream lacks them
    for k, v in OVERRIDES.items():
        if k not in seen:
            out.append(f"{k}=={v}")
    with open("constraints.custom.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("Wrote constraints.custom.txt")
    return 0


if __name__ == "__main__":
    sys.exit(main())

