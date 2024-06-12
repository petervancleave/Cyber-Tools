
import tkinter as tk
from tkinter import filedialog, messagebox

def parse_file(file_path):
    try:
        with open(file_path, 'r') as file:
            content = file.read()
            word_count = len(content.split())
            line_count = content.count('\n') + 1

            # message box
            message = f"File parsed successfully!\n\nWord count: {word_count}\nLine count: {line_count}"
            messagebox.showinfo("File Parsed", message)

    except Exception as e:
        messagebox.showerror("Error", f"Error parsing the file:\n{str(e)}")

def open_file_dialog():
    file_path = filedialog.askopenfilename(filetypes=[("Text files", "*.txt")])
    if file_path:
        parse_file(file_path)

# main application window
app = tk.Tk()
app.title("Enhanced Text File Parser")

# open button
open_button = tk.Button(app, text="Open File", command=open_file_dialog)
open_button.pack(pady=20)

app.mainloop()
