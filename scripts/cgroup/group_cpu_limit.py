import os
import multiprocessing

# Stack size (just a placeholder in Python as we don't use raw memory management like C)
STACK_SIZE = 1024 * 1024


# Function to simulate the container process
def container_main():
    print("start")
    i = 0
    while True:
        i += 1


# Function to handle parent process
def parent_process():
    print("Parent - start a container!")

    # Create cgroup directory for CPU limitation
    os.makedirs("/sys/fs/cgroup/cpu/deadloop", exist_ok=True)

    # Set CPU quota to 50%
    with open("/sys/fs/cgroup/cpu/deadloop/cpu.cfs_quota_us", "w") as f:
        f.write("50000")

    # Start the container process (using multiprocessing as an alternative to `clone`)
    container_process = multiprocessing.Process(target=container_main)
    container_process.start()

    # Add the container's PID to the cgroup
    container_pid = container_process.pid
    with open("/sys/fs/cgroup/cpu/deadloop/tasks", "a") as f:
        f.write(f"{container_pid}\n")

    # Wait for the container process to finish
    container_process.join()

    print("Parent - container stopped!")


# Main entry point
if __name__ == "__main__":
    parent_process()
