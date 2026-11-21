<div align="center">
  <img src="SkillVerse/logo.png" alt="Squared Studio" width="72" />
  <h1>Squared Studio</h1>
  <p><strong>Open-Source Engineering Learning Platform — Learn. Build. Verify.</strong></p>
  <p>
    <a href="https://squared-studio.cc">Website</a> &middot;
    <a href="https://squared-studio.cc/SkillVerse/">SkillVerse</a> &middot;
    <a href="https://squared-studio.cc/about.html">About</a> &middot;
    <a href="https://squared-studio.cc/people.html">People</a> &middot;
    <a href="https://squared-studio.cc/contact.html">Contact</a> &middot;
    <a href="LICENSE">MIT License</a>
  </p>
</div>

---

## Overview

This repository ([`squared-studio/.github`](https://github.com/squared-studio/.github)) serves two purposes for the [Squared Studio](https://github.com/squared-studio) open-source organization:

1. **Website & Learning Hub (`https://squared-studio.cc`)** — Hosts the static Squared Studio website (`index.html`, `about.html`, `people.html`, `contact.html`, `404.html`, contributor profiles under [`people/`](people/), shared [`common.js`](common.js) & [`styles.css`](styles.css), and [`sitemap.xml`](sitemap.xml)) alongside the complete [**SkillVerse**](SkillVerse/README.md) engineering curriculum (`SkillVerse/`), served via GitHub Pages ([`CNAME`](CNAME)).
2. **GitHub Organization Configuration (`.github`)** — Houses organization-level GitHub metadata, including the public organization profile README at [`profile/README.md`](profile/README.md).

---

## Key Features

- **Zero-Framework Static Architecture** — Built with vanilla HTML, CSS, and JavaScript with no build step, bundler, or runtime backend required.
- **SkillVerse Markdown Reader ([`SkillVerse/index.html`](SkillVerse/index.html))** — A single-page knowledge-base reader featuring:
  - GitHub Flavored Markdown rendering via `marked`
  - Syntax highlighting via `highlight.js` with Verilog / SystemVerilog support
  - Mathematical equation rendering via `KaTeX`
  - Instant search across all courses, chapters, and section headings (`Ctrl K`)
  - Toggleable **Dark**, **Light**, and **Reading** color modes
- **Automated Curriculum Publishing ([`SkillVerse/update.sh`](SkillVerse/update.sh))** — Sequentially renumbers chapters, builds course index files, updates copyright footers, regenerates `SkillVerse/index.html`, and rebuilds `sitemap.xml` from [`SkillVerse/config.json`](SkillVerse/config.json).

---

## SkillVerse Curriculum

**25 active courses &middot; 233 chapters** organized across four core engineering tracks.

### RTL Design & Verification (9 courses · 99 chapters)

| Course | Chapters | Read Online | Overview |
| :--- | :---: | :---: | :--- |
| [RTL Design](SkillVerse/RTL_Design.md) | 10 | [Open](https://squared-studio.cc/SkillVerse/#RTL_Design.md) | Synchronous digital design, microarchitecture, FSMs, pipelining, CDC, and synthesis. |
| [SystemVerilog](SkillVerse/SystemVerilog.md) | 23 | [Open](https://squared-studio.cc/SkillVerse/#SystemVerilog.md) | Hardware modeling, interfaces, OOP testbenches, randomization, and assertions. |
| [RTL Design Verification](SkillVerse/RTL_Design_Verification.md) | 8 | [Open](https://squared-studio.cc/SkillVerse/#RTL_Design_Verification.md) | Simulation methodologies, layered testbenches, coverage, and verification closure. |
| [UVM](SkillVerse/uvm.md) | 6 | [Open](https://squared-studio.cc/SkillVerse/#uvm.md) | Universal Verification Methodology phases, agents, sequences, scoreboards, and RAL. |
| [Formal Verification](SkillVerse/Formal_Verification.md) | 8 | [Open](https://squared-studio.cc/SkillVerse/#Formal_Verification.md) | SVA properties, bounded model checking, induction, and formal sign-off. |
| [Design for Testability (DFT)](SkillVerse/DFT.md) | 8 | [Open](https://squared-studio.cc/SkillVerse/#DFT.md) | Scan chains, ATPG, BIST, boundary scan, and silicon test readiness. |
| [UPF / CPF Low-Power Design](SkillVerse/UPF_CPF.md) | 12 | [Open](https://squared-studio.cc/SkillVerse/#UPF_CPF.md) | IEEE 1801 UPF and Si2 CPF power domains, isolation, retention, level shifters, PSTs, and power-aware verification. |
| [CDC / RDC (Clock & Reset Crossings)](SkillVerse/CDC_RDC.md) | 12 | [Open](https://squared-studio.cc/SkillVerse/#CDC_RDC.md) | Metastability, MTBF, 2-FF and pulse synchronizers, MCP/DMUX, Gray-code async FIFOs, reset trees, RDC isolation, and static/formal sign-off. |
| [GLS (Gate-Level Simulation)](SkillVerse/GLS.md) | 12 | [Open](https://squared-studio.cc/SkillVerse/#GLS.md) | Standard-cell models, SDF back-annotation, zero-delay vs timing GLS, pulse filtering, X-propagation, timing debug, PG UPF, DFT/MBIST, and sign-off. |

### Bus & Interconnect Protocols (6 courses · 57 chapters)

| Course | Chapters | Read Online | Overview |
| :--- | :---: | :---: | :--- |
| [AXI Protocol](SkillVerse/AXI_Protocol.md) | 10 | [Open](https://squared-studio.cc/SkillVerse/#AXI_Protocol.md) | AMBA AXI4 burst transactions, channel handshakes, ordering, and VIP design. |
| [ACE Protocol](SkillVerse/ACE_Protocol.md) | 10 | [Open](https://squared-studio.cc/SkillVerse/#ACE_Protocol.md) | AXI Coherency Extensions, snoop channels, cache states, and barrier transactions. |
| [CHI Protocol](SkillVerse/CHI_Protocol.md) | 10 | [Open](https://squared-studio.cc/SkillVerse/#CHI_Protocol.md) | Coherent Hub Interface packetized fabric, RN/HN/SN nodes, and flit flows. |
| [APB Protocol](SkillVerse/APB_Protocol.md) | 7 | [Open](https://squared-studio.cc/SkillVerse/#APB_Protocol.md) | Advanced Peripheral Bus register access, transfers, and low-power interfaces. |
| [OBI Protocol](SkillVerse/OBI.md) | 10 | [Open](https://squared-studio.cc/SkillVerse/#OBI.md) | Open Bus Interface handshake protocol used in open-source RISC-V cores. |
| [UART Protocol](SkillVerse/UART_Protocol.md) | 10 | [Open](https://squared-studio.cc/SkillVerse/#UART_Protocol.md) | Asynchronous serial framing, baud generation, FIFO buffering, and verification. |

### Architecture, Silicon & EDA (1 course · 9 chapters)

| Course | Chapters | Read Online | Overview |
| :--- | :---: | :---: | :--- |
| [Electronics](SkillVerse/Electronics.md) | 9 | [Open](https://squared-studio.cc/SkillVerse/#Electronics.md) | Semiconductor physics, diodes, MOSFETs, BJTs, op-amps, and logic families. |

### Software & Engineering Tooling (9 courses · 68 chapters)

| Course | Chapters | Read Online | Overview |
| :--- | :---: | :---: | :--- |
| [RISC-V Assembly](SkillVerse/RISC_V_Assembly.md) | 7 | [Open](https://squared-studio.cc/SkillVerse/#RISC_V_Assembly.md) | RV32I/RV64I instruction formats, calling conventions, CSRs, and bare-metal code. |
| [Vivado](SkillVerse/Vivado.md) | 9 | [Open](https://squared-studio.cc/SkillVerse/#Vivado.md) | AMD/Xilinx FPGA synthesis, XDC constraints, simulation, ILA debug, and bitstreams. |
| [C Programming](SkillVerse/C.md) | 7 | [Open](https://squared-studio.cc/SkillVerse/#C.md) | Pointers, memory layout, structs, bitwise operations, and systems-level C. |
| [Python](SkillVerse/Python.md) | 7 | [Open](https://squared-studio.cc/SkillVerse/#Python.md) | Scripting, automation, verification helpers, data structures, and tooling workflows. |
| [Bash](SkillVerse/bash.md) | 9 | [Open](https://squared-studio.cc/SkillVerse/#bash.md) | Shell scripting, text pipelines, job control, and regression automation. |
| [Unix Terminal](SkillVerse/Unix_Terminal.md) | 10 | [Open](https://squared-studio.cc/SkillVerse/#Unix_Terminal.md) | Filesystem navigation, permissions, processes, SSH, and CLI productivity. |
| [Git](SkillVerse/git.md) | 7 | [Open](https://squared-studio.cc/SkillVerse/#git.md) | Branching, rebasing, conflict resolution, bisect, and collaborative workflows. |
| [Makefile](SkillVerse/Makefile.md) | 7 | [Open](https://squared-studio.cc/SkillVerse/#Makefile.md) | Dependency graphs, pattern rules, variables, and simulation build automation. |
| [VIM](SkillVerse/VIM.md) | 5 | [Open](https://squared-studio.cc/SkillVerse/#VIM.md) | Modal editing, motions, visual block macros, buffers, and HDL productivity. |

### In Development / Roadmap

Draft courses use the `___` directory prefix (configured via `draft_prefix` in [`SkillVerse/config.json`](SkillVerse/config.json)) so their plans remain tracked in-repo without appearing in the active catalog until ready:

- [Circuits](SkillVerse/___Circuits/plan.md) (`___Circuits`) — Foundational analog and digital circuit analysis, RLC networks, amplifiers, and switching circuits.
- [DDR Protocol](SkillVerse/___DDR_Protocol/plan.md) (`___DDR_Protocol`) — JEDEC DDR4/DDR5 timing fundamentals, controller scheduling, DFI interfaces, and PHY initialization.
- [I2C Protocol](SkillVerse/___I2C_Protocol/plan.md) (`___I2C_Protocol`) — Two-wire serial bus arbitration, clock stretching, multi-master addressing, and controller RTL.
- [PCIe Protocol](SkillVerse/___PCIe_Protocol/plan.md) (`___PCIe_Protocol`) — Physical layer signaling, TLP/DLLP transaction routing, LTSSM link training, and Gen5/Gen6 verification.
- [SPI Protocol](SkillVerse/___SPI_Protocol/plan.md) (`___SPI_Protocol`) — Serial Peripheral Interface clocking modes, full-duplex framing, QSPI extensions, and controller design.
- [USB Protocol](SkillVerse/___USB_Protocol/plan.md) (`___USB_Protocol`) — Universal Serial Bus packet framing, enumeration, endpoints, and high-speed host/device architecture.

Additional planned hardware engineering and verification topics (such as Linting, LEC, X-Propagation, RAL, SVA, Coverage Closure, PSS, SDC, STA, and Logic Synthesis) are tracked in [`TODO`](TODO).

---

## Repository Structure

```text
.
├── index.html          # Main landing page
├── about.html          # Mission and engineering values
├── people.html         # Team and contributor directory
├── contact.html        # Community channels and FAQ
├── 404.html            # Custom GitHub Pages 404 page
├── common.js           # Shared navigation bar and footer injector
├── styles.css          # Shared site theme and responsive styles
├── CNAME               # Custom domain configuration (squared-studio.cc)
├── sitemap.xml         # Auto-generated sitemap for root pages & SkillVerse
├── serve-local.sh      # Local Python HTTP server script
├── TODO                # Planned topics and curriculum backlog
├── LICENSE             # MIT License
├── people/             # Individual contributor profile pages & avatars
├── profile/            # GitHub organization profile README (profile/README.md)
└── SkillVerse/         # Curriculum courses, chapters, diagrams, config & SPA
    ├── index.html      # Single-page Markdown reader (auto-generated)
    ├── config.json     # Site metadata, categories, and course catalog
    ├── update.sh       # Curriculum indexing & HTML/sitemap generator script
    ├── README.md       # Generated SkillVerse course index
    ├── logo.png        # Brand icon / favicon
    ├── <Course>.md     # Generated per-course chapter & section indexes
    ├── <Course>/       # Chapter files (chapter_00001.md ...) & diagrams
    └── ___<Draft>/     # Draft / planned course directories (excluded from catalog)
```

---

## Local Development

The SkillVerse reader ([`SkillVerse/index.html`](SkillVerse/index.html)) loads course and chapter `.md` files dynamically using `fetch()`, so opening HTML files directly via `file://` will be blocked by browser CORS policies. Serve the repository over local HTTP instead.

### Clone the Repository

```bash
git clone https://github.com/squared-studio/.github.git
cd .github
```

### Start a Local Server

Using the included helper script (Linux / macOS / Git Bash, requires Python 3):

```bash
./serve-local.sh        # Serves on http://localhost:8000
./serve-local.sh 8080   # Optional custom port
```

Or run Python's built-in HTTP server directly (works on Windows PowerShell as well):

```bash
# Linux / macOS
python3 -m http.server 8000

# Windows (PowerShell / Command Prompt)
py -3 -m http.server 8000
```

Then open [http://localhost:8000](http://localhost:8000) (or [http://localhost:8000/SkillVerse/](http://localhost:8000/SkillVerse/)) in your browser.

---

## Authoring & Updating SkillVerse

1. **Add or edit chapters** inside `SkillVerse/<Course>/` as `chapter_XXXXX.md` (with a top-level `# Title` heading and `## Section` headings used for indexing and search).
2. **Configure course metadata** in [`SkillVerse/config.json`](SkillVerse/config.json) (course title, description, and category mapping).
3. **Draft upcoming courses** under a `___`-prefixed directory (for example, `SkillVerse/___New_Course/`) until they are ready to publish.
4. **Regenerate indexes and site pages** by running [`SkillVerse/update.sh`](SkillVerse/update.sh):

```bash
bash SkillVerse/update.sh
```

> **Prerequisites:** `SkillVerse/update.sh` requires **Bash** and one of `jq`, `python`, `python3`, or `node` on your `PATH` to parse [`SkillVerse/config.json`](SkillVerse/config.json).

Running `SkillVerse/update.sh` automatically:
- Renumbers all `chapter_XXXXX.md` files sequentially within each course directory.
- Rebuilds every per-course `SkillVerse/<Course>.md` table of contents and [`SkillVerse/README.md`](SkillVerse/README.md).
- Adds or refreshes `##### Copyright (c) <year> squared-studio` footers across Markdown files.
- Regenerates [`SkillVerse/index.html`](SkillVerse/index.html) with updated metadata, categories, and `COURSE_CATALOG`.
- Rebuilds the root [`sitemap.xml`](sitemap.xml) (without modifying this root `README.md`).

---

## Contributing

Contributions — from typo fixes and diagram improvements to new chapters and courses — are welcome:

1. **Fork** this repository and create a dedicated feature or fix branch.
2. **Edit or add content** in the website pages or under `SkillVerse/`.
3. **Run `bash SkillVerse/update.sh`** whenever you add, rename, or restructure SkillVerse chapters or update `SkillVerse/config.json`.
4. **Preview locally** over HTTP (`./serve-local.sh` or `py -3 -m http.server 8000`) to verify formatting, diagrams, math rendering, and links.
5. **Open a Pull Request** describing your changes.

- **Organization:** [github.com/squared-studio](https://github.com/squared-studio)
- **Issues & Suggestions:** [github.com/squared-studio/.github/issues](https://github.com/squared-studio/.github/issues)
- **Contact & FAQ:** [squared-studio.cc/contact.html](https://squared-studio.cc/contact.html)

---

## Core Team

| Contributor | Role | GitHub |
| :--- | :--- | :--- |
| **Foez Ahmed** | Founder & Maintainer | [@foez-ahmed](https://github.com/foez-ahmed) |
| **Mohiuddin Reyad** | Verification Engineer | [@Reyad07](https://github.com/Reyad07) |
| **Samia Alam** | Hobbyist | [@samia-alam](https://github.com/samia-alam) |

See [squared-studio.cc/people.html](https://squared-studio.cc/people.html) for full contributor profiles.

---

## License

All content and code in this repository is open-source under the [MIT License](LICENSE) — `Copyright (c) 2026 squared-studio`.
