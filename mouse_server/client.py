import asyncio
import websockets

# async def test():
#     async with websockets.connect('ws://localhost:8000') as websocket:
#         await websocket.send("hello")
#         response = await websocket.recv()
#         print(response)
 
# asyncio.get_event_loop().run_until_complete(test())

async def hello():
    async with websockets.connect("ws://172.20.10.2:8000") as websocket:
        await websocket.send("Hello world!")
        response = await websocket.recv()
        print(response)

asyncio.run(hello())
asyncio.run(hello())