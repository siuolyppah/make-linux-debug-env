import sys

def extract_option_name(line):
    line = line.strip()
    if line.startswith("CONFIG_") and "=" in line:
        return line.split("=")[0]
    elif line.startswith("# CONFIG_") and "is not set" in line:
        return line.split()[1]
    else:
        return None

def parse_config(path):
    options = {}
    with open(path, "r") as file:
        for line in file:
            opt_name = extract_option_name(line)
            if opt_name:
                options[opt_name] = line.strip()
    return options

def overwrite_config(config_path, overwrite_path):
    overwrite_options = parse_simple_config(overwrite_path)

    def read_config_lines(config_path):
        with open(config_path, "r") as file:
            return file.readlines()

    lines = read_config_lines(config_path)

    with open(config_path, "w") as file:
        for line in lines:
            line_strip = line.strip()
            opt = extract_option_name(line_strip)
            if opt in overwrite_options:
                file.write(f"{overwrite_options[opt]}\n")
            else:
                file.write(f"{line_strip}\n")

def parse_simple_config(path):
    options = {}
    with open(path, "r") as file:
        for line in file:
            line = line.strip()
            if line and line.startswith("CONFIG_"):
                options[line.split('=')[0]] = line
    return options

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python overwrite_config.py <overwrite_config_path> <config_path>")
        sys.exit(1)

    overwrite_config_path = sys.argv[1]
    config_path = sys.argv[2]
    overwrite_config(config_path, overwrite_config_path)
