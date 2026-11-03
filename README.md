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

## Settings: the .env file

All settings live in one file, `~/ue-pcas/.env`. You usually change nothing: the defaults run the demo as it is.

**Written by the script. Don't edit these by hand.** Each run of `install.sh` writes these lines from the address you give it, and overwrites what is there:

| Setting | On your own computer | On a server at `https://idea.example.com/ue-pcas` |
|---|---|---|
| `PCAS_URL` | `http://localhost:8080` | `https://idea.example.com/ue-pcas` |
| `PCAS_ORIGIN` | `http://localhost:8080` | `https://idea.example.com` |
| `PCAS_BASE_PATH` | empty | `/ue-pcas` |
| `KEYCLOAK_URL` | `http://localhost:8180` | `https://idea.example.com/ue-pcas-keycloak` |
| `KEYCLOAK_PATH` | empty | `/ue-pcas-keycloak` |
| `PCAS_PORT`, `KEYCLOAK_PORT`, `API_PORT`, `MOCKS_PORT`, `DB_PORT` | `8080`, `8180`, `8000`, `8090`, `5433` | the same |

To change the address or a port, run the script again rather than editing the file, for example `bash install.sh https://new.example.com/pcas` or `PCAS_PORT=9080 bash install.sh http://localhost:9080`. The five address settings have to agree with each other, and the script keeps them in step.

**Yours to add.** Add these lines yourself. The script keeps every line it does not write.

| To do this | Add to `.env` | When it takes effect |
|---|---|---|
| Use a live AI model instead of the recorded answers | `AI__PROVIDER=OpenAI`<br>`OPENAI_API_KEY=<your key>`<br>`OPENAI_MODEL=gpt-4.1` | After `docker compose up -d` |
| Name the AI provider on the AI governance page | `AI__CONTROLS__PROVIDER=OpenAI`<br>`AI__CONTROLS__DATAHANDLING=The text of a notice is sent to OpenAI to be read.` | After `docker compose up -d` |
| Change the sign-in admin console's password (do this on a server, where the console is reachable at `<sign-in address>/admin`) | `KEYCLOAK_ADMIN_PASSWORD=<a password of your own>` | Only on a fresh start: `docker compose down -v`, then `bash install.sh <same address>`. This resets the demo data |

Without the AI lines, the demo answers every AI call from recorded replies. That costs nothing and gives the same results every time, which is how HTC verifies it. With a live model, each call costs money, and the monthly caps on the AI governance page limit the spend. Keep the key only in `.env`. It never leaves that file, and the app never shows it.

**Applying a change.** In `~/ue-pcas`, run `docker compose up -d`. It restarts only the parts whose settings changed and keeps the demo data.

`.env.example` in this repository lists every setting the stack reads, with a note on each. Leave the rest alone: the database and client passwords there are the demo's test values, and the sign-in service is set up to match them.

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
