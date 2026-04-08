#include <stdio.h> // printf, perror
#include <stdlib.h> // exit
#include <unistd.h> // fork, getpid

int main(int argc, char *argv[]) {
    // this program causes its running process to call fork, which creates a child process by copying the calling process.
    
    // What does fork return:
    // 0 (Zero): Returned to the child process. This indicates that the current execution is happening inside the new process.
    // Positive Value: Returned to the parent process. This value is the Process ID (PID) of the newly created child process. The parent uses this PID to track or manage the child.
    // -1 (Negative One): Returned only to the parent process if the fork fails. In this case, no child process is created, and the errno global variable is set to indicate the error (e.g., EAGAIN if process limits are reached).
    printf("hello world (pid:%d)\n", (int) getpid());
    int rc = fork();
    if (rc < 0) {
        perror("forkfailed");
        exit(1);
    } else if (rc == 0) {
        printf("Hello, i am the child process (pid:%d)\n", (int) getpid());
    } else {
        printf("Hello, I am the parent of %d (pid: %d)\n", rc, (int) getpid());
    }
    return 0;
}

// Program output:
// hello world (pid:16585)
// Hello, I am the parent of 16589 (pid: 16585)
// Hello, i am the child process (pid:16589)

//// OR
// hello world (pid:32768)
// Hello, i am the child process (pid:32769)
// Hello, I am the parent of 32769 (pid: 32768)

// Why both branches appear in one program:
// - Code before fork() runs once in the original process.
// - fork() creates a second process (child), and both parent + child continue
//   from the next line after fork().
// - The parent sees rc > 0 (child PID), so it runs the parent branch.
// - The child sees rc == 0, so it runs the child branch.
//
// About output order:
// Basically, it is not deterministic and is determined by the scheduler
// - Parent-vs-child print order is not guaranteed; the scheduler decides.
// - If you want strict order, use wait()/waitpid() in the parent.

