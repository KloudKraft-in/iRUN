# NET-D1-102 - Process model comparison

Fill every `<<FILL ...>>` cell with values you captured yourself (PowerShell: `Get-CimInstance Win32_Process`;
Ubuntu: `ps -eo pid,ppid,user,rss,cmd`). `lab check` rejects the file while any `<<FILL` remains.

## Windows track (IIS + ASP.NET Core Module v2)

| Mode | Process | PID | Parent PID | Memory (MB) | Who answered /whoami |
|------|---------|-----|------------|-------------|----------------------|
| In-Process      | w3wp.exe  | <<FILL>> | <<FILL>> | <<FILL>> | <<FILL: processName from /whoami>> |
| Out-of-Process  | w3wp.exe  | <<FILL>> | <<FILL>> | <<FILL>> | (proxy only) |
| Out-of-Process  | dotnet.exe| <<FILL>> | <<FILL: must equal the w3wp PID above>> | <<FILL>> | <<FILL: processName from /whoami>> |

## Ubuntu track (nginx reverse proxy + Kestrel)

| Mode | Process | PID | Parent PID | Memory (MB) | Who answered /whoami |
|------|---------|-----|------------|-------------|----------------------|
| Kestrel only (direct, port 5001) | dotnet | <<FILL>> | <<FILL>> | <<FILL>> | <<FILL>> |
| nginx -> Kestrel | nginx (master) | <<FILL>> | <<FILL>> | <<FILL>> | (proxy only) |
| nginx -> Kestrel | dotnet | <<FILL>> | <<FILL>> | <<FILL>> | <<FILL>> |

(Fill in only the table for the track you are on; delete the other table.)

## In one or two sentences: what is the practical difference between the two models?

<<FILL>>
