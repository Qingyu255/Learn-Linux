#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Calling fork() is only useful if you want to keep running copies of the same program. However, often you want to run a different program; exec() does just that

int main(int argc, char *argv[]) {
    printf("Hello, I am process with PID: %d\n", (int) getpid());
    int rc = fork(); // where rc is return code
    if (rc < 0) {
        perror("fork failed, failed to create child process");
        exit(1);
    } else if (rc == 0) { // child process
        printf("Hello, i am the child process (pid:%d)\n", (int) getpid());
        char *myargs[] = {"wc", "exec.c", NULL};
        execvp(myargs[0], myargs); // runs word count
        printf("this shouldn’t print out");
        // what this means:
        // If execvp() succeeds, the child process image is replaced by wc, so control never returns to your original code, and that printf is never reached.
        // If you ever see "this shouldn’t print out", it means execvp() failed (bad command/path/args, permission issue, etc.) and execution continued to the next line.
    } else { // parent process goes here
        // where wc is wait code
        int wc = wait(NULL); // NULL means: “I don’t care about the child’s exit status.” If you do care, use: int status; wait(&status);
        // now, the parent process calls wait() to delay its execution until the child finishes executing.
        printf("Hello, I am the parent of %d (pid: %d)\n", rc, (int) getpid());
    }
    return 0;
}

// exec does not create a new process; rather, it transforms the currently running program
// (formerly p3) into a different running program (wc). After the exec()
// in the child, it is almost as if p3.cnever ran; a successful call to exec()
// never returns.

// exec does not create a new process, so it does not create a new PID.
    // fork() creates a new process → new PID (child).
    // exec*() replaces the program image inside the same process.
    // So when child calls execvp("wc", ...), that child keeps its PID, but its code/data/stack are replaced by wc.
    // That’s why people say “it’s as if the old program never ran” from that point forward.
    // If exec succeeds, it never returns to old code; if it returns, it failed.