class TestSpeedCheck:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.start_mcu_pos = {}
        self.register_commands()

    def register_commands(self):
        self.gcode.register_command('RECORD_START_POS', self.cmd_RECORD_START_POS, 
                                   help="Record MCU positions before test")
        self.gcode.register_command('COMPARE_POS', self.cmd_COMPARE_POS, 
                                   help="Compare current MCU positions to start")

    def get_mcu_positions(self):
        # Access the toolhead and kinematics to get raw stepper positions
        toolhead = self.printer.lookup_object('toolhead')
        kin = toolhead.get_kinematics()
        steppers = kin.get_steppers()
        
        pos_dict = {}
        for s in steppers:
            s_name = s.get_name()
            # mcu_position is the internal step counter
            pos_dict[s_name] = s.get_mcu_position()
        return pos_dict

    def cmd_RECORD_START_POS(self, gcmd):
        self.start_mcu_pos = self.get_mcu_positions()
        gcmd.respond_info("Initial MCU positions recorded.")

    def cmd_COMPARE_POS(self, gcmd):
        if not self.start_mcu_pos:
            gcmd.respond_info("No starting positions recorded! Run RECORD_START_POS first.")
            return

        end_mcu_pos = self.get_mcu_positions()
        output = ["Speed Test Results (Step Difference):"]
        
        for s_name, start_val in self.start_mcu_pos.items():
            end_val = end_mcu_pos.get(s_name, start_val)
            diff = end_val - start_val
            output.append(f"{s_name}: Start={start_val} | End={end_val} | Diff={diff}")

        gcmd.respond_info("\n".join(output))

def load_config(config):
    return TestSpeedCheck(config)
