import os
import tempfile
import time
from pathlib import Path
from urllib.parse import urljoin

import docker
import requests


AIRFLOW_VERSION = os.environ.get("AIRFLOW_VERSION") or "3.0.3"
PYTHON_VERSION = os.environ.get("PYTHON_VERSION") or "3.12"
IMAGE = os.environ.get("AIRFLOW_IMAGE") or f"airflow-custom:{AIRFLOW_VERSION}-py{PYTHON_VERSION}"


def wait_http_healthy(url: str, timeout: float = 180.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            r = requests.get(urljoin(url, "/health"), timeout=3)
            if r.ok and r.json().get("status") == "healthy":
                return
        except Exception:
            pass
        time.sleep(2)
    raise AssertionError("webserver not healthy")


def test_build_and_run_stack():
    client = docker.from_env()

    # Create temp airflow home on host
    with tempfile.TemporaryDirectory() as tmp:
        home = Path(tmp)
        (home / "dags").mkdir()
        (home / "logs").mkdir()
        (home / "plugins").mkdir()

        # Simple DAG
        dag_py = (home / "dags" / "test_dag.py")
        dag_py.write_text(
            """
from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator

with DAG('smoke_dag', schedule=None, start_date=datetime(2024,1,1), catchup=False) as dag:
    BashOperator(task_id='echo', bash_command='echo hello')
"""
        )

        env_common = {
            "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION": "False",
            "AIRFLOW__CORE__LOAD_EXAMPLES": "False",
            "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN": f"sqlite:////opt/airflow/airflow.db",
            "AIRFLOW__WEBSERVER__AUTHENTICATE": "True",
            "AIRFLOW__WEBSERVER__SECRET_KEY": "devsecret",
            "AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX": "True",
        }

        binds = {str(home): {"bind": "/opt/airflow", "mode": "rw"}}

        # Bootstrap DB and user
        bootstrap = client.containers.run(
            IMAGE,
            command=(
                "bash -lc "
                "'airflow db reset -y && airflow db init && "
                " airflow users create --role Admin --username admin --password admin --firstname A --lastname U --email a@u'"
            ),
            environment=env_common,
            volumes=binds,
            detach=True,
        )
        rc = bootstrap.wait(timeout=300)["StatusCode"]
        logs = bootstrap.logs().decode("utf-8", "ignore")
        bootstrap.remove()
        assert rc == 0, f"bootstrap failed: {logs}"

        # Start services
        web = client.containers.run(
            IMAGE,
            command="airflow webserver",
            environment=env_common,
            volumes=binds,
            ports={"8080/tcp": ("127.0.0.1", None)},
            detach=True,
        )
        sch = client.containers.run(
            IMAGE,
            command="airflow scheduler",
            environment=env_common,
            volumes=binds,
            detach=True,
        )
        trg = client.containers.run(
            IMAGE,
            command="airflow triggerer",
            environment=env_common,
            volumes=binds,
            detach=True,
        )

        try:
            web.reload()
            port = web.attrs["NetworkSettings"]["Ports"]["8080/tcp"][0]["HostPort"]
            base_url = f"http://127.0.0.1:{port}"
            wait_http_healthy(base_url, timeout=300)

            # Programmatic login and fetch home
            s = requests.Session()
            r = s.get(urljoin(base_url, "/login/"), timeout=10)
            assert r.ok
            import bs4
            soup = bs4.BeautifulSoup(r.text, "html.parser")
            token = soup.find("input", {"name": "csrf_token"}).get("value")
            resp = s.post(urljoin(base_url, "/login/"), data={"username": "admin", "password": "admin", "csrf_token": token}, allow_redirects=True, timeout=10)
            assert resp.status_code == 200
            # Load home
            home_resp = s.get(urljoin(base_url, "/"), timeout=10)
            assert home_resp.status_code == 200

            # Trigger and wait for DAG success via CLI inside web container
            exec1 = web.exec_run("bash -lc 'airflow dags trigger smoke_dag'", demux=True)
            assert exec1.exit_code == 0, (exec1[1] or b"").decode()

            # Poll for success
            deadline = time.time() + 300
            succeeded = False
            while time.time() < deadline:
                st = web.exec_run("bash -lc 'airflow dags state smoke_dag $(date +%Y-%m-%d)'", demux=True)
                out = (st[0] or b"") + (st[1] or b"") if isinstance(st, tuple) else st.output
                txt = out.decode("utf-8", "ignore")
                if "success" in txt.lower():
                    succeeded = True
                    break
                time.sleep(5)
            assert succeeded, "DAG did not reach success"

        finally:
            for c in (web, sch, trg):
                try:
                    c.remove(force=True)
                except Exception:
                    pass
