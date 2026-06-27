## Rider + mise dotnet
Rider's MSBuild auto-detection is unreliable with mise-managed dotnet 
installs (confirmed bug, also hit by others — RIDER-139472). After 
installing/upgrading dotnet via mise, ALWAYS manually set:

Settings → Build, Execution, Deployment → Toolset and Build 
→ .NET CLI executable path: ~/.local/share/mise/dotnet-root/dotnet

MSBuild version auto-resolves correctly once that's set explicitly. 
Do not rely on Rider auto-detecting this on first project open — 
it can cache a broken/empty state that persists across IDE restarts 
and even reinstalls, and won't self-correct even if the underlying 
SDK install is fine.