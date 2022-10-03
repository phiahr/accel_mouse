import asyncio
 
import websockets
import pyautogui
import json
from screeninfo import get_monitors


width = get_monitors()[0].width
height = get_monitors()[0].height


async def echo(websocket):
    async for message in websocket:
        data = json.loads(message)

        if "leftMouseClick" in data:
            print("leftMouseClick")
            pyautogui.click()
        else:
            pitch = -data['pitch']
            yaw = -data['yaw']

            # await websocket.send(message)

            # Dynamic calculation for screen size
            dist_x = round((120/7)*(yaw)+(width/2))
            if dist_x > 1200:
                dist_x = 1200
            elif (dist_x < 0):
                dist_x = 0

            dist_y = round((80/7)*(pitch)+(height/2))
            if dist_y > 800:
                dist_y = 800
            elif (dist_y < 0) :
                dist_y = 0
            pyautogui.moveTo(int(dist_x), int(dist_y))
        


async def main():
    async with websockets.serve(echo, "172.20.10.2", 8000):
        await asyncio.Future()  # run forever

asyncio.run(main())
 

# # create handler for each connection
 
# async def handler(websocket, path):
 
#     data = await websocket.recv()
#     print(data)
 
#     reply = f"Data recieved as:  {data}!"
 
#     # await websocket.send(reply)
 
 
 
# start_server = websockets.serve(handler, "172.20.10.2", 8000)

# asyncio.get_event_loop().run_until_complete(start_server)
 
# asyncio.get_event_loop().run_forever()