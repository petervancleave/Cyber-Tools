# 9:00 AM 2/8/2024

import tkinter as tk
from tkinter import messagebox
import bcrypt
import secrets
import json

class PasswordHasherApp:
    def __init__(self, master):
        self.master = master
        master.title("Password Hasher")

        screen_width = master.winfo_screenwidth()
        screen_height = master.winfo_screenheight()
        x = (screen_width - 300) // 2  
        y = (screen_height - 150) // 2  
        master.geometry(f"300x150+{x}+{y}")

        self.label = tk.Label(master, text="Enter Password:")
        self.label.pack()

        self.password_entry = tk.Entry(master, show="*")
        self.password_entry.pack()

        self.hash_button = tk.Button(master, text="Hash Password", command=self.hash_password)
        self.hash_button.pack()

        self.verify_label = tk.Label(master, text="Verify Password:")
        self.verify_label.pack()

        self.verify_entry = tk.Entry(master, show="*")
        self.verify_entry.pack()

        self.verify_button = tk.Button(master, text="Verify Password", command=self.verify_password)
        self.verify_button.pack()

        self.save_button = tk.Button(master, text="Save Hashed Password", command=self.save_hashed_password)
        self.save_button.pack()

    def hash_password(self):
        password = self.password_entry.get()

        if not password:
            messagebox.showwarning("Warning", "Please enter a password.")
            return

        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt)
        messagebox.showinfo("Hashed Password", f"Hashed Password: {hashed_password}")

    def verify_password(self):
        password = self.password_entry.get()
        hashed_password = self.verify_entry.get()

        if not password or not hashed_password:
            messagebox.showwarning("Warning", "Please enter both password and hashed password for verification.")
            return

        if bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8')):
            messagebox.showinfo("Verification", "Password is verified.")
        else:
            messagebox.showwarning("Verification", "Password verification failed.")

    def save_hashed_password(self):
        username = self.master.clipboard_get() 
        if not username:
            messagebox.showwarning("Warning", "Please copy the username to the clipboard.")
            return

        password = self.password_entry.get()

        if not password:
            messagebox.showwarning("Warning", "Please enter a password.")
            return

        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt)

        # store the hashed password securely. Adjust based on storage needs.
        credentials = {'username': username, 'hashed_password': hashed_password.decode('utf-8')}
        with open('passwords.json', 'a') as file:
            json.dump(credentials, file)
            file.write('\n')

        messagebox.showinfo("Saved Password", "Hashed password has been securely saved.")

if __name__ == "__main__":
    root = tk.Tk()
    app = PasswordHasherApp(root)
    root.mainloop()
