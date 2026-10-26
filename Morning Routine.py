#Uses calling functions to loop through the system because it allowes different functions to be called when something happens
def sleep_more():
    print("Sleep")
    awake()

def handle_time():
    is_before = input("Is it before 7:10? [y]/[n]\n")
    if is_before == "n":
        print("Complain about being late")
    elif is_before == "y":
        print("Many steps incoming. Press enter to move to next step")
        input("Go ask to leave")
        input("Go to school")
        input("Eat breakfast")
        input("Get work done")
        input("Go to advisory")
        print("Stop")
        quit()
    else:
        handle_time()

def handle_cold():
    is_cold = input("Am I cold? [y]/[n]\n")
    if is_cold == "y":
        sleep_more()
    elif is_cold == "n":
        print("Many steps incoming. Press enter to move to next step")
        input("Get out of bed")
        input("Get dressed")
        input("Brush teeth")
        input("Go down the stairs")
        input("Look at phone")
        handle_time()
    else:
        handle_cold()

def tired():
    is_tired = input("Am I tired? [y]/[n]\n")
    if is_tired == "y":
        sleep_more()
    elif is_tired == "n":
        handle_cold()
    else:
        tired()

def want_get_up():
    get_up = input("Do I want to get up? [y]/[n]\n")
    if get_up == "n":
        sleep_more()
    elif get_up == "y":
        print("Getup")
        tired()
    else:
        want_get_up()

def need_get_up():
    need_to = input("Do I need to get up? [y]/[n]\n")
    if need_to == "n":
        sleep_more()
    elif need_to == "y":
        want_get_up()
    else:
        need_get_up()

def school():
    is_school = input("Is there school? [y]/[n]\n")
    if is_school == "n":
        print("Many stepps incoming. Press enter to move to next step")
        input("Get up")
        input("Play video games")
        input("Stop")
        quit()
    if is_school == "y":
        need_get_up()
    else:
        school()

def awake():
    is_awake = input("Am I awake? [y]/[n]\n")
    if is_awake == "n":
        sleep_more()
    elif is_awake == "y":
        school()
    else:
        awake()

#Starts code
print("Start")
awake()