"""Exercise the packed CLI with real package managers and terminal prompts.

Uses only Python's standard library, available on the Ubuntu Actions runner.
"""

import argparse
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import shlex
import signal
import struct
import subprocess
import tempfile
import termios
import time


MANAGERS = {
    "npm": ("npm", "package-lock.json"),
    "pnpm": ("pnpm", "pnpm-lock.yaml"),
    "yarn-classic": ("yarn", "yarn.lock"),
    "yarn-berry": ("yarn", "yarn.lock"),
    "bun": ("bun", "bun.lock"),
}


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def stop(process):
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()


class Suite:
    def __init__(self, args, workspace):
        self.manager = args.manager
        self.command, self.lockfile = MANAGERS[self.manager]
        self.workspace = workspace
        self.logs = args.logs.resolve()
        self.logs.mkdir(parents=True, exist_ok=True)
        self.env = {
            **os.environ,
            # Exercise the normal CLI, including existing-project detection.
            "CI": "false",
            "TERM": "xterm",
            "NO_COLOR": "1",
            "NPM_CONFIG_AUDIT": "false",
            "NPM_CONFIG_FUND": "false",
            "YARN_ENABLE_TELEMETRY": "0",
        }
        self.env.pop("FORCE_COLOR", None)
        self.log = self.logs / "setup.log"
        self.run(["node", "--version"], workspace)
        self.run([self.command, "--version"], workspace)
        cli_directory = workspace / "cli"
        self.run([
            "npm", "install", "--prefix", str(cli_directory), str(args.package.resolve()),
        ], workspace)
        self.env["CRA_E2E_CLI"] = str(
            cli_directory / "node_modules/create-rescript-app/out/create-rescript-app.cjs"
        )
        self.launcher = workspace / "launcher"
        self.launcher.mkdir()
        wrapper = Path(__file__).with_name("launch-cli.mjs").resolve()
        write_json(self.launcher / "package.json", {
            "name": "cra-e2e-launcher",
            "private": True,
            "scripts": {"cra": shlex.join(["node", str(wrapper)])},
        })
        if self.manager == "yarn-berry":
            (self.launcher / ".yarnrc.yml").write_text("nodeLinker: node-modules\n")
        self.run([self.command, "install"], self.launcher)
        self.passed = 0

    def run(self, command, cwd, expected=0):
        with self.log.open("a") as log:
            log.write(f"\n$ {shlex.join(command)}\n(cwd: {cwd})\n")
            log.flush()
            process = subprocess.Popen(
                command, cwd=cwd, env=self.env, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, text=True, start_new_session=True,
            )
            try:
                output, _ = process.communicate(timeout=300)
            except BaseException:
                stop(process)
                output, _ = process.communicate()
                log.write(output)
                raise
            log.write(output)
        check(process.returncode == expected,
              f"Command exited {process.returncode}, expected {expected}: {shlex.join(command)}")
        return output

    def cli(self, cwd, args=(), prompts=(), expected=0):
        # Every manager runs the same launcher script; package-manager detection
        # and the subsequent installation commands run without mocked env values.
        separator = ["--"] if self.manager == "npm" else []
        command = [self.command, "run", "cra", *separator, str(cwd), *args]
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 160, 0, 0))
        process = None
        with self.log.open("ab") as log:
            log.write(f"\n$ {shlex.join(command)}\n".encode())
            try:
                process = subprocess.Popen(
                    command, cwd=self.launcher, env=self.env, stdin=slave,
                    stdout=slave, stderr=slave, start_new_session=True,
                )
                os.close(slave)
                slave = None
                pending = b""
                next_prompt = 0
                deadline = time.monotonic() + 300
                while True:
                    check(time.monotonic() < deadline, "CLI timed out waiting for a prompt or installation")
                    ready, _, _ = select.select([master], [], [], 0.2)
                    if not ready:
                        if process.poll() is not None:
                            break
                        continue
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as error:
                        if error.errno == errno.EIO:
                            break
                        raise
                    if not chunk:
                        break
                    log.write(chunk)
                    log.flush()
                    pending += chunk
                    if next_prompt < len(prompts):
                        question, answer = prompts[next_prompt]
                        position = pending.find(question.encode())
                        if position >= 0:
                            os.write(master, answer.encode())
                            next_prompt += 1
                            pending = b""
                process.wait(timeout=10)
                check(process.returncode == expected,
                      f"CLI exited {process.returncode}, expected {expected}")
                check(next_prompt == len(prompts),
                      f"CLI exited before answering all prompts ({next_prompt}/{len(prompts)})")
            finally:
                if process is not None:
                    stop(process)
                if slave is not None:
                    os.close(slave)
                os.close(master)

    def case(self, name, perform):
        self.log = self.logs / f"{name}.log"
        directory = self.workspace / name
        directory.mkdir()
        print(f"RUN {self.manager}: {name}", flush=True)
        try:
            perform(directory)
        except BaseException:
            print(self.log.read_text(errors="replace"), flush=True)
            print(f"FAIL {name}; log: {self.log}", flush=True)
            raise
        self.passed += 1
        print(f"PASS {self.manager}: {name}", flush=True)

    def verify_project(self, directory, suffix, legacy=False):
        package = json.loads((directory / "package.json").read_text())
        config = json.loads((directory / "rescript.json").read_text())
        check(config["name"] == package["name"], "Project and package names differ")
        check(config["suffix"] == suffix, f"Unexpected generated JS suffix: {config}")
        check((directory / self.lockfile).is_file(), f"Missing {self.lockfile}: manager detection failed")
        if self.manager != "npm":
            check(not (directory / "package-lock.json").exists(), "npm lockfile was not removed")
        if self.manager == "yarn-berry":
            check("nodeLinker: node-modules" in (directory / ".yarnrc.yml").read_text(),
                  "Yarn Berry node-modules linker was not configured")
        installed = json.loads((directory / "node_modules/rescript/package.json").read_text())["version"]
        if legacy:
            check(installed == "11.1.4", f"Expected ReScript 11.1.4, installed {installed}")
            check("@rescript/core" in package["dependencies"], "Missing ReScript 11 core dependency")
        else:
            check(installed.startswith("12."), f"Expected a current ReScript 12 version, installed {installed}")
        self.run([self.command, "run", "res:build"], directory)
        output = self.run(["node", f"src/Demo{suffix}"], directory)
        check(output.strip() == "Hello, world!", f"Unexpected generated program output: {output}")

    def new_project(self, directory, target="my-app", devcontainer=False):
        project = directory if target in (".", "./") else directory / target
        preserved = {}
        if devcontainer:
            project.mkdir(exist_ok=True)
            (project / ".devcontainer").mkdir()
            preserved[".devcontainer/devcontainer.json"] = '{"name":"keep me"}\n'
            if target in (".", "./"):
                preserved.update({"README.md": "Existing README\n", ".gitignore": "keep-this-entry\n"})
            for path, contents in preserved.items():
                (project / path).write_text(contents)
        self.cli(directory, [target, "--template", "basic"])
        check(json.loads((project / "package.json").read_text())["name"] == project.name,
              "Current-directory package name was not derived from the directory")
        for path, contents in preserved.items():
            actual = (project / path).read_text()
            check(actual == contents if path != ".gitignore" else actual.startswith(contents),
                  f"Scaffolding overwrote {path}")
        self.verify_project(project, ".res.mjs")

    def existing_project(self, directory, module="commonjs", typescript=None):
        original = {
            "name": directory.name,
            "version": "1.0.0",
            "private": True,
            "type": module,
            "scripts": {"test": "node src/original.cjs"},
            "dependencies": {"is-number": "7.0.0"},
        }
        if typescript:
            original["devDependencies"] = {"typescript": "5.9.3"}
        write_json(directory / "package.json", original)
        (directory / "src").mkdir()
        preserved = {
            "README.md": "Existing project README\n",
            ".gitignore": "existing-ignore\n",
            "src/original.cjs": 'console.log(require("is-number")(42));\n',
        }
        if typescript:
            preserved["src/original.ts"] = "export const existingValue: number = 1;\n"
            preserved["tsconfig.base.json"] = json.dumps({"compilerOptions": {
                "module": "NodeNext" if typescript == "nodenext" else "ESNext",
                "moduleResolution": typescript,
                "target": "ES2022", "strict": True, "noEmit": True,
            }}, indent=2)
            (directory / "tsconfig.json").write_text('''{
  // Preserve this comment and the inherited configuration.
  "extends": "./tsconfig.base.json",
  "compilerOptions": {"skipLibCheck": true,},
  "include": ["src"],
}
''')
        for path, contents in preserved.items():
            (directory / path).write_text(contents)
        self.run([self.command, "install"], directory)
        prompts = [
            ("Do you want to add ReScript", "y"),
            # The reversed registry list ends with the sole supported v11
            # release. Arrow-up wraps to it; assert the installed version below.
            ("ReScript version?", "\r" if typescript else "\x1b[A\r"),
            ("Where will you put your ReScript source files?", "\r"),
        ]
        if typescript:
            prompts.append(("Set compilerOptions.allowJs to true", "y"))
            if typescript == "bundler":
                prompts.append(("Set compilerOptions.allowImportingTsExtensions to true", "y"))
        else:
            prompts.append(("What module system will you use?", "\r" if module == "module" else "\x1b[B\r"))
        prompts.append(("Do you want to check generated", "n"))
        self.cli(directory, prompts=prompts)
        package = json.loads((directory / "package.json").read_text())
        for field in ("name", "version", "private", "type"):
            check(package[field] == original[field], f"Changed existing package field {field}")
        check(package["scripts"]["test"] == original["scripts"]["test"], "Overwrote existing script")
        check(package["dependencies"]["is-number"] == "7.0.0", "Changed existing dependency")
        if typescript:
            check(package["devDependencies"] == original["devDependencies"], "Changed TypeScript dependency")
        for path, contents in preserved.items():
            actual = (directory / path).read_text()
            check(actual == contents if path != ".gitignore" else actual.startswith(contents),
                  f"Adding ReScript overwrote {path}")
        suffix = ".res.js" if typescript or module == "commonjs" else ".res.mjs"
        check(f"**/*{suffix}" in (directory / ".gitignore").read_text(), "Generated JS was not ignored")
        if typescript:
            config = json.loads((directory / "rescript.json").read_text())
            check(config["gentypeconfig"]["moduleResolution"] ==
                  ("node16" if typescript == "nodenext" else "bundler"), "Incorrect genType mapping")
            tsconfig = (directory / "tsconfig.json").read_text()
            check("// Preserve this comment" in tsconfig, "Lost tsconfig comment")
            check('"allowJs": true' in tsconfig, "Did not enable allowJs")
            if typescript == "bundler":
                check('"allowImportingTsExtensions": true' in tsconfig, "Did not enable TS extension imports")
            (directory / "src/Interop.res").write_text("@genType\nlet answer = 42\n")
            extension = "ts" if typescript == "bundler" else "js"
            (directory / "src/consumer.ts").write_text(
                f'import {{answer}} from "./Interop.gen.{extension}";\nconst value: number = answer;\n'
            )
        self.verify_project(directory, suffix, legacy=not typescript)
        output = self.run([self.command, "run", "test"], directory)
        check("true" in output.splitlines(),
              "Existing JavaScript program no longer runs")
        if typescript:
            check((directory / "src/Interop.gen.ts").is_file(), "genType did not generate TypeScript")
            self.run(["node", "node_modules/typescript/bin/tsc", "--noEmit"], directory)

    def occupied_directory(self, directory):
        project = directory / "occupied"
        project.mkdir()
        sentinel = project / "keep.txt"
        sentinel.write_text("Do not overwrite\n")
        self.cli(directory, ["occupied", "--template", "basic"], expected=1)
        check(sentinel.read_text() == "Do not overwrite\n", "Overwrote occupied directory")
        check(sorted(path.name for path in project.iterdir()) == ["keep.txt"],
              "Failed scaffolding left files in the occupied directory")

    def execute(self):
        self.case("new-basic", self.new_project)
        self.case("existing-commonjs", self.existing_project)
        if self.manager == "npm":
            self.case("existing-esm", lambda path: self.existing_project(path, module="module"))
            for mode in ("nodenext", "bundler"):
                self.case(f"existing-ts-{mode}", lambda path, mode=mode:
                          self.existing_project(path, module="module", typescript=mode))
            for name, target in (("devcontainer-named", "my-app"), ("devcontainer-dot", "."),
                                 ("devcontainer-dot-slash", "./")):
                self.case(name, lambda path, target=target:
                          self.new_project(path, target=target, devcontainer=True))
            self.case("occupied-directory", self.occupied_directory)
        print(f"PASS: {self.passed} E2E cases for {self.manager}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True, help="npm pack tarball to test")
    parser.add_argument("--manager", choices=MANAGERS, required=True)
    parser.add_argument("--logs", type=Path, required=True)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="cra e2e ") as directory:
        Suite(args, Path(directory)).execute()


if __name__ == "__main__":
    main()
