; console position .ini
; need save dialogue for reload??
; want some way to "scroll presets"
; better filtering for 'english'
; search by number or label

#NoEnv
#SingleInstance force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

StringCaseSense, Off
FileEncoding, UTF-8

ctrDel:=chr(127)
ctrS:=chr(19)
ctrH:=chr(8)
ctrA:=chr(1)
ctrU:=chr(21)
ctrZ:=chr(26)
ctrV:=chr(22)

if !FileExist("recliner.ini")
	FileAppend,
	( LTrim
		;Hotkey=#s
		;   Examples: ^t (control t) !f5 (alt f5) +f6 (shift f6) #s (windows s) See http://www.autohotkey.com/docs/Hotkeys.htm for further documenation (Default f4)
		;MinLength=14
		;   Strings shorter than this length will not be stored in the archive (default 2)
		;Font=Courier
		;FontColor=FFF00
		;BGColor=808080
		;FontSize=10
	), reclinerv102.ini

FileRead, Settings, reclinerv102.ini
Loop, Parse, Settings, `n, `r
{	if (SubStr(A_LoopField,1,1)=";")
		continue
	StringGetPos, pos, A_LoopField, =
	if (ErrorLevel || !pos)
		continue
	StringLeft, VarName, A_LoopField, pos
	StringTrimLeft, VarVal, A_LoopField, pos+1
	%VarName%=%VarVal%
}

Defaults := {Hotkey:"f4",MinLength:2,FontColor:"DDEEDD",BGColor:221122,FontSize:12,Font:"Arial Narrow"}
for key,value in Defaults
	if !%key%
		%key%=%value%

Hotkey,%Hotkey%,uiLoop

log:=Object()
pre:=Object()
logL:=0
preL:=0
logsection=
Loop, Read, recliner.log
	if logsection
		log[logL++]:=A_LoopReadLine
	else if A_LoopReadLine = ### End Presets ###
		logsection=1
	else
		pre[preL++]:=A_LoopReadLine
while preL < 12
	pre[preL++]:=""
Gosub, RebuildPresets

mark:=0
browseKeys := Object("EndKey:Up",-1,"EndKey:Down",1,"EndKey:Delete",1,"EndKey:Left",-12,"EndKey:Right",12,"EndKey:Home",-999999,"EndKey:End",999999)

Menu, Tray, Nostandard
Menu, Tray, add, &Edit log, MenuEditLog
Menu, Tray, add, &Reload from log, MenuReload
Menu, Tray, add, &Edit Settings, MenuEditSettings
Menu, Tray, add
Menu, Tray, add, P&ause, MenuPause
Menu, Tray, add, S&ave, MenuSave
Menu, Tray, add, E&xit, MenuExit

Gui, Font, s%FontSize% c%FontColor%, %Font%
Gui, Color, %BGColor%
Gui, Add, Text,vConsole r14 -Wrap, WW`tWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW

Gui, +AlwaysOnTop +ToolWindow +Resize
Gui, show,, recLiner
VarSetCapacity( rect, 16, 0 )
GuiControl,,Console,% "`trecLiner 1.3`tHotkey: " . Hotkey . "`n... " . logL . " logs " . preL . " presets loaded from recliner.log`n`nTips:`n- Drag and resize this window to change location of console`n- Change font and color in recliner.ini`n`n`n`n`n`n`n`n(Press any key to continue)"
Winwaitactive, recLiner
MyGuiHWND := WinExist()
DllCall("GetClientRect", uint, MyGuiHWND, uint, &rect )
ClientH := NumGet( rect, 12, "int" )
Input, char, L1
Gui, -Caption -Resize
DllCall("GetClientRect", uint, MyGuiHWND, uint, &rect )
ClientW := NumGet( rect, 8, "int" )
WinMove, recLiner,,,,%ClientW%,%ClientH%
Winset, Region, 0-0 w%ClientW% h%ClientH% R30-30, recLiner
Gui, hide

Loop {
	Input, k, V M, {enter}{esc}{tab}
	if (StrLen(k)<MinLength)
		continue
	out=
	Loop,Parse,k
		if (A_LoopField = ctrDel) {
			out := RTrim(out)
			StringGetPos,pos,out,%A_Space%,R1
			if !ErrorLevel
				StringLeft,out,out,% pos+1
		} else if (A_LoopField = ctrH)
			StringTrimRight,out,out,1
		else if (A_LoopField = ctrA)
			out=
		else if (Asc(A_LoopField)>=32)
			out.=A_LoopField
	log[logL++]:=out
}
return

ConsoleMsg(string, hide=0) {
	if hide
	{	GuiControl,,Console,%string%
		Gui, show
		Winwaitactive, recLiner
		Input, char, L1
		Gui, hide
	} else {
		GuiControl,,Console,%string%
		Input, char, L1
	}
	return char
}

WriteLog:
	File := FileOpen("recliner.log","w `r`n")
	for key,value in pre
		File.WriteLine(value)
	File.WriteLine("### End Presets ###")
	for key,value in log
		File.WriteLine(value)
	File.close()
	return
MenuSave:
	Gosub, WriteLog
	ConsoleMsg(logL . " logs " . preL . " presets written to recliner.log`n(Press any key to continue)",1)
	return
MenuPause:
	Pause
	return
MenuReload:
	Reload
	return
MenuEditLog:
	Gosub, MenuSave
	Run, recliner.log
	return
MenuEditSettings:
	Run, reclinerv102.ini
	return
MenuExit:
	entry := ConsoleMsg("Save log? (y/n/esc)",1)
	if (entry="y")
		Gosub, WriteLog
	else if (entry!="n")
		return
	ExitApp

uiLoop:
Gui, show
next := mark>=0? (mark+1>=preL? preL-1 : mark+1) : (-mark>logL? -logL-1 : mark-1)
nextEnt := next>=0? pre[next] : log[-next-1]
GuiControl,,Console,% ">`t^U:clear ^V:paste ^Save arrows:history`nEnter`t" . (StrLen(nextEnt) > 50? SubStr(nextEnt,1,50) . "..." : nextEnt) . presets
matches := 1
Entry=
NotFirstPress=0
matchV := Object()
matchK := Object()
deleteK := {}
nmode=0
Winwaitactive, recLiner
Loop {
	Input, char, M L1, {enter}{esc}{bs}{f1}{f2}{f3}{f4}{f5}{f6}{f7}{f8}{f9}{f10}{f11}{f12}{up}{down}{left}{right}{delete}{home}{end}
	if browseKeys.HasKey(ErrorLevel) {
		nmode=1
		mark:=matches>1? matchK[1] : mark
		if (ErrorLevel="EndKey:Delete") && NotFirstPress
			if deleteK.HasKey(mark)
				deleteK.Remove(mark,"")
			else
				deleteK[mark]:=1
		if (mark>=0) {
			mark+=browseKeys[ErrorLevel]*(NotFirstPress || ErrorLevel="EndKey:Home" || ErrorLevel="EndKey:End")
			mark:=mark>=preL? preL-1 : mark<0? 0 : mark
			Entry:=pre[mark]
			start:=mark//12*12-1
			hist=
			Loop 12
				hist.="`n" . (A_Index+start=mark? ">" : " ") . (deleteK.HasKey(A_Index+start)? "X " : " ") . "F" . A_Index . "`t" . (A_Index+start+1) . " " . pre[A_Index+start] 
		} else {
			mark-=browseKeys[ErrorLevel]*(NotFirstPress || ErrorLevel="EndKey:Home" || ErrorLevel="EndKey:End")
			mark:=-mark-1>logL? -logL-1 : mark>-1? -1 : mark 
			Entry:=log[-mark-1]
			start:=(-mark-1)//12*12-1
			hist=
			Loop 12
				hist.="`n" . (A_Index+start=-mark-1? ">" : " ") . (deleteK.HasKey(-A_Index-start-1)? "X " : " ") . "f" . A_Index . "`t" . (A_Index+start+1) . " " . log[A_Index+start] 
		}
		NotFirstPress=1
		matches=1
		GuiControl,,Console,% "> " . (StrLen(Entry)>50? "..." . SubStr(Entry,-50) : Entry) .  hist
		continue
	} else if (ErrorLevel="EndKey:Backspace") {
		StringTrimRight, Entry, Entry, 1
		nmode=0
	} else if (SubStr(ErrorLevel,1,8)="EndKey:F") {
		fN:=SubStr(ErrorLevel,9)
		if fN<=12
			if (nmode=1) {
				SendString(mark>=0? pre[fN+start] : log[fN+start])
			} else if (matches>fN) {
				SendString(matchV[fN])
				mark:=matchK[fN]
			} else if (matches<=1)
				if (Entry!="") {
					pre[fN-1]:=Entry
					Gosub, RebuildPresets
					GoSub, uiLoop
				} else
					SendString(pre[fn-1])
		Gosub, ProcDel
		if deletions>0
			ConsoleMsg(deletions . " entries removed`n(Press any key to continue)")
		break
	} else if (ErrorLevel="EndKey:Enter") {
		if (nmode=1) {
			Gosub, ProcDel
			if deletions>0
				ConsoleMsg(deletions . " entries removed`n(Press any key to continue)")
			else
				SendString(Entry)
		} else if (matches>1) {
			SendString(matchV[1])
			mark:=matchK[1]
		} else if (Entry="") {
			mark := next
			SendString(nextEnt)
		} else {
			count=0
			while (pre[count]!="" && count<12)
				count++
			if count=12
				pre[preL++]:=Entry
			else {
				pre[count]:=Entry
				Gosub, RebuildPresets
			}
			SendString(Entry)
		}
		break
	} else if (ErrorLevel!="Max") {
		Sleep 99
		break
	} else if (char>ctrZ) {
		Entry.=char
		NotFirstPress=0
	} else if (char=ctrU)
		Entry := ""
	else if (char=ctrS) { 
		Gosub, WriteLog
		GoSub, ProcDel
		ConsoleMsg(logL . " logs " . preL . " presets written to recliner`n(Press any key to continue).log")
		break
	} else if (char=ctrV)
		Entry=%clipboard%
	matches:=1
	if Entry
	{	
		print := "> " . (StrLen(Entry)>50? "..." . SubStr(Entry,-50) : Entry)
		for key,value in pre {
			StringGetPos,pos,value,%Entry%
			if (pos=-1)
				continue
			matchV[matches] := value
			matchK[matches] := key
			len:=StrLen(value)
			print.="`n F" . matches . "`t" . key . " " . (pos<=50? value : len<100? value : "..." . SubStr(value,pos-50))
			if (++matches>12)
				break
		}
		key := logL
		while (key>0 && matches<=12) {
			key--
			value := log[key]
			StringGetPos,pos,value,%Entry%
			if (pos=-1)
				continue
			matchV[matches] := value
			matchK[matches] := -key-1
			len:=StrLen(value)
			print.="`n F" . matches . "`t" . key . " " . (pos<=50? value : len<100? value : "..." . SubStr(value,pos-50))
			matches++
		}
		GuiControl,,Console, % matches>1? print : print . "`nF1-12`tset`nEnter`tappend to presets && send"
	} else
		GuiControl,,Console, % ">`nEnter`t" . (StrLen(nextDisP) > 50? SubStr(nextEnt,1,50) . "..." : nextEnt) . presets
}
Gui, hide
return

ProcDel:
	deletions=0
	for key in deleteK {
		deletions++
		if key>=0
			pre[key]:=""
		else
			log.Remove(-key-1)
	}
RebuildPresets:
	presets:=""
	Loop 12
		presets.="`n F" . A_Index . "`t" . pre[A_Index-1]
	return

SendString(string) {
	Gui, hide
	WinWaitNotActive, RecGUI
	Send % SubStr(string,1,3)="###"? SubStr(string,4) : "{Raw}" . string
}
