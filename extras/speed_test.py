import logging

class SpeedTest:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.start_mcu_pos = {}
        
        # Descriptions
        self.cmd_START_DESC = "Record stepper microsteps and position before test"
        self.cmd_COMPARE_DESC = "Compare stepper positions and report Pass/Fail based on the difference in microsteps lost"
        
        self.register_commands()
        self.logger = logging.getLogger("SPEED_TEST")

    def register_commands(self):
        self.gcode.register_command('POSITION_START_INFO', self.cmd_POSITION_START_INFO, 
                                   desc=self.cmd_START_DESC)
        self.gcode.register_command('COMPARE_POSITION_END', self.cmd_COMPARE_POSITION_END, 
                                   desc=self.cmd_COMPARE_DESC)

    def get_stepper_info(self):
        toolhead = self.printer.lookup_object('toolhead')
        kin = toolhead.get_kinematics()
        steppers = kin.get_steppers()
        
        mcu_pos = s.get_mcu_position()
        
		# Pull microsteps from the settings dictionary
        configfile = self.printer.lookup_object('configfile')
        sconfig = configfile.get_status(None)['settings']
        stconfig = sconfig.get(s_name, {})
        microsteps = stconfig['microsteps']

        stepper_data = {}
        for s in steppers:
            # internal name to config name mapping
            s_name = s.get_name().replace(' ', '_')
            
            stepper_data[s_name] = {
                'pos': mcu_pos,
                'microsteps': microsteps
            }
        return stepper_data

    def cmd_POSITION_START_INFO(self, gcmd):
        try:
            self.start_mcu_pos = self.get_stepper_info()
            if not self.start_mcu_pos:
                raise gcmd.error("SPEED_TEST ERROR: No steppers found in settings.")
            else:
                s_list = ", ".join(self.start_mcu_pos.keys())
                gcmd.respond_info(f"SPEED_TEST: Recorded positions for: {s_list}")
                self.logger.info(f"SPEED_TEST Recorded: {self.start_mcu_pos}")
        except Exception as e:
            self.logger.exception("ERROR in POSITION_START_INFO")
            raise gcmd.error(f"!! SPEED_TEST ERROR: {str(e)} !!")


    def cmd_COMPARE_POSITION_END(self, gcmd):
        if not self.start_mcu_pos:
            raise gcmd.error("!! SPEED_TEST ERROR: No position values were found !!")
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
            self.logger.exception("ERROR in COMPARE_POSITION_END")
            raise gcmd.error(f"!! SPEED_TEST ERROR: {str(e)} !!")

def load_config(config):
    return SpeedTest(config)
