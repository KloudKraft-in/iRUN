# Middleware and API Integration Training Suite

A production-grade, hands-on training repository covering **Middleware Fundamentals, Web Servers, API Gateways, Messaging Systems, and Security Troubleshooting**.

---

## Operating System Support: Ubuntu (Linux) & Windows

Every component in this repository provides **native, dual-platform support**:
- **Ubuntu / Linux**: Shell scripts (`.sh`) using Bash, `curl`, `apt`, `openssl`, `ss`, `grep`.
- **Windows**: PowerShell scripts (`.ps1`) and batch launchers (`.bat`) using `python`, `netstat`, `Invoke-WebRequest`.

---

## 1. Initial Machine Setup & Readiness Verification

Run the host setup script once before starting scenarios:

### On Ubuntu (Linux / WSL2):
```bash
# 1. Install required packages (curl, OpenSSL, Python 3, net-tools)
sudo bash setup_scripts/ubuntu/install_dependencies_ubuntu.sh

# 2. Check environment readiness (exits with code 0 if ready)
bash setup_scripts/ubuntu/validate_environment_ubuntu.sh
```

### On Windows PowerShell:
```powershell
# 1. Check / install dependencies
.\setup_scripts\windows\install_dependencies_windows.ps1

# 2. Check environment readiness
.\setup_scripts\windows\validate_environment_windows.ps1
```

---

## 2. Repository Structure

```
middleware_and_apiintegration/
├── setup_scripts/                             <-- Host environment installers & validators
│   ├── ubuntu/                                <-- install & validate for Ubuntu
│   └── windows/                               <-- install & validate for Windows (.ps1 & .bat)
│
├── day1/                                      <-- Module 1: Web Servers & API Gateways
│   ├── participant_guide.md                   <-- Layman guided manual (symptoms & clues)
│   ├── instructor_solution_guide.md           <-- Mentor root-cause analysis & grading rubric
│   ├── step_by_step_execution_guide/          <-- Step-by-step commands (Ubuntu & Windows)
│   ├── s1/                                    <-- Scenario 1: Tomcat Port Collision
│   ├── s2/                                    <-- Scenario 2: Nginx 502 Upstream Repair
│   └── s3/                                    <-- Scenario 3: Kong API Gateway Routing & Security
│
└── day2/                                      <-- Module 2: Messaging, Security & Multi-Hop Timeouts
    ├── participant_guide.md                   <-- Layman guided manual
    ├── instructor_solution_guide.md           <-- Mentor root-cause analysis & grading rubric
    ├── step_by_step_execution_guide/          <-- Step-by-step commands (Ubuntu & Windows)
    ├── s1/                                    <-- Scenario 1: RabbitMQ DLQ Recovery
    ├── s2/                                    <-- Scenario 2: JWT Audience & SSL Certificate Expiry
    └── s3/                                    <-- Scenario 3: Distributed Multi-Hop Timeout Chain
```

---

## 3. The 3-Phase Execution Flow in Every Scenario

In every scenario folder (`s1`, `s2`, `s3`), you will find:

| Phase | Purpose | Ubuntu Command | Windows PowerShell Command |
|:---|:---|:---|:---|
| **Phase 1** | **Generate / Reproduce Error** | `bash starter/setup_scenario.sh`<br>`bash validation_script.sh` *(FAILS)* | `.\starter\setup_scenario.ps1`<br>`.\validation_script.ps1` *(FAILS)* |
| **Phase 2** | **Apply Solution** | `bash solution/solution_fix.sh` | `.\solution\solution_fix.ps1` |
| **Phase 3** | **Verify Resolution** | `bash validation_script.sh` *(PASSES)* | `.\validation_script.ps1` *(PASSES)* |

---

## 4. Documentation References

* **Step-by-Step Execution**:
  * [Day 1 Execution Walkthrough](file:///c:/Users/HP/Downloads/middleware/middleware_and_apiintegration/day1/step_by_step_execution_guide/step_by_step_guide.md)
  * [Day 2 Execution Walkthrough](file:///c:/Users/HP/Downloads/middleware/middleware_and_apiintegration/day2/step_by_step_execution_guide/step_by_step_guide.md)
* **Participant Guides (Layman Problem-Solving Manual)**:
  * [Day 1 Participant Guide](file:///c:/Users/HP/Downloads/middleware/middleware_and_apiintegration/day1/participant_guide.md)
  * [Day 2 Participant Guide](file:///c:/Users/HP/Downloads/middleware/middleware_and_apiintegration/day2/participant_guide.md)
* **Instructor Solution Guides (Mentor Reference)**:
  * [Day 1 Instructor Guide](file:///c:/Users/HP/Downloads/middleware/middleware_and_apiintegration/day1/instructor_solution_guide.md)
  * [Day 2 Instructor Guide](file:///c:/Users/HP/Downloads/middleware/middleware_and_apiintegration/day2/instructor_solution_guide.md)

