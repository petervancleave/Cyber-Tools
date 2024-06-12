def caesar_decrypt(ciphertext, shift):
    decrypted_text = []
    for char in ciphertext:
        if char.isalpha():
            shift_base = ord('A') if char.isupper() else ord('a')
            decrypted_char = chr((ord(char) - shift_base - shift) % 26 + shift_base)
            decrypted_text.append(decrypted_char)
        else:
            decrypted_text.append(char)
    return ''.join(decrypted_text)

def all_caesar_shifts(ciphertext):
    variations = {}
    for shift in range(1, 26):
        decrypted_text = caesar_decrypt(ciphertext, shift)
        variations[shift] = decrypted_text
    return variations

def main():
    # prompt
    ciphertext = input("Enter the ciphertext: ")
    
    shifts = all_caesar_shifts(ciphertext)

    # print each variation
    for shift, decrypted_text in shifts.items():
        print(f"Shift {shift}: {decrypted_text}")

if __name__ == "__main__":
    main()
