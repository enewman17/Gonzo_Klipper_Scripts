# from extras import neopixel

# class MaxMCUSizeOverride:
#     def __init__(self, config):
#         # Retrieve the MAX_MCU_SIZE value from the [max_mcu_size] section
#         max_mcu_size = config.getint('MAX_MCU_SIZE')
#         # Override the MAX_MCU_SIZE variable in the neopixel module
#         neopixel.MAX_MCU_SIZE = max_mcu_size

# def load_config(config):
#     # Klipper requires this function to instantiate the class
#     return MaxMCUSizeOverride(config)






# Klipper extra to override the MAX_MCU_SIZE in the neopixel module
#
# Copyright (C) 2025  GonzoStrange
#
# This file may be distributed under the terms of the GNU GPLv3 license.

# Import the original neopixel module to modify it
# import klippy.extras.neopixel as neopixel_module

# class MaxMCUSizeOverride:
#     def __init__(self, config):
#         self.printer = config.get_printer()
        
#         # Read the 'max_size' value from the [neopixel_size_override] section
#         # in printer.cfg. Set a minimum value of 1.
#         new_max_size = config.getint('MAX_MCU_SIZE', default=None, minval=500)
        
#         if new_max_size is None:
#             return

#         # Get the original value for logging purposes
#         original_max_size = neopixel_module.MAX_MCU_SIZE

#         # Override the constant in the imported neopixel module
#         neopixel_module.MAX_MCU_SIZE = new_max_size
        
#         # Log a message to klipper.log and the console for confirmation
#         gcode = self.printer.lookup_object('gcode')
#         gcode.respond_info(
#             f"✅ Neopixel MAX_MCU_SIZE overridden.\n"
#             f"   Original: {original_max_size}, New: {new_max_size}"
#         )

# # Klipper requires this function to load the module
# def load_config_prefix(config):
#     # This registers the [neopixel_size_override] config section
#     return MaxMCUSizeOverride(config)


# Custom Klipper module to override MAX_MCU_SIZE for Neopixel
#
# Copyright (C) 2025  Grok (based on original neopixel.py by Kevin O'Connor)
#
# This file may be distributed under the terms of the GNU GPLv3 license.

import logging
from . import neopixel

class PrinterNeoPixelOverride(neopixel.PrinterNeoPixel):
    def __init__(self, config):
        # Get MAX_MCU_SIZE from config, default to 500 if not specified
        self.MAX_MCU_SIZE = config.getint('max_mcu_size', 500)
        super().__init__(config)

def load_config_prefix(config):
    return PrinterNeoPixelOverride(config)



# Custom Klipper module to override MAX_MCU_SIZE for Neopixel
#
# Copyright (C) 2025  Grok (based on original neopixel.py by Kevin O'Connor)
#
# This file may be distributed under the terms of the GNU GPLv3 license.

import logging
from . import neopixel

class PrinterNeoPixelOverride(neopixel.PrinterNeoPixel):
    def __init__(self, config):
        # Get MAX_MCU_SIZE from config, default to 500 if not specified
        self.MAX_MCU_SIZE = config.getint('max_mcu_size', 500, minval=1)
        super().__init__(config)
        # Validate chain length against custom MAX_MCU_SIZE
        if len(self.color_map) > self.MAX_MCU_SIZE:
            raise config.error("neopixel chain too long (max %d)" % (self.MAX_MCU_SIZE,))

def load_config_prefix(config):
    return PrinterNeoPixelOverride(config)
