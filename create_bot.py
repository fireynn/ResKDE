import aiogram
import logging
from aiogram.fsm.storage.memory import MemoryStorage
from aiogram.client.session.aiohttp import AiohttpSession
from decouple import config

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

PROXY_URL = config("PROXY_URL", default=None)
if PROXY_URL:
    session = AiohttpSession(proxy=PROXY_URL)
    bot = aiogram.Bot(token=config("TOKEN"), session=session)
else:
    bot = aiogram.Bot(token=config("TOKEN"))
dp = aiogram.Dispatcher(storage=MemoryStorage())
