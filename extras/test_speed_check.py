# extras/test_speed_check.py
class TestSpeedCheck:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.start_mcu_pos = {}
        
        # Define descriptions for the G-Code terminal
        self.cmd_RECORD_DESC = "Record MCU stepper positions and microsteps before test"
        self.cmd_COMPARE_DESC = "Compare MCU stepper positions to start and report Pass/Fail based on microsteps"
        
        self.register_commands()

    def register_commands(self):
        # Registering with desc= as required by Klipper
        self.gcode.register_command('RECORD_START_POS', self.cmd_RECORD_START_POS, 
                                   desc=self.cmd_RECORD_DESC)
        self.gcode.register_command('COMPARE_POS', self.cmd_COMPARE_POS, 
                                   desc=self.cmd_COMPARE_DESC)

    def get_stepper_info(self):
        toolhead = self.printer.lookup_object('toolhead')
        kin = toolhead.get_kinematics()
        steppers = kin.get_steppers()
        configfile = self.printer.lookup_object('configfile')
        
        stepper_data = {}
        for s in steppers:
            s_name = s.get_name()
            mcu_pos = s.get_mcu_position()
            
            # Fetch microsteps from config, default to 16
            microsteps = 16
            if s_name in configfile.config:
                microsteps = int(configfile.config[s_name].get('microsteps', 16))
            
            stepper_data[s_name] = {
                'pos': mcu_pos,
                'microsteps': microsteps
            }
        return stepper_data

    def cmd_RECORD_START_POS(self, gcmd):
        self.start_mcu_pos = self.get_stepper_info()
        gcmd.respond_info("TEST_SPEED: Initial positions recorded.")

    def cmd_COMPARE_POS(self, gcmd):
        if not self.start_mcu_pos:
            gcmd.respond_info("TEST_SPEED: No starting positions found. Run RECORD_START_POS first.")
            return

        end_mcu_data = self.get_stepper_info()
        output = ["Speed Test Comparison Report:"]
        overall_fail = False
        
        for s_name, start_data in self.start_mcu_pos.items():
            start_val = start_data['pos']
            u_steps = start_data['microsteps']
            
            if s_name in end_mcu_data:
                end_val = end_mcu_data[s_name]['pos']
                diff = abs(end_val - start_val)
                
                # Comparison: Pass if diff <= 1 full step (the microstep value)
                status = "PASS"
                if diff > u_steps:
                    status = "FAIL"
                    overall_fail = True
                
                # Detailed output as requested
                output.append(
                    f"{s_name}: Start={start_val} | End={end_val} | Diff={diff} | "
                    f"Microsteps={u_steps} | Result: {status}"
                )

        final_report = "\n".join(output)
        if overall_fail:
            final_report += "\n\n!!! WARNING: SKIPPING DETECTED !!!"
        else:
            final_report += "\n\nSUCCESS: No significant skipping detected."
            
        gcmd.respond_info(final_report)

def load_config(config):
    return TestSpeedCheck(config)
