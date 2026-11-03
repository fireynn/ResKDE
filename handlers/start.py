from aiogram import Router, F, types
from aiogram.filters import BaseFilter
from aiogram.filters import CommandStart, Command
from aiogram.types import Message
from utils.reskde import cmd_restart_plasma
from decouple import config
from dotenv import set_key
import os

start_router = Router()


class IsTargetUser(BaseFilter):
    async def __call__(self, message: types.Message) -> bool:
        raw_id = config("IDUSER", default=None)
        if not raw_id:
            return False
        return message.from_user.id == int(raw_id)


@start_router.message(Command('id'))
async def register(message: types.Message):
    current_configured_id = config("IDUSER", default=None)
    if current_configured_id:
        await message.answer("User ID is already registered.")
        return

    current_id = message.from_user.id
    set_key(
        dotenv_path=".env",
        key_to_set="IDUSER",
        value_to_set=str(current_id)
    )
    os.environ["IDUSER"] = str(current_id)

    await message.answer(f"Your ID ({current_id}) saved in .env!")


@start_router.message(CommandStart(), IsTargetUser())
async def cmd_start(message: Message):
    kb = [
        [types.KeyboardButton(text="/restart")],
    ]
    keyboard = types.ReplyKeyboardMarkup(keyboard=kb, resize_keyboard=True)
    await message.answer('To restart KDE Plasma 6, enter the /restart command or tap the Restart button.', reply_markup=keyboard)


@start_router.message(Command('restart'), IsTargetUser())
async def cmd_restart(message: Message):
    await message.answer('Restart KDE Plasma6')
    result = await cmd_restart_plasma()
    await message.answer(result)
