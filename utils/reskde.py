import asyncio

async def cmd_restart_plasma() -> str:
    try:
        for target in ["kwin_wayland", "kwin_x11", "plasmashell"]:
            cont_proc = await asyncio.create_subprocess_exec(
                "pkill", "-CONT", "-f", target,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            await cont_proc.communicate()

        kill_proc = await asyncio.create_subprocess_exec(
            "pkill", "-9", "-f", "plasmashell",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await asyncio.wait_for(kill_proc.communicate(), timeout=2.0)

        start_proc = await asyncio.create_subprocess_exec(
            "systemctl", "--user", "restart", "plasma-plasmashell.service",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await asyncio.wait_for(start_proc.communicate(), timeout=3.0)

        return "Graphical shell successfully thawed and restarted."

    except asyncio.TimeoutError:
        return "Command forced, services are recovering."
    except Exception as e:
        return f"Error during recovery: {e}"
