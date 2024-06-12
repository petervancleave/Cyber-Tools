def hex_to_binary(hex_string):
    bytes_object = bytes.fromhex(hex_string)
    binary_string = ''.join(format(byte, '08b') for byte in bytes_object)
    return binary_string

def main():
    while True:
    
        user_input = input("Enter the hexadecimal string to convert to binary (enter 'q' to quit): ")
        if user_input.lower() == 'q':
            break
        
        try:
            binary_result = hex_to_binary(user_input)
            print(f"Binary representation: {binary_result}")
        except ValueError:
            print("Invalid hexadecimal input. Please ensure the input is a valid hexadecimal string.")

if __name__ == "__main__":
    main()
