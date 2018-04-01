@echo off
for %%i in (*) do (
    if not %%~xi == .m (
        if not %%~xi == .py (
            if not %%~xi == .cmd (
                if not %%~xi == .cam (
                    if not %%~xi == .docx (
                        if not %%i == LogoMacroPCB.scr (
                            if not %%i == README.txt (
                                if not %%i == .gitignore (
                                    del %%i
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)
echo on