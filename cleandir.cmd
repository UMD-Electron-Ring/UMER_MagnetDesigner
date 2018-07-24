@echo off
for %%i in (*) do (
    if not %%~xi == .m (
        if not %%~xi == .py (
            if not %%~xi == .cmd (
                if not %%~xi == .cam (
                    if not %%~xi == .docx (
                        if not %%i == LogoMacroPCB.scr (
                            if not %%i == .gitignore (
                                if not %%~xi == .png (
                                    if not %%~xi == .md (
                                        if not %%~xi == .sh (
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
    )
)
echo on
