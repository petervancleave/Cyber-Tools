import psutil
import time
import tkinter as tk

class BandwidthMonitorGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Bandwidth Monitor")
        
        self.sent_label = tk.Label(root, text="Sent: 0.00 B/s")
        self.sent_label.pack()

        self.received_label = tk.Label(root, text="Received: 0.00 B/s")
        self.received_label.pack()

        self.start_button = tk.Button(root, text="Start Monitoring", command=self.start_monitoring)
        self.start_button.pack()

        self.stop_button = tk.Button(root, text="Stop Monitoring", command=self.stop_monitoring, state=tk.DISABLED)
        self.stop_button.pack()

        self.running = False

    def get_bandwidth_usage(self):
        net_io = psutil.net_io_counters()
        return net_io.bytes_sent, net_io.bytes_recv

    def format_bytes(self, bytes):
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes < 1024.0:
                break
            bytes /= 1024.0
        return f"{bytes:.2f} {unit}/s"

    def update_labels(self):
        sent_before, received_before = self.get_bandwidth_usage()
        time.sleep(1)
        sent_after, received_after = self.get_bandwidth_usage()

        sent_speed = self.format_bytes(sent_after - sent_before)
        received_speed = self.format_bytes(received_after - received_before)

        self.sent_label.config(text=f"Sent: {sent_speed}")
        self.received_label.config(text=f"Received: {received_speed}")

        if self.running:
            self.root.after(1000, self.update_labels)

    def start_monitoring(self):
        self.running = True
        self.update_labels()
        self.start_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)

    def stop_monitoring(self):
        self.running = False
        self.start_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)

if __name__ == "__main__":
    root = tk.Tk()
    app = BandwidthMonitorGUI(root)
    root.mainloop()
