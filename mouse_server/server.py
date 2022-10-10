import asyncio
 
import websockets
import pyautogui
import json
from screeninfo import get_monitors
import platform
import time

ctrlKey = "command" if platform.uname()[0]=='Darwin' else "ctrl"

width = get_monitors()[0].width
height = get_monitors()[0].height

def missionCtrl():
    if platform.uname()[0]=='Darwin':
        pyautogui.keyDown("ctrl")
        pyautogui.press("up")
        pyautogui.keyUp("ctrl")
    else:
        pyautogui.keyDown("alt")
        pyautogui.press("tab")
        pyautogui.keyUp("alt")

def switchToLaser():
    pyautogui.keyDown(ctrlKey)
    pyautogui.press("l")
    pyautogui.keyUp(ctrlKey)

def switchTab():
    pyautogui.keyDown(ctrlKey)
    pyautogui.press("tab")
    pyautogui.keyUp(ctrlKey)

def scroll(offset):
    print(offset)
    pyautogui.scroll(float(offset/20))

async def echo(websocket):
    async for message in websocket:
        data = json.loads(message)

        if "leftMouseClick" in data:
            if data["leftMouseClick"]:
                pyautogui.click()
            elif data["rightMouseClick"]:
                pyautogui.rightClick()
            elif data['mouseDoubleClick']:
                pyautogui.doubleClick()
            elif data['scroll'] != 0:
                scroll(data['scroll'])
        elif 'switchTab' in data:
            if data['switchTab']:
                switchTab()
            elif data['switchToLaser']:
                switchToLaser()
            elif data['missionCtrl']:
                missionCtrl()
            elif data['leftArrow']:
                pyautogui.press('left')
            elif data['rightArrow']:
                pyautogui.press('right')
            
        else:
            pitch = -data['pitch']
            yaw = -data['yaw']

            # await websocket.send(message)

            # Dynamic calculation for screen size
            dist_x = round((120/7)*(yaw)+(width/2))
            if dist_x > width:
                dist_x = width
            elif (dist_x < 0):
                dist_x = 0

            dist_y = round((80/7)*(pitch)+(height/2))
            if dist_y > height:
                dist_y = height
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