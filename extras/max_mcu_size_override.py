from extras import neopixel

class MaxMCUSizeOverride:
    def __init__(self, config):
        # Retrieve the MAX_MCU_SIZE value from the [max_mcu_size] section
        max_mcu_size = config.getint('MAX_MCU_SIZE')
        # Override the MAX_MCU_SIZE variable in the neopixel module
        neopixel.MAX_MCU_SIZE = max_mcu_size

def load_config(config):
    # Klipper requires this function to instantiate the class
    return MaxMCUSizeOverride(config)
