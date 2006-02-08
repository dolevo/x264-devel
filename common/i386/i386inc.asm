;*****************************************************************************
;* i386inc.asm: h264 encoder library
;*****************************************************************************
;* Copyright (C) 2006 x264 project
;*
;* Author: Sam Hocevar <sam@zoy.org>
;*
;* This program is free software; you can redistribute it and/or modify
;* it under the terms of the GNU General Public License as published by
;* the Free Software Foundation; either version 2 of the License, or
;* (at your option) any later version.
;*
;* This program is distributed in the hope that it will be useful,
;* but WITHOUT ANY WARRANTY; without even the implied warranty of
;* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;* GNU General Public License for more details.
;*
;* You should have received a copy of the GNU General Public License
;* along with this program; if not, write to the Free Software
;* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111, USA.
;*****************************************************************************

BITS 32

;=============================================================================
; Macros and other preprocessor constants
;=============================================================================

%macro cglobal 1
    %ifdef PREFIX
        global _%1
        %define %1 _%1
    %else
        global %1
    %endif
%endmacro

; PIC support macros. All these macros are totally harmless when __PIC__ is
; not defined but can ruin everything if misused in PIC mode. On x86, shared
; objects cannot directly access global variables by address, they need to
; go through the GOT (global offset table). Most OSes do not care about it
; and let you load non-shared .so objects (Linux, Win32...). However, OS X
; requires PIC code in its .dylib objects.
;
; - GLOBAL should be used as a suffix for global addressing, eg.
;     mov eax, [foo GLOBAL]
;   instead of
;     mov eax, [foo]
;
; - picgetgot computes the GOT address into the given register in PIC
;   mode, otherwise does nothing. You need to do this before using GLOBAL.
;
; - picpush and picpop respectively push and pop the given register
;   in PIC mode, otherwise do nothing. You should always use them around
;   picgetgot except when sure that the register is no longer used and is
;   being restored later by other means.
;
; - picesp is defined to compensate the changing of esp when pushing
;   a register into the stack, eg.
;     mov eax, [esp + 8]
;     pushpic  ebx
;     mov eax, [picesp + 12]
;   instead of
;     mov eax, [esp + 8]
;     pushpic  ebx
;     mov eax, [esp + 12]
;
%ifdef __PIC__
    extern _GLOBAL_OFFSET_TABLE_
    ; FIXME: find an elegant way to use registers other than ebx
    %define GLOBAL + ebx wrt ..gotoff
    %macro picgetgot 1
        call %%getgot 
      %%getgot: 
        pop %1 
        add %1, _GLOBAL_OFFSET_TABLE_ + $$ - %%getgot wrt ..gotpc 
    %endmacro
    %macro picpush 1
        push %1
    %endmacro
    %macro picpop 1
        pop %1
    %endmacro
    %define picesp esp+4
%else
    %define GLOBAL
    %macro picgetgot 1
    %endmacro
    %macro picpush 1
    %endmacro
    %macro picpop 1
    %endmacro
    %define picesp esp
%endif

