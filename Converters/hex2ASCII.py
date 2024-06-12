def hex_to_ascii(hex_string):

    bytes_object = bytes.fromhex(hex_string)
    ascii_string = bytes_object.decode('ascii')
    return ascii_string

def main():
    while True:
        user_input = input("Enter the hexadecimal string to convert to ASCII (enter 'q' to quit): ")
        if user_input.lower() == 'q':
            break
        
        try:
            ascii_result = hex_to_ascii(user_input)
            print(f"ASCII representation: {ascii_result}")
        except ValueError:
            print("Invalid hexadecimal input. Please ensure the input is a valid hexadecimal string.")

if __name__ == "__main__":
    main()
