def hex_to_decimal_int(hex_number):
  try:
    decimal_value = int(hex_number, 16)
    return decimal_value
  except ValueError:
    print("Invalid hexadecimal input. Please enter a valid hex string.")
    return None

def main():
  while True:
    hex_string = input("Enter a hexadecimal number (or 'q' to quit): ")
    if hex_string.lower() == 'q':
      break
    decimal_value = hex_to_decimal_int(hex_string)
    if decimal_value is not None:
      print(f"{hex_string} (hex) is equivalent to {decimal_value} (decimal)")

if __name__ == "__main__":
  main()
