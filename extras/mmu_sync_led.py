import logging
import asyncio
import json
from components import websockets
from typing import Callable

# Configuration
MOONRAKER_URL = "ws://localhost:7125/websocket"  # Default Moonraker WebSocket URL
MMU_SYNC_FEEDBACK_PATH = "notify_status_update" # Moonraker subscription
GCODE_COMMANDS = [
    "SET_LED_EFFECT EFFECT=sync_feedback_tension",
    "SET_LED_EFFECT EFFECT=sync_feedback_compression",
    "SET_LED_EFFECT EFFECT=sync_feedback_neutral",
]
# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class MmuSyncListener:
    """
    Listens for changes in mmu:sync_feedback from Moonraker and triggers G-code commands.
    """

    def __init__(self, moonraker_url: str):
        """
        Initializes the listener.

        Args:
            moonraker_url: The URL of the Moonraker WebSocket.
        """
        self.moonraker_url = moonraker_url
        self.websocket = None
        self.gcode_send_callback = None
        self.last_value = None
        self.subscribed = False # Track if subscribed

    async def connect(self):
        """Connects to the Moonraker WebSocket."""
        try:
            self.websocket = await websockets.connect(self.moonraker_url)
            logging.info("Connected to Moonraker WebSocket")
            return self.websocket
        except Exception as e:
            logging.error(f"Error connecting to Moonraker: {e}")
            return None

    async def subscribe(self):
        """Subscribes to the mmu:sync_feedback updates."""
        if not self.websocket or self.websocket.closed:
            logging.error("Websocket not connected")
            return

        if self.subscribed: # prevent resubscribing
            return

        subscribe_message = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "printer.subscribe",
            "params": {
                "items": {
                    MMU_SYNC_FEEDBACK_PATH: ["mmu:sync_feedback"],
                }
            }
        }
        try:
            await self.websocket.send(json.dumps(subscribe_message))
            response = await self.websocket.recv()
            response_json = json.loads(response)
            if "error" in response_json:
                logging.error(f"Subscription failed: {response_json['error']}")
                return
            logging.info("Subscribed to mmu:sync_feedback updates")
            self.subscribed = True
        except Exception as e:
            logging.error(f"Error subscribing to updates: {e}")

    def set_gcode_send_callback(self, callback: Callable[[str], None]):
        """Sets the callback function to send G-code commands."""
        self.gcode_send_callback = callback

    async def handle_updates(self):
        """Handles updates received from Moonraker."""
        if not self.websocket:
            return

        try:
            while not self.websocket.closed:
                message = await self.websocket.recv()
                update = json.loads(message)

                if "params" in update and update["method"] == "notify_status_update":
                    # handle the data
                    for changes in update["params"]:
                        if MMU_SYNC_FEEDBACK_PATH in changes:
                            mmu_feedback = changes[MMU_SYNC_FEEDBACK_PATH]
                            if "mmu:sync_feedback" in mmu_feedback:
                                value = mmu_feedback["mmu:sync_feedback"]
                                logging.info(f"Received update: mmu:sync_feedback = {value}")
                                if self.gcode_send_callback:
                                    if value != self.last_value:
                                        self.last_value = value
                                        if value == "tension":
                                            self.gcode_send_callback(GCODE_COMMANDS[0])
                                        elif value == "compression":
                                            self.gcode_send_callback(GCODE_COMMANDS[1])
                                        elif value == "neutral":
                                            self.gcode_send_callback(GCODE_COMMANDS[2])
                                        else:
                                            logging.warning(f"Unknown mmu:sync_feedback value: {value}")
                                else:
                                    logging.warning("G-code sender callback is not set.")
        except websockets.ConnectionClosed:
            logging.info("Connection to Moonraker closed.")
        except Exception as e:
            logging.error(f"Error handling updates: {e}")
            if self.websocket and not self.websocket.closed:
                await self.websocket.close()

    async def run(self):
        """Runs the listener: connect, subscribe, handle updates."""
        websocket = await self.connect()
        if websocket:
            await self.subscribe()
            await self.handle_updates()
        else:
            logging.error("Failed to connect to Moonraker. Listener stopped.")

    def start(self):
        """Starts the listener."""
        asyncio.run(self.run())



def gcode_sender(gcode_command: str) -> None:
    """
    G-code sender function for Moonraker.

    Args:
        gcode_command: The G-code command to send.
    """
    logging.info(f"Sending G-code: {gcode_command}")
    import requests
    try:
        response = requests.post(
            "http://localhost:7125/printer/gcode/script",  # Default Moonraker URL
            json={"script": gcode_command},
        )
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        logging.error(f"Error sending G-code: {e}")



def main():
    """Main function."""
    listener = MmuSyncListener(MOONRAKER_URL)
    listener.set_gcode_send_callback(gcode_sender)
    listener.start()


if __name__ == "__main__":
    main()
