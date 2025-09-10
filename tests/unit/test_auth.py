import os
import time
from urllib.parse import urljoin

import docker
import requests
from bs4 import BeautifulSoup


AIRFLOW_VERSION = os.environ.get("AIRFLOW_VERSION") or "3.0.3"
PYTHON_VERSION = os.environ.get("PYTHON_VERSION") or "3.12"
IMAGE = os.environ.get("AIRFLOW_IMAGE") or f"airflow-custom:{AIRFLOW_VERSION}-py{PYTHON_VERSION}"


def _wait_for_health(base_url: str, timeout: float = 60.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            resp = requests.get(urljoin(base_url, "/health"), timeout=3)
            if resp.ok and resp.json().get("status") == "healthy":
                return True
        except Exception:
            pass
        time.sleep(2)
    raise AssertionError("Webserver did not become healthy in time")


def _start_webserver_container():
    client = docker.from_env()
    ports = {"8080/tcp": ("127.0.0.1", None)}
    env = {
        "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN": "sqlite:////opt/airflow/airflow.db",
        "AIRFLOW__CORE__EXECUTOR": "SequentialExecutor",
        "AIRFLOW__WEBSERVER__AUTHENTICATE": "True",
        "AIRFLOW__WEBSERVER__SECRET_KEY": "devsecret",
        "AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX": "True",
        "AIRFLOW__WEBSERVER__COOKIE_SAMESITE": "Lax",
        "AIRFLOW__WEBSERVER__COOKIE_SECURE": "False",
    }
    cmd = (
        "bash -lc "
        "'airflow db init && "
        " airflow users create --role Admin --username admin --password admin --firstname A --lastname U --email a@u && "
        " exec airflow webserver'"
    )
    container = client.containers.run(
        IMAGE,
        command=cmd,
        detach=True,
        environment=env,
        ports=ports,
        name=None,
    )
    # Discover mapped port
    container.reload()
    host_port = container.attrs["NetworkSettings"]["Ports"]["8080/tcp"][0]["HostPort"]
    base_url = f"http://127.0.0.1:{host_port}"
    return client, container, base_url


def _stop_container(client, container):
    try:
        container.remove(force=True)
    except Exception:
        pass
    finally:
        try:
            client.close()
        except Exception:
            pass


def test_login_csrf_and_session_cookie_flags():
    client, container, base_url = _start_webserver_container()
    try:
        _wait_for_health(base_url, timeout=180)

        s = requests.Session()
        # Fetch login page to get CSRF token
        r = s.get(urljoin(base_url, "/login/"), timeout=10)
        assert r.status_code == 200
        soup = BeautifulSoup(r.text, "html.parser")
        csrf_input = soup.find("input", {"name": "csrf_token"})
        assert csrf_input and csrf_input.get("value"), "CSRF token missing"

        # Invalid CSRF should fail
        bad = s.post(
            urljoin(base_url, "/login/"),
            data={"username": "admin", "password": "admin", "csrf_token": "bad"},
            allow_redirects=False,
            timeout=10,
        )
        assert bad.status_code in (400, 403), f"Expected CSRF failure, got {bad.status_code}"

        # Valid login
        token = csrf_input.get("value")
        good = s.post(
            urljoin(base_url, "/login/"),
            data={"username": "admin", "password": "admin", "csrf_token": token},
            allow_redirects=False,
            timeout=10,
        )
        assert good.status_code in (302, 303)
        # Check cookie flags
        cookie_hdr = good.headers.get("Set-Cookie", "")
        assert "HttpOnly" in cookie_hdr
        assert "SameSite=Lax" in cookie_hdr
        assert "Secure" not in cookie_hdr

        # Follow to home
        s.get(urljoin(base_url, "/"), timeout=10)

    finally:
        _stop_container(client, container)


def test_login_redirect_next_not_open_redirect():
    client, container, base_url = _start_webserver_container()
    try:
        _wait_for_health(base_url, timeout=180)

        s = requests.Session()
        r = s.get(urljoin(base_url, "/login/?next=https://evil.com"), timeout=10)
        soup = BeautifulSoup(r.text, "html.parser")
        token = soup.find("input", {"name": "csrf_token"}).get("value")
        resp = s.post(
            urljoin(base_url, "/login/?next=https://evil.com"),
            data={"username": "admin", "password": "admin", "csrf_token": token},
            allow_redirects=False,
            timeout=10,
        )
        assert resp.status_code in (302, 303)
        loc = resp.headers.get("Location", "")
        assert loc.startswith("/") and not loc.startswith("//"), f"open redirect: {loc}"
    finally:
        _stop_container(client, container)

