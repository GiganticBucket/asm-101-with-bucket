; this file is intentionally left empty. 
; 
; so here's the deal.  GIT doesn't track empty folders, and UberASM
; will always try to interpret ANY file in this folder as assembly, even
; a '.gitkeep' file. So we need a Non-empty ASM file that we don't use.
; yay.
init:

    RTL