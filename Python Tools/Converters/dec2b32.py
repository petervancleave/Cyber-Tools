import base64

def decimal_to_base32(decimal_numbers):
    bytes_object = bytes(decimal_numbers)
    base32_encoded = base64.b32encode(bytes_object)
    base32_string = base32_encoded.decode('utf-8')
    return base32_string

def main():
    while True:
        user_input = input("Enter the decimal numbers separated by spaces to convert to Base32 (enter 'q' to quit): ")
        if user_input.lower() == 'q':
            break
        
        try:
            decimal_numbers = [int(num) for num in user_input.split()]
            base32_result = decimal_to_base32(decimal_numbers)
            print(f"Base32 representation: {base32_result}")
        except ValueError:
            print("Invalid input. Please enter valid decimal numbers separated by spaces.")

if __name__ == "__main__":
    main()
