import random
import string

def generate_password(length):
    # character set
    characters = string.ascii_letters + string.digits + string.punctuation
    # password has at least one lowercase, one uppercase, one digit, and one symbol
    password = [
        random.choice(string.ascii_lowercase),
        random.choice(string.ascii_uppercase),
        random.choice(string.digits),
        random.choice(string.punctuation)
    ]
    # fill the rest of the password with random characters from the set
    password += random.choices(characters, k=length-4)
    # Shuffle 
    random.shuffle(password)
    return ''.join(password)

def generate_unique_passwords(num_passwords, min_length, max_length):
    unique_passwords = set()
    while len(unique_passwords) < num_passwords:
        # Generate a password with a random length between min_length and max_length
        length = random.randint(min_length, max_length)
        new_password = generate_password(length)
        unique_passwords.add(new_password)
    return list(unique_passwords)

# Make 10 unique passwords with lengths between 12-15 characters
passwords = generate_unique_passwords(10, 12, 15)

for i, password in enumerate(passwords, 1):
    print(f"Password {i}: {password}")
