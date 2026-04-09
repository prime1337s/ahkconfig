#+r::Reload  ; Windows+Shift+R Reload config

; RUNNING APPS

#w::Run("powershell.exe -Command Start-Process 'https:'", , "Hide")
#c::Run "calc"
#m::Run "mmsys.cpl"
#Enter::Run "wt.exe"
;Insert::Run "flameshot"
;#Enter::Run "powershell" " -NoExit -Command Set-Location ~"
;+#Enter::Run "wt.exe debian.exe" 

; MEDIA CONTROL

#+MButton::media_play_pause
#+WheelUp::SoundSetVolume "+5"
#+WheelDown::SoundSetVolume "-5"
;#=::SoundSetVolume "+5"
;#é::SoundSetVolume "-5"
#á::media_play_pause
#é::volume_mute
#=::volume_down
#SC00D::volume_up
#ý::media_prev
#í::media_next

; DISABLE USELESS SHORTCUTS
*#d::return 
*#q::return
;#f::return

; SYSTEM MANIPULATION

#f::{
    state := WinGetMinMax("A")
    if (state = 1)
        WinRestore("A")
    else
        WinMaximize("A")
}
; SYSTEM MANIPULATION

#+g::
{
    clipboardBackup := A_Clipboard
    A_Clipboard := ""

    Send "^c"
    if !ClipWait(1) {
        MsgBox "No text selected."
        A_Clipboard := clipboardBackup
        return
    }

    query := A_Clipboard
    query := StrReplace(query, "`r`n", " ")
    query := StrReplace(query, "`n", " ")
    query := StrReplace(query, " ", "+")

    Run "https://www.google.com/search?q=" query

    A_Clipboard := clipboardBackup
}
+#l::Run "powershell.exe rundll32.exe powrprof.dll,SetSuspendState 0,1,0"
#q::WinClose "A"
#+t::{
    WinSetAlwaysOnTop -1, "A"
}

#Requires AutoHotkey v2.0

global lastLayout := Map()

#d::
{
    global lastLayout

    windows := GetTopTwoWindows()

    if windows.Length < 2 {
        MsgBox "I couldn't find two visible windows to tile."
        return
    }

    leftHwnd := windows[1]
    rightHwnd := windows[2]

    ; Save original positions before tiling
    lastLayout := Map()
    lastLayout[leftHwnd] := GetWindowRect(leftHwnd)
    lastLayout[rightHwnd] := GetWindowRect(rightHwnd)

    ; Restore first in case one is maximized/minimized
    Try WinRestore(leftHwnd)
    Try WinRestore(rightHwnd)

    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    workW := right - left
    workH := bottom - top
    halfW := Floor(workW / 2)

    ; Tile left/right
    WinMove(left, top, halfW, workH, leftHwnd)
    WinMove(left + halfW, top, workW - halfW, workH, rightHwnd)

    WinActivate(leftHwnd)
}

#+d::
{
    global lastLayout

    if lastLayout.Count = 0 {
        MsgBox "No saved window layout to restore."
        return
    }

    for hwnd, rect in lastLayout {
        if !WinExist("ahk_id " hwnd)
            continue

        Try WinRestore(hwnd)
        Try WinMove(rect.x, rect.y, rect.w, rect.h, hwnd)
    }

    lastLayout := Map()
}

GetWindowRect(hwnd)
{
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    return { x: x, y: y, w: w, h: h }
}

GetTopTwoWindows()
{
    result := []
    hwndList := WinGetList()  ; topmost to bottommost

    for hwnd in hwndList {
        if !IsUsableWindow(hwnd)
            continue

        result.Push(hwnd)

        if result.Length = 2
            break
    }

    return result
}

IsUsableWindow(hwnd)
{
    try {
        title := WinGetTitle(hwnd)
        mm := WinGetMinMax(hwnd)
        style := WinGetStyle(hwnd)
        exStyle := WinGetExStyle(hwnd)
        class := WinGetClass(hwnd)
    } catch {
        return false
    }

    if !WinExist("ahk_id " hwnd)
        return false

    if class = "Progman" || class = "WorkerW" || class = "Shell_TrayWnd"
        return false

    if Trim(title) = ""
        return false

    if mm = -1
        return false

    if !(style & 0x10000000) ; WS_VISIBLE
        return false

    if (exStyle & 0x80) ; WS_EX_TOOLWINDOW
        return false

    return true
}

^+v::  ; Ctrl+Shift+V               ; plain text–only paste from ClipBoard
{					     ; works with Clipboard History. AHKv2 built-in variable A_Clipboard references only the top item.
   ClipSaved := ClipBoardAll()  ; save clipboard as an object which might include formatting, images, non-text data

   ; assignment converts potential object to plain text and trims all whitespace. See AHKv2 Escape Sequences
   A_ClipBoard := Trim( A_ClipBoard,"`n`r`b`t`s`v`a`f") 

   SendInput "^v"                    ; request natural OS paste  feature; For best compatibility: SendPlay
   Sleep 50                            ; Don't change clipboard while it is being pasted! (Sleep > 0)
   A_Clipboard := ClipSaved   ; Restore ClipBoard's original state
   ClipSaved := ""                   ; Releases the reference to free the resources used by an object
Return
}
