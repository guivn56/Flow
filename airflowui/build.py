#!/usr/bin/env python3
"""Build do AirflowUI: junta as 7 abas num unico ficheiro.

O bundle (dist/airflowui.lua) e o artefacto que se cola no executor:
um ficheiro, sem readfile das abas, sem pasta tabs/ no telemóvel.

Como funciona:
  1. le o main.lua do projecto;
  2. troca a linha "local EMBEDDED = {}" pela tabela com as abas
     embutidas (cada aba como uma string longa);
  3. escreve o bundle e um manifesto (sha256 por modulo + do bundle).

O build e determinista: os mesmos ficheiros dao sempre o mesmo bundle.
"""
import hashlib
import json
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(ROOT)
OUT = os.path.join(REPO, "dist", "airflowui.lua")
MAP = os.path.join(REPO, "dist", "airflowui.lua.map.json")

MAIN = os.path.join(ROOT, "main.lua")
TABS_DIR = os.path.join(ROOT, "tabs")

# A ordem e a ordem em que as abas aparecem na sidebar.
TABS = [
    "tabs/visuals.lua",
    "tabs/players.lua",
    "tabs/combat.lua",
    "tabs/world.lua",
    "tabs/misc.lua",
    "tabs/lootfinder.lua",
    "tabs/server.lua",
]

PLACEHOLDER = "local EMBEDDED = {}"
CLOSE = "]==]"
OPEN = "[==["


def read(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    main_src = read(MAIN)
    if PLACEHOLDER not in main_src:
        print("main.lua nao tem a linha %r" % PLACEHOLDER)
        return 1

    parts = []
    for rel in TABS:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            print("aba em falta: " + rel)
            return 1
        code = read(path)
        if CLOSE in code:
            print("aba com delimitador %s: %s" % (CLOSE, rel))
            return 1
        parts.append((rel, code))

    table = ["local EMBEDDED = {"]
    for rel, code in parts:
        table.append('\t["%s"] = %s%s%s,' % (rel, OPEN, code, CLOSE))
    table.append("}")
    embedded = "\n".join(table)

    bundle = main_src.replace(PLACEHOLDER, embedded, 1)
    header = "--[[ gerado por airflowui/build.py -- nao editar a mao ]]\n"
    bundle = header + bundle

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        handle.write(bundle)

    data = open(OUT, "rb").read()
    modules = {"airflowui/main.lua": sha256(read(MAIN).encode("utf-8"))}
    for rel in TABS:
        modules["airflowui/" + rel] = sha256(read(os.path.join(ROOT, rel)).encode("utf-8"))

    manifest = {
        "artifact": "airflowui",
        "obfuscated": False,
        "bundle_size": len(data),
        "bundle_sha256": sha256(data),
        "tabs": len(TABS),
        "modules": modules,
    }
    with open(MAP, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2, sort_keys=True)
        handle.write("\n")

    # a fonte em claro, para os testes correrem exactamente os mesmos bytes
    with open(OUT + ".source.lua", "w", encoding="utf-8") as handle:
        handle.write(header)
        handle.write("return [====[\n")
        handle.write(bundle[len(header):])
        handle.write("]====]\n")

    print("bundle:  " + OUT)
    print("tamanho: %d bytes" % len(data))
    print("sha256:  " + manifest["bundle_sha256"])
    print("abas:    %d" % len(TABS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
