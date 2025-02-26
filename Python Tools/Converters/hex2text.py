def hex_to_text(hex_string):
    bytes_object = bytes.fromhex(hex_string)
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
