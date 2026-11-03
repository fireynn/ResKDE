from aiogram import Router, F, types
from aiogram.filters import BaseFilter
from aiogram.filters import CommandStart, Command
from aiogram.types import Message
from utils.reskde import cmd_restart_plasma
from decouple import config
from dotenv import set_key
start_router = Router()
id_user = config("IDUSER", default=None)
if id_user:
    id_user = int(id_user)
    print(id_user)


@start_router.message(Command('id'))
async def register(message: types.Message):
    if id_user:
        return
    current_id = message.from_user.id
    set_key(
            dotenv_path=".env",
            key_to_set="IDUSER",
            value_to_set=str(current_id)
        )
    id_user = current_id
    await message.answer(f"Your ID ({current_id}) save in .env!")

class IsTargetUser(BaseFilter):
    async def __call__(self, message: types.Message) -> bool:
        global id_user
        return message.from_user.id == id_user


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
