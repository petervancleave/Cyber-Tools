def decimal_to_text(decimal_number):
    text_output = chr(decimal_number)
    return text_output

def main():
    while True:
        user_input = input("Enter the decimal number to convert to text (enter 'q' to quit): ")
        if user_input.lower() == 'q':
            break
        
        try:
            decimal_number = int(user_input)
            text_result = decimal_to_text(decimal_number)
            print(f"Text representation: {text_result}")
        except ValueError:
            print("Invalid input. Please enter a valid decimal number.")

if __name__ == "__main__":
    main()
