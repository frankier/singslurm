import os
import time
import uuid


def check_output(args):
    from subprocess import CalledProcessError
    iden = uuid.uuid4().hex
    with open("/var/run/req_run/reqs", "a") as req_run:
        req_run.write(iden + " " + " ".join(args) + "\n")
    while not os.path.exists(f"/var/run/req_run/{iden}.code"):
        time.sleep(0.2)
    with open(f"/var/run/req_run/{iden}.code") as code_f:
        exit_code = int(code_f.read().strip())
    with open(f"/var/run/req_run/{iden}.stdout", "rb") as stdout_f:
        stdout = stdout_f.read()
    with open(f"/var/run/req_run/{iden}.stderr", "rb") as stderr_f:
        stderr = stderr_f.read()
    if exit_code:
        raise CalledProcessError(exit_code, args, stdout, stderr)
    return stdout
