import datetime

def add_time_to_current():
    # pull current local time from the device
    current_time = datetime.datetime.now()
    
    print(f"Current local time: {current_time.strftime('%I:%M %p')}")
    
    # prompt for user input
    user_input = input("How much time would you like to add to your current local time? (HH:MM format): ")
    
    # split user input
    try:
        hours, minutes = map(int, user_input.split(':'))
    except ValueError:
        print("Invalid input format. Please enter time in HH:MM format.")
        return

    # time calculation
    new_time = current_time + datetime.timedelta(hours=hours, minutes=minutes)

    # new time
    print(f"The new time after adding {hours} hours and {minutes} minutes is: {new_time.strftime('%I:%M %p')}")

if __name__ == "__main__":
    add_time_to_current()
