import logging

class TestSpeedCheck:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.start_mcu_pos = {}
        
        # Descriptions
        self.cmd_RECORD_DESC = "Record MCU stepper positions and microsteps before test"
        self.cmd_COMPARE_DESC = "Compare MCU positions to start and report Pass/Fail"
        
        self.register_commands()
        self.logger = logging.getLogger("test_speed_check")


    def register_commands(self):
        self.gcode.register_command('RECORD_START_POS', self.cmd_RECORD_START_POS, 
                                   desc=self.cmd_RECORD_DESC)
        self.gcode.register_command('COMPARE_POS', self.cmd_COMPARE_POS, 
                                   desc=self.cmd_COMPARE_DESC)

    def get_stepper_positions(self):
        toolhead = self.printer.lookup_object('toolhead')
        kin = toolhead.get_kinematics()
        steppers = kin.get_steppers()
        
        # Access the config data via the printer settings object
        configfile = self.printer.lookup_object('configfile')
        
        stepper_data = {}
        for s in steppers:
            # internal name to config name mapping
            s_name = s.get_name().replace(' ', '_')
            
            mcu_pos = s.get_mcu_position()
            # Pull microsteps from the settings dictionary
            configfile = self.printer.lookup_object('configfile')
            sconfig = configfile.get_status(None)['settings']
            stconfig = sconfig.get(s_name, {})
            microsteps = stconfig['microsteps']
        
            stepper_data[s_name] = {
                'pos': mcu_pos,
                'microsteps': microsteps
            }
        return stepper_data

    def cmd_RECORD_START_POS(self, gcmd):
        try:
            self.start_mcu_pos = self.get_stepper_positions()
            if not self.start_mcu_pos:
                raise gcmd.error("TEST_SPEED: No steppers found in settings.")
            else:
                s_list = ", ".join(self.start_mcu_pos.keys())
                gcmd.respond_info(f"TEST_SPEED: Recorded positions for: {s_list}")
                self.logger.info(f"TEST_SPEED recorded: {self.start_mcu_pos}")
        except Exception as e:
            self.logger.exception("Error in RECORD_START_POS")
            raise gcmd.error(f"!! TEST_SPEED Error: {str(e)} !!")


    def cmd_COMPARE_POS(self, gcmd):
        if not self.start_mcu_pos:
            raise gcmd.error("!! TEST_SPEED: No stepper position values were found !!")
            return

        try:
            end_mcu_data = self.get_stepper_info()
            output = ["Speed Test Comparison Report:"]
            overall_fail = False
            
            for s_name, start_data in self.start_mcu_pos.items():
                if s_name in end_mcu_data:
                    start_val = start_data['pos']
                    u_steps = start_data['microsteps']
                    end_val = end_mcu_data[s_name]['pos']
                    
                    diff = abs(end_val - start_val)
                    status = "PASS"
                    if diff > u_steps:
                        status = "FAIL"
                        overall_fail = True
                    
                    line = (f"{s_name}: Start={start_val} | End={end_val} | "
                            f"Diff={diff} | Microsteps={u_steps} | Result: {status}")
                    output.append(line)
                    self.logger.info(line)

            final_report = "\n".join(output)
            if overall_fail:
                final_report += "\n\n!!! WARNING: SKIPPING DETECTED !!!"
            else:
                final_report += "\n\nSUCCESS: No significant skipping detected."
                
            gcmd.respond_info(final_report)
            
        except Exception as e:
            self.logger.exception("Error in COMPARE_POS")
            raise gcmd.error(f"!! TEST_SPEED Error: {str(e)} !!")

def load_config(config):
    return TestSpeedCheck(config)
