/*
 * PROJECT:     LiberNT API tests
 * LICENSE:     GPL-3.0-or-later (https://spdx.org/licenses/GPL-3.0-or-later)
 * PURPOSE:     Observe user32 module lifetime across dynamic loads
 * COPYRIGHT:   Copyright 2026 orhunnx <orhuntopcux@gmail.com>
 */

#include <windows.h>

static VOID
PrintText(PCSTR Text)
{
    DWORD Length = (DWORD)lstrlenA(Text);
    DWORD Written;

    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), Text, Length, &Written, NULL);
}

static VOID
PrintValue(PCSTR Name, DWORD Value)
{
    static CHAR Buffer[] = "0x00000000\r\n";
    static const CHAR Digits[] = "0123456789abcdef";
    ULONG Index;

    for (Index = 0; Index < 8; ++Index)
        Buffer[2 + Index] = Digits[(Value >> ((7 - Index) * 4)) & 0xf];

    PrintText(Name);
    PrintText("=");
    PrintText(Buffer);
}

VOID __cdecl
mainCRTStartup(VOID)
{
    HMODULE Module;
    DWORD Error;
    BOOL Result;

    PrintValue("probe_version", 1);
    PrintValue("user32_initially_loaded", GetModuleHandleW(L"user32.dll") != NULL);

    Module = LoadLibraryW(L"user32.dll");
    Error = Module != NULL ? ERROR_SUCCESS : GetLastError();
    PrintValue("load_1_ok", Module != NULL);
    PrintValue("load_1_error", Error);

    if (Module != NULL)
    {
        Result = FreeLibrary(Module);
        Error = Result ? ERROR_SUCCESS : GetLastError();
        PrintValue("free_1_ok", Result != FALSE);
        PrintValue("free_1_error", Error);
    }

    PrintValue("loaded_after_free", GetModuleHandleW(L"user32.dll") != NULL);

    Module = LoadLibraryW(L"user32.dll");
    Error = Module != NULL ? ERROR_SUCCESS : GetLastError();
    PrintValue("load_2_ok", Module != NULL);
    PrintValue("load_2_error", Error);

    if (Module != NULL)
    {
        Result = FreeLibrary(Module);
        Error = Result ? ERROR_SUCCESS : GetLastError();
        PrintValue("free_2_ok", Result != FALSE);
        PrintValue("free_2_error", Error);
    }

    ExitProcess(0);
}
