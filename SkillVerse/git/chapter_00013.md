# Containerized Jobs, Self-Hosted Runners, and Hardware/RTL CI Pipelines

## Learning Goals

After completing this chapter, you should be able to:

- Run reproducible CI jobs inside custom Docker toolchains (`container:`) alongside health-checked sidecar databases (`services:`).
- Architect secure, scalable self-hosted runner infrastructure—including ephemeral JIT runners and Kubernetes Actions Runner Controller (ARC)—and understand when to use them over GitHub-hosted VMs.
- Build a complete, automated Hardware / RTL & Verification CI pipeline covering SystemVerilog linting, Verilator/`cocotb` regression simulation, Yosys synthesis checks, failure waveform artifact uploads, and `$GITHUB_STEP_SUMMARY` scoreboards.
- Debug failing workflows locally with `nektos/act` and remotely with `ACTIONS_STEP_DEBUG`.
- Prevent self-hosted workspace contamination, UID mismatch issues, and public-repo fork runner compromises.

---

## Running Jobs Inside Containers and Service Sidecars

While GitHub-hosted Ubuntu runners preinstall common software stacks, specialized builds—embedded cross-compilers, specific EDA simulator builds, or legacy toolchains—require deterministic environments. Using **`container:`** executes every step of a job inside a pinned Docker image, while **`services:`** launches networked sidecar containers (such as PostgreSQL or Redis) on a shared Docker bridge network.

![Containerized Jobs and Sidecar Service Containers](images/ch13_container_and_service_architecture.svg)

### Full Container + Service Sidecar Example

```yaml
jobs:
  integration-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    container:
      # Pin by digest for reproducible builds; falls back safely across runs
      image: python:3.12-slim
      env:
        DATABASE_URL: postgres://ci_user:ci_pass@postgres:5432/testdb
        REDIS_URL: redis://redis:6379/0
      # Optional credentials for private GHCR / Docker Hub images:
      # credentials:
      #   username: ${{ github.actor }}
      #   password: ${{ secrets.GITHUB_TOKEN }}

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: ci_user
          POSTGRES_PASSWORD: ci_pass
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - name: Run database-backed integration tests
        run: |
          pip install -r requirements.txt
          pytest tests/integration/
```

### Container Networking & Workspace Mapping Details
- **Hostnames Inside `container:`**: When the job uses `container:`, it shares the custom Docker bridge network with `services:`, so services are addressed directly by their YAML label (`postgres:5432`, `redis:6379`).
- **Hostnames Without `container:`**: If the job runs directly on the VM host (no `container:` block), add `ports: ["5432:5432"]` under `services.postgres` and connect via `localhost:5432`.
- **Workspace Mount**: GitHub automatically mounts the repository workspace at `/__w/<repo>/<repo>` inside the job container and sets `$GITHUB_WORKSPACE` accordingly, so relative paths work transparently.

---

## Self-Hosted Runners: Architecture, Security, and Scaling

Standard GitHub-hosted VMs are ideal for 90% of workloads, but hardware and specialized engineering teams frequently need **self-hosted runners**:

1. **Proprietary & Licensed EDA Toolchains**: Commercial simulators (VCS, Questa, Xcelium, Vivado, Quartus) require massive multi-gigabyte installations and access to internal FlexLM license servers inside a corporate VPC.
2. **High Compute / Memory Profiles**: Full-SoC gate-level or FPGA place-and-route builds often require 32–128 CPU cores and 128–512 GB RAM.
3. **Hardware-in-the-Loop (HIL) & GPU Testing**: Workflows flashing real FPGA boards over JTAG or running CUDA inference tests on physical GPUs.

![Ephemeral Self-Hosted Runners and Hardware/RTL CI Pipeline](images/ch13_self_hosted_and_rtl_ci_pipeline.svg)

### Label-Based Routing & Ephemeral Runners

```yaml
jobs:
  eda-regression:
    # Job waits until a runner matching ALL four labels is idle
    runs-on: [self-hosted, linux, x64, eda-64g]
```

> [!CAUTION]
> **Critical Security Rules for Self-Hosted Runners:**
> 1. **Never attach self-hosted runners to public repositories!** Anyone on the internet can open a Pull Request that runs malicious code directly inside your private network, steals FlexLM/cloud tokens, and pivots laterally.
> 2. **Always run ephemeral runners (`--ephemeral` or Kubernetes ARC).** Persistent self-hosted machines retain leftover `/tmp` files, cached credentials, and background processes from previous jobs. Configure runners with `./config.sh --ephemeral` or deploy **Actions Runner Controller (ARC)** on Kubernetes so every job spawns a pristine pod that self-destructs upon completion.

### Outbound-Only Network Security
Self-hosted runners **never** require inbound firewall ports opened to GitHub. The runner daemon polls GitHub over outbound **HTTPS (TCP 443)** via long-polling, receives an encrypted job payload, executes steps locally, and streams logs back over HTTPS.

---

## Building Hardware, RTL, and Verification CI Pipelines

Hardware teams treat RTL (`*.sv`, `*.v`), testbenches (`cocotb`, C++ Verilator harnesses, SVA properties), synthesis scripts, and FPGA constraint files (`*.xdc`, `*.sdc`) as software-grade artifacts. Every PR should pass **RTL Linting → Simulation Regression → Synthesis Sanity Check** automatically.

### Complete Open-Source RTL CI Workflow (`.github/workflows/rtl-ci.yml`)

```yaml
name: RTL & Verification CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
    paths:
      - "rtl/**"
      - "tb/**"
      - "constraints/**"
      - "Makefile"
      - ".github/workflows/rtl-ci.yml"

permissions:
  contents: read

concurrency:
  group: rtl-ci-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  rtl-lint:
    name: SystemVerilog Lint & Formatting
    runs-on: ubuntu-latest
    timeout-minutes: 10
    container:
      image: hdlc/sim:osflow
    steps:
      - uses: actions/checkout@v4

      - name: Run Verilator structural lint
        run: |
          set -euo pipefail
          verilator --lint-only -Wall -Werror-WIDTH -Werror-LATCH \
            -Irtl rtl/top_uart_apb.sv

      - name: Check formatting with Verible
        run: |
          verible-verilog-lint rtl/*.sv

  rtl-sim:
    name: Verilator & cocotb Regression
    needs: rtl-lint
    runs-on: ubuntu-latest
    timeout-minutes: 25
    container:
      image: hdlc/sim:osflow
    strategy:
      fail-fast: false
      matrix:
        test_suite: [apb_reg_smoke, uart_tx_rx, uart_fifo_stress, parity_error]
    steps:
      - uses: actions/checkout@v4

      - name: Run cocotb simulation (${{ matrix.test_suite }})
        id: sim
        env:
          TESTCASE: ${{ matrix.test_suite }}
          WAVES: "1"
        run: |
          set -euo pipefail
          mkdir -p build/logs build/waves
          make -C tb SIM=verilator TESTCASE="$TESTCASE" WAVES=1 \
            | tee "build/logs/${TESTCASE}.log"

      - name: Upload waveforms & simulation logs on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: rtl-debug-${{ matrix.test_suite }}-${{ github.run_attempt }}
          path: |
            build/logs/*.log
            build/waves/*.fst
            build/waves/*.vcd
          retention-days: 14

      - name: Append test result to Step Summary
        if: always()
        run: |
          echo "| \`${{ matrix.test_suite }}\` | \`${{ steps.sim.outcome }}\` | \`$GITHUB_SHA\` |" >> "$GITHUB_STEP_SUMMARY"

  yosys-synth:
    name: Synthesis & Resource Sanity Check
    needs: rtl-lint
    runs-on: ubuntu-latest
    timeout-minutes: 15
    container:
      image: hdlc/sim:osflow
    steps:
      - uses: actions/checkout@v4

      - name: Run Yosys synthesis check
        run: |
          set -euo pipefail
          yosys -p "read_verilog -sv rtl/top_uart_apb.sv; synth -top top_uart_apb; stat" \
            | tee synth_report.txt

      - name: Publish synthesis utilization summary
        if: always()
        run: |
          {
            echo "### Yosys Resource Utilization"
            echo '```text'
            tail -n 25 synth_report.txt || true
            echo '```'
          } >> "$GITHUB_STEP_SUMMARY"
```

### Why This RTL Pipeline Works Well
- **Strict Lint First (`rtl-lint`)**: Catching inferred latches (`-Werror-LATCH`), bit-width mismatches (`-Werror-WIDTH`), and syntax issues in 20 seconds prevents wasting 20 minutes of matrix simulation compute.
- **Matrix Regression by Suite**: Independent suites run in parallel with `fail-fast: false`, giving complete visibility across UART, APB, and FIFO scenarios.
- **Zero-Noise Waveform Uploads**: `.fst`/`.vcd` waveform dumps are large; uploading them strictly under `if: failure()` preserves full GTKWave/Surfer debug artifacts without bloating storage on passing builds.

---

## Local Workflow Testing and Debugging

Waiting 3 minutes for a push-and-pray edit cycle on `.github/workflows/*.yml` kills productivity. Use local and diagnostic debugging tools instead:

### 1. Local Execution with `nektos/act`
`act` reads `.github/workflows/` and runs jobs locally inside Docker containers approximating GitHub runners:

```bash
# List jobs without running them
act -l

# Execute the pull_request workflow locally
act pull_request

# Run a single named job with a custom runner image
act -j rtl-lint -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

### 2. Diagnostic Step & Runner Logging
If a workflow fails only in GitHub's hosted environment, re-run the job with **Enable debug logging** checked in the GitHub UI—or define these repository secrets/variables temporarily:
- `ACTIONS_STEP_DEBUG = true`: Emits verbose API calls, expression evaluations, and action internals.
- `ACTIONS_RUNNER_DEBUG = true`: Emits runner agent diagnostics, container mount commands, and network health logs.

---

## Best Practices and Common Pitfalls

- **Clean Workspaces on Persistent Self-Hosted Runners**: If you cannot deploy ephemeral pods yet, always run `git clean -ffdx` or isolate workspaces inside `container:` so stale synthesis netlists or object files from yesterday's PR cannot corrupt today's build.
- **Watch Container UID / File Ownership**: If a job container runs as `root` while the runner host agent runs as `runner`, root-owned files written into `$GITHUB_WORKSPACE` may cause cleanup permission errors on persistent self-hosted runners. Configure matching UIDs or run ephemeral VMs/pods.
- **Pin Container Images by Digest**: Tag names like `hdlc/sim:latest` can shift overnight and break deterministic hardware regressions. Pin exact `@sha256:...` digests in production CI.
- **Ensure Sidecar Health Checks**: Without `--health-cmd` on `services:`, Step 1 often starts before PostgreSQL or Redis finishes initializing, causing intermittent connection-refused flakes.

---

## Practical Exercises

1. Write a workflow job running inside `container: python:3.12-slim` paired with a `postgres:16` service container configured with `--health-cmd pg_isready`, and verify your test step connects to `postgres:5432`.
2. Build a Verilator or Icarus Verilog lint + simulation workflow (even for a simple counter or UART RTL module) that fails on inferred latches (`-Werror-LATCH`) and uploads `.vcd`/`.fst` waveforms only when `failure()` occurs.
3. Install `nektos/act` locally (if Docker is available) and run `act -l` on a repository containing `.github/workflows/ci.yml` to inspect the resolved job graph before pushing.
4. Draft a short architecture checklist detailing how you would secure an on-prem self-hosted EDA runner cluster (network egress, `--ephemeral` pods, private-repo restriction, and FlexLM access).

##### Copyright (c) 2026 squared-studio
