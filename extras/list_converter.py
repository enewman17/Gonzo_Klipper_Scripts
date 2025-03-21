class ListConverter:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_command("CONVERT_LIST", self.cmd_CONVERT_LIST, desc="Convert a list of quoted strings to integers")

    def cmd_CONVERT_LIST(self, gcmd):
        list_param = gcmd.get('LIST', None)
        if list_param is None:
            raise gcmd.error("LIST parameter is required")
        
        # Split the input string into a list if it's comma-separated
        if isinstance(list_param, str):
            string_list = list_param.split(',')
        else:
            string_list = list_param
            
        # Convert the list
        converted = self.convert_string_list(string_list)
        
        # Save to variable
        var_name = gcmd.get('OUTPUT_VAR', 'variable_converted_list')
        self.gcode.run_script_from_command(f"SET_GCODE_VARIABLE MACRO=printer VARIABLE={var_name} VALUE={converted}")

def load_config(config):
    return ListConverter(config)
