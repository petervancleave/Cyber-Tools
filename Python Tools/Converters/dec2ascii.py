def decimal_to_text(decimal_numbers):
    text_output = ''.join(chr(int(decimal)) for decimal in decimal_numbers.split())
    return text_output

def main():
    while True:
        user_input = input("Enter the decimal numbers separated by spaces to convert to text (enter 'q' to quit): ")
        if user_input.lower() == 'q':
            break
        
        text_result = decimal_to_text(user_input)
        print(f"Text representation: {text_result}")

if __name__ == "__main__":
    main()
