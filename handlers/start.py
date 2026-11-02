from aiogram import Router, F, types
from aiogram.filters import CommandStart, Command
from aiogram.types import Message
from utils.reskde import cmd_restart_plasma
start_router = Router()

@start_router.message(CommandStart())
async def cmd_start(message: Message):
    kb = [
            [types.KeyboardButton(text="/restart")],
        ]
    keyboard = types.ReplyKeyboardMarkup(keyboard=kb, resize_keyboard=True)
    await message.answer('To restart KDE Plasma 6, enter the /restart command or tap the Restart button.', reply_markup=keyboard)

@start_router.message(Command('restart'))
async def cmd_restart(message: Message):
    await message.answer('Restart KDE Plasma6')
    result = await cmd_restart_plasma()
    await message.answer(result)
