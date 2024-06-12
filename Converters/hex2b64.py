import base64

def hex_to_base64(hex_string):
    # convert the hex string to bytes
    bytes_object = bytes.fromhex(hex_string)
    
    base64_encoded = base64.b64encode(bytes_object)
    base64_string = base64_encoded.decode('utf-8')
    return base64_string

def main():
    while True:
       
        user_input = input("Enter the hexadecimal string to convert to Base64 (enter 'q' to quit): ")
        if user_input.lower() == 'q':
            break
        
        try:
    
            base64_result = hex_to_base64(user_input)
    
            print(f"Base64 representation: {base64_result}")
        except ValueError:
            print("Invalid hexadecimal input.")

if __name__ == "__main__":
    main()
