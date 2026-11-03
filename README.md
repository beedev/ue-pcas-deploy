# UE PCAS demo: install

This installs HTC's demonstration of PCAS, the Policy and Claim Administration System built for United Educators, on a Mac or a Linux server with Docker. The programs are public images on ghcr.io. This repository holds only what is needed to run them: one install script, the file that starts them (`docker-compose.yml`) and the settings they read (`config/`). There is no source code here.

Everything in the demo is invented: the institutions, the people and the amounts. Every password below is a test value that works only inside this demo.

## On your own computer (Mac or Linux)

You need Docker (on a Mac, [Docker Desktop](https://www.docker.com/products/docker-desktop/)) running, about 4 GB of memory for it, and 3 GB of disk.

```bash
curl -fsSLo install.sh https://raw.githubusercontent.com/beedev/ue-pcas-deploy/main/install.sh
bash install.sh
```

It installs into `~/ue-pcas`, starts the demo and opens **http://localhost:8080**. Use exactly that address, not `127.0.0.1`: the sign-in checks it. The first run downloads about 1.5 GB and takes a few minutes.

## On a server

People reach a server through its HTTPS web proxy (nginx, for example), so first decide the address they will open, for example `https://idea.example.com/ue-pcas`. HTTPS is required: the sign-in cookie is sent only over HTTPS. Then, on the server:

```bash
curl -fsSLo install.sh https://raw.githubusercontent.com/beedev/ue-pcas-deploy/main/install.sh
bash install.sh https://idea.example.com/ue-pcas
```

From that one address the script works out every setting the stack needs, and the sign-in service gets the address next to it (`https://idea.example.com/ue-pcas-keycloak`). The stack listens only on the server itself (`127.0.0.1`). At the end the script prints the lines to add to the server's nginx, filled in with your host and ports; it does not edit nginx itself.

## Upgrade, stop, start over

- **Upgrade:** run `bash install.sh` again (with the same address on a server). It downloads the latest settings and images and keeps the demo data.
- **Stop:** `cd ~/ue-pcas && docker compose down`. **Wipe the demo data too:** `docker compose down -v`.
- **Another address:** run it with the new address. The sign-in service reads its addresses only on a fresh start, so this resets the demo data.
- **A port is taken:** the script says which one. Choose another, for example `PCAS_PORT=9080 bash install.sh http://localhost:9080`.

## Sign in

Every demo user has the password `Pcas!2026`.

| User | Role in the story |
|---|---|
| `demo.all` | Holds every role, to present the whole flow without switching users |
| `r.alvarez` | Policy service representative |
| `j.ferro` | Referral underwriter |
| `m.delacroix` | Finance analyst |
| `r.chen` | Claims adjuster |
| `j.kim` | Claims supervisor |
| `k.osei` | Configuration administrator |
| `n.adeyemi` | Second configuration administrator |
| `t.okonkwo` | System administrator |
| `e.kennedy` | Auditor |

Press **Flow** in the top bar for the guided story, from the bind in the Underwriting Workbench to the end-to-end trace. **Reset**, at the bottom of it, puts every record back to the start, for everyone using that installation. The simulated Workbench is at `/workbench` on the PCAS address.

## If something goes wrong

- **A part does not become healthy.** In `~/ue-pcas`, `docker compose ps` shows which, and `docker compose logs <name>` shows why. The sign-in service is the slowest; give it two minutes the first time.
- **The sign-in page loops.** You are on an address other than the one you installed with, or on plain `http://` on a server.

These files are written from HTC's private repository by `scripts/publish-deploy.sh`; changes made here are overwritten.
