def hex_to_text(hex_string):
    # Split the hex string into pairs of characters (each pair represents one byte)
    bytes_object = bytes.fromhex(hex_string)
    # Convert the bytes object to a string
    text_output = bytes_object.decode("utf-8")
    return text_output

def main():
    # Get user input
    user_input = input("Enter the hexadecimal string with no spaces to convert to text: ")
    try:
        
        text_result = hex_to_text(user_input)
        
        print(f"Text representation: {text_result}")
    except ValueError:
        print("Invalid hexadecimal input.")

if __name__ == "__main__":
    main()
