@echo off
setlocal enabledelayedexpansion

set toc_interface=90100
set toc_author=Vladinator ^(Voidzone-Ravencrest^), Aspyr ^(Aspyrox-Skullcrusher^) and Isak ^(Isak-Sargeras^)
set toc_addon=RaiderIO

for %%r in (
	"US	Americas"
	"EU	Europe"
	"KR	Korea"
	"TW	Taiwan"
) do (
	set r=%%r
	set r1=!r:~1,2!
	set r2=!r:~4,-1!

	for %%t in (
		"R	Raiding"
		"M	Mythic Plus"
	) do (
		set t=%%t
		set t1=!t:~1,1!
		set t2=!t:~3,-1!

		set lt=!t2!
		call :LoCase lt
		call :UnScor lt

		if !t1! neq M set t1=_!t1!
		if !t1! equ M set t1=

		if !lt! neq mythicplus set lt=_!lt!
		if !lt! equ mythicplus set lt=

		for %%f in (
			"A	Alliance"
			"H	Horde"
		) do (
			set f=%%f
			set f1=!f:~1,1!
			set f2=!f:~3,-1!

			set d=.\RaiderIO_DB_!r1!_!f1!!t1!
			set f=.\!d!\!d!.toc

			set lr=!r1!
			set lf=!f2!
			call :LoCase lr
			call :LoCase lf

			echo !d! !f!

			rmdir /s /q "!d!"
			mkdir "!d!"

			echo ## Interface: !toc_interface!>"!f!"
			echo ## Title: Raider.IO ^|cffFFFFFF!t2!^|r ^(!r2! - !f2!^)>>"!f!"
			echo ## Author: !toc_author!>>"!f!"
			echo ## Dependencies: !toc_addon!>>"!f!"
			echo ## DefaultState: enabled>>"!f!"
			echo ## X-Type: !t2!>>"!f!"
			echo ## X-Region: !r2!>>"!f!"
			echo ## X-Faction: !f2!>>"!f!"
			echo ## X-Website: https:^/^/raider.io>>"!f!"
			if !t1! == _R (
				echo ../!toc_addon!/db/db_raiding_!lr!_!lf!_characters.lua>>"!f!"
				echo ../!toc_addon!/db/db_raiding_!lr!_!lf!_lookup.lua>>"!f!"
			) else (
				echo ../!toc_addon!/db/db_!lr!_!lf!!lt!_characters.lua>>"!f!"
				echo ../!toc_addon!/db/db_!lr!_!lf!!lt!_lookup.lua>>"!f!"
			)
		)
	)
)
goto end

REM http://www.robvanderwoude.com/battech_convertcase.php
:LoCase
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF

:UnScor
:: Subroutine to convert spaces into empty strings.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN (" =") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF

:end
pause
