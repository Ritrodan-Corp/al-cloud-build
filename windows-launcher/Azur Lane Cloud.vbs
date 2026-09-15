Option Explicit

Dim shell, fso, base, command
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

base = fso.GetParentFolderName(WScript.ScriptFullName)
command = "cmd.exe /d /c """ & base & "\azl-cloud-launch.cmd"""

' Run the launcher invisibly. On failure, the cmd script opens its log in Notepad.
shell.Run command, 0, False
