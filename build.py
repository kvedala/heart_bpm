#!/usr/bin/env python3

import logging as log
import subprocess
import os
from typing import Tuple
import yaml
import tempfile
from argparse import ArgumentParser, Namespace
log.basicConfig(
    format="%(asctime)s %(levelname)s: %(message)s", level=log.INFO)


def getBuildCount() -> int:
    output = subprocess.check_output(["git", "rev-list", "--count", "HEAD"])
    return int(output)


def makeOptions() -> Namespace:
    arg = ArgumentParser(description="Script to build the app.")
    arg.add_argument("-t", "--type", choices=['apk', 'ios', 'appbundle', 'ipa'],
                     type=str, default='apk',  # const='apk', nargs='?',
                     help="Type of build to make. (Default: '%(default)s')")
    arg.add_argument("--install", type=str, default=None,
                     help="install to device d. (Default: '%(default)s')")
    # arg.add_argument("-n", action='store_true',
    #                  help="Do not make a new commit with tag. (Default: '%(default)s')")

    out = arg.parse_args()
    return out


def getVersion() -> Tuple[str, bool]:
    last_commit = subprocess.check_output(
        ["git", "log", "-1", "--oneline"])
    if last_commit.decode('utf-8').split(' ', 1)[1].startswith("updated build number"):
        with open("pubspec.yaml", 'rt') as f:
            yamlData = yaml.safe_load(f)
            return yamlData['version'], False

    version = "1.0.0(0)"
    with tempfile.TemporaryFile('w+t') as tmpFile:
        with open("pubspec.yaml", 'rt') as f:
            yamlData = yaml.safe_load(f)
            f.seek(0)
            tmpFile.writelines(f.readlines())
        tmpFile.seek(0)

        version = yamlData['version'].split('+')[0]
        version = f"{version}+{getBuildCount()}"

        yamlData['version'] = version
        with open("pubspec.yaml", 'wt') as f:
            for line in tmpFile.readlines():
                if line.strip().startswith("version:"):
                    f.write(f"version: {version}\n")
                else:
                    f.write(line)

    return version, True


if __name__ == '__main__':
    args = makeOptions()

    version, toCommit = getVersion()
    # Build the project

    log.info(f"Building: v{version}")

    if toCommit:
        subprocess.call(["git", "commit", "-m", "updated build number", "pubspec.yaml"],
                        env=os.environ.copy(), shell=False, cwd=".")
        subprocess.call(['git', 'tag', f'v{version}'],
                        env=os.environ.copy(), shell=False, cwd=".")

    log.info(f"Building: {args.type}")
    subprocess.call(["flutter", "build", args.type],
                    env=os.environ.copy(), shell=False, cwd=".")
    log.info("Building: Done")

    if args.install is not None:
        subprocess.call(["flutter", "install", "-d", args.install],
                        env=os.environ.copy(), shell=False, cwd=".")
