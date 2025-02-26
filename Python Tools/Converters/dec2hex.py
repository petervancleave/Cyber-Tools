def decimal_to_hex(decimal_number):
    hex_output = hex(decimal_number)
    return hex_output

def main():
    while True:
        user_input = input("Enter the decimal number to convert to hexadecimal (enter 'q' to quit): ")
        if user_input.lower() == 'q':
            break
        
        try:
            decimal_number = int(user_input)
            hex_result = decimal_to_hex(decimal_number)
            print(f"Hexadecimal representation: {hex_result}")
        except ValueError:
            print("Invalid input. Please enter a valid decimal number.")

if __name__ == "__main__":
    main()
