import base64

def hex_to_base32(hex_string):
    bytes_object = bytes.fromhex(hex_string)
    base32_encoded = base64.b32encode(bytes_object)
    base32_string = base32_encoded.decode('utf-8')
    return base32_string

def main():
    
    user_input = input("Enter the hexadecimal string to convert to Base32: ")
    try:

        base32_result = hex_to_base32(user_input)
       
        print(f"Base32 representation: {base32_result}")
    except ValueError:
        print("Invalid hexadecimal input.")

if __name__ == "__main__":
    main()
