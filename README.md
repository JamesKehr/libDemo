# libDemo
A PowerShell module used to demo scripts and commands. PowerShell syntax is highlighted to showcase the components of PowerShell.

![image](https://github.com/user-attachments/assets/e719b2e8-b229-4bf8-8598-39b07b3274d4)

# The Goal

Demoing or teaching code is difficult. A PowerShell demo traditionally use the old PowerShell ISE, copy/paste and relying on PSReadLine to highlight syntax, or switching between something like VSCode to show the code and the Windows Terminal to run the code. Manually typing the code live are prone to typos and syntax errors, and a bit of memorization. All of which are fairly time consuming and take time away from teaching.

The libDemo module is designed to be a single file solution to the PowerShell demo conundrum. A single file module simplifies the use and portability of demo files.

libDemo does not fake type commands. I personally see this is a time consuming step that takes time away from teaching. I did add some pretty scroll animations though...

# Usage

See the [wiki](https://github.com/JamesKehr/libDemo/wiki).

## Using Start-DemoDemoDemo

The GitHub repro contains three files that are not part of the modeule:

- **template.ps1** - Think of this as a quick start guide to creating demos.
- **Start-DemoDemoDemo.ps1** - Contains a working example of all three supported demo types: Command, Segment, and File.
- **Start-MyFirstScript.ps1** - The file used by Start-DemoDemoDemo to demonstrate the File-type demo.

By downloading or cloning the repo you can run (after unblocking the files) ```.\Start-DemoDemoDemo.ps1`` to see a basic example of how libDemo looks and operates.

# NOTES

- The scripts need to be be unblocked if you download them from the GitHub webpage. This is not needed if the repo is cloned.

```powershell 
Get-ChildItem "<path to files>" | Unblock-File
```
- Here-strings currently to do not highlight correctly. This is a known limitation with the initial version of libDemo.
- Lines that are longer than the width of the console/terminal will currently cause scrolling issues.
- Please create an issue for any bugs or feature requests.
- Feel free to submit a PR if you add to or fix anything for libDemo.
