# TEL-D2-201 Runbook – VM setup \+ Dynatrace walkthrough

## A. Dynatrace account

1. Sign up at [https\://www\.dynatrace.com/signup/](https://www.dynatrace.com/signup/) (15-day free trial, no card). Use a training alias email.  
2. Note your tenant URL: `https://<id>.live.dynatrace.com` (or `.apps.dynatrace.com`).

## B. VM (Ubuntu 22.04/24.04, ≥ 4 GB RAM, 2 vCPU)

```sh
# copy setup_shopnow.sh + shopnow_ctl.sh to the VM (scp, or paste each file with: cat > file <<'EOF' ... EOF), then:
sudo bash setup_shopnow.sh        # hostname, JDK, build, services
```

Install OneAgent **before starting the apps** (so Java gets auto-instrumented): Dynatrace → **Deploy OneAgent → Linux** → create a PaaS/installer token → copy the 2 commands it shows, e.g.:

```sh
wget -O Dynatrace-OneAgent.sh "https://<tenant>/api/v1/deployment/installer/agent/unix/default/latest?arch=x86" --header="Authorization: Api-Token <TOKEN>"
sudo /bin/sh Dynatrace-OneAgent.sh --set-monitoring-mode=fullstack --set-app-log-content-access=true
```

Then:

```sh
sudo bash shopnow_ctl.sh start     # starts services + 2 req/s traffic
sudo bash shopnow_ctl.sh status    # test call should return "succeeded"
```

&nbsp;

Wait **\~15 min** of healthy traffic so Dynatrace learns the services.

## C. Make Davis open the problem fast (Dynatrace UI)

Services → **PaymentController** (Dynatrace names the service after the Java controller; its process group is PaymentService) → ⋮ → **Settings → Analyze and alert → Alerts → Services** → Failure rate: *Use fixed thresholds*, alert if \> **10 %**, sensitivity **High**. Save. (Optional: Settings → Server-side service monitoring → Service naming rules, if the service shows as something other than "PaymentService".)

Then on the VM:

```sh
sudo bash shopnow_ctl.sh inject 60
```

Within \~5–10 min a problem appears: **"Failure rate increase" on PaymentService**.

> ⚠ Dynatrace generates problem IDs itself, so yours will be `P-2xxxxxx`, not literally `P-24101`. Record the real ID and note "maps to P-24101 in the scenario".

## D. Vendor-neutral mapping (step 7\)

| Dynatrace term | What it is | OpenTelemetry / neutral equivalent |
| :---- | :---- | :---- |
| OneAgent | Single auto-instrumenting agent per host (code, process, host, logs) | OTel SDK/auto-instrumentation \+ OTel Collector (agent mode) |
| PurePath | End-to-end distributed trace with code-level method detail | Trace (made of Spans) |
| PurePath node / method | One call within the trace | Span (method-level ≈ child span / profiling data) |
| Smartscape | Real-time auto-discovered dependency topology | Service map / dependency graph (built from resource attrs \+ spans) |
| Smartscape tiers (Application, Service, Process Group, Host) | Vertical stack layers | `service.name`, `process.*`, `host.*` resource attributes |
| Davis AI | Causation engine that correlates events into one problem and finds root cause | AIOps / RCA engine (not part of OTel; e.g. alert correlation) |
| Problem Card | One correlated incident with impact \+ root cause | Incident / alert group |
| Request Attribute | Captured request parameter for filtering | Span attribute / tag |
| Process Group | Set of identical processes | Service instance group (`service.name` \+ `service.instance.id`) |
| Management Zone / Tags | Entity scoping | Resource attributes / labels |

&nbsp;

## E. Gotchas

- Install OneAgent **before** starting the Java services, or restart them afterwards.  
- Your tenant may already contain unrelated demo services (`checkout`, `frontend`, `payment`…) — use the `*Controller` ones.  
- Ignore any older closed problem (e.g. on `frontend`); open the **Active** one on PaymentController.